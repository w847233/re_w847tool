"""
steam_bot.py — Steam 客户端封装模块

职责：
- 使用 WebAPI IAuthenticationService 进行登录（支持手机验证及令牌批准）
- 保存 refresh_token 以实现免密登录
- 使用 ModernSteamClient 配合 access_token 登录 Steam CM 服务器
- 直接构造 CMsgClientGamesPlayed protobuf 消息设置自定义状态
- 提供清晰的状态管理接口
"""

import os
import json
import base64
import logging
import requests

import vdf
import gevent
from cryptography.fernet import Fernet

from steam.client import SteamClient
from steam.enums import EResult, EPersonaState
from steam.enums.emsg import EMsg
from steam.core.msg import MsgProto
from steam.steamid import SteamID
from steam.utils import ip4_to_int
from steam.core.crypto import rsa_publickey, pkcs1v15_encrypt

logger = logging.getLogger(__name__)

# 常见的 Steam 错误代码中文对照
ERESULT_DESCRIPTIONS = {
    5: "密码错误或 Token 无效，请重新登录",
    15: "访问被拒绝（账号可能受限或网络被屏蔽）",
    18: "找不到该账号，请检查用户名是否正确",
    43: "账号已被禁用",
    63: "需要提供 Steam Guard 验证码",
    65: "登录请求太频繁，受到速率限制，请稍后再试",
    84: "请求过于频繁，触发了 Steam 速率限制，请稍后再试",
    85: "需要提供 Steam Guard 验证码或手机令牌",
    88: "手机令牌验证码错误",
    89: "邮箱验证码错误",
}

def get_error_message(result) -> str:
    """获取错误码的中文描述"""
    if isinstance(result, int) or hasattr(result, "value"):
        code = getattr(result, "value", result)
        if code in ERESULT_DESCRIPTIONS:
            return f"错误 {code}：{ERESULT_DESCRIPTIONS[code]}"
        
        name = getattr(result, "name", str(result))
        return f"未知错误 {code}：{name}"
    return str(result)

NON_STEAM_GAME_ID = 0x8000000000000000

AUTH_DIR = os.path.join(os.path.dirname(__file__), "auth")
SESSIONS_FILE = os.path.join(AUTH_DIR, "sessions.json")
KEY_FILE = os.path.join(AUTH_DIR, "session.key")


# ────────────────────────────────────────────────────────────────────────────
# 加密工具（用于保存 refresh_token 和 shared_secret）
# ────────────────────────────────────────────────────────────────────────────

def _get_or_create_key() -> bytes:
    if not os.path.exists(AUTH_DIR):
        os.makedirs(AUTH_DIR, exist_ok=True)
    if os.path.exists(KEY_FILE):
        with open(KEY_FILE, "rb") as f:
            return f.read()
    key = Fernet.generate_key()
    with open(KEY_FILE, "wb") as f:
        f.write(key)
    return key

def _encrypt(data: str) -> str:
    f = Fernet(_get_or_create_key())
    return f.encrypt(data.encode()).decode()

def _decrypt(data: str) -> str:
    f = Fernet(_get_or_create_key())
    return f.decrypt(data.encode()).decode()


# ────────────────────────────────────────────────────────────────────────────
# 凭证持久化
# ────────────────────────────────────────────────────────────────────────────

def _read_sessions() -> dict:
    if not os.path.exists(SESSIONS_FILE): return {}
    try:
        with open(SESSIONS_FILE, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return {}

def _write_sessions(data: dict) -> None:
    os.makedirs(AUTH_DIR, exist_ok=True)
    with open(SESSIONS_FILE, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

def get_saved_accounts() -> list[str]:
    """获取所有已保存的账号列表"""
    data = _read_sessions()
    return [k for k, v in data.items() if isinstance(v, dict) and "refresh_token_enc" in v]

def get_saved_refresh_token(username: str) -> str | None:
    data = _read_sessions()
    entry = data.get(username)
    if not entry or "refresh_token_enc" not in entry: return None
    try:
        return _decrypt(entry["refresh_token_enc"])
    except Exception: return None

def save_refresh_token(username: str, refresh_token: str) -> None:
    data = _read_sessions()
    entry = data.get(username, {})
    entry["refresh_token_enc"] = _encrypt(refresh_token)
    data[username] = entry
    _write_sessions(data)
    logger.info("已保存 %s 的 refresh_token", username)

def delete_session(username: str) -> bool:
    data = _read_sessions()
    if username in data:
        del data[username]
        _write_sessions(data)
        return True
    return False


# ────────────────────────────────────────────────────────────────────────────
# Steam API (WebAPI & CM)
# ────────────────────────────────────────────────────────────────────────────


class ModernSteamClient(SteamClient):
    """继承 SteamClient 以提供通过 access_token 登录 CM 服务器的功能"""
    
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self._last_username = None
        self._last_refresh_token = None
        self._auto_relogin = True
        self.on('logged_off', self._handle_logged_off_override)

    def _handle_logged_off_override(self, result):
        if self._auto_relogin and self._last_refresh_token:
            self._LOG.info("检测到服务器登出，因为配置了自动重连，恢复 _logged_on_once 以便网络重连后触发 relogin")
            self._logged_on_once = True

    def login_with_access_token(self, username: str, refresh_token: str, login_id=None) -> EResult:
        self._last_username = username
        self._last_refresh_token = refresh_token
        self._auto_relogin = True
        self._LOG.debug("Attempting login with refresh_token (in access_token field)")
        eresult = self._pre_login()
        if eresult != EResult.OK:
            return eresult

        self.username = username

        def get_steamid_from_token(token: str) -> int:
            parts = token.split('.')
            if len(parts) >= 2:
                try:
                    decoded = json.loads(base64.urlsafe_b64decode(parts[1] + '==').decode())
                    return int(decoded.get('sub', 0))
                except Exception: pass
            return 0

        message = MsgProto(EMsg.ClientLogon)
        steamid64 = get_steamid_from_token(refresh_token)
        if steamid64:
            message.header.steamid = steamid64
        else:
            message.header.steamid = SteamID(type='Individual', universe='Public')
        message.body.protocol_version = 65580
        message.body.client_package_version = 1561159470
        message.body.client_os_type = 16 # Windows 10
        message.body.client_language = "english"
        message.body.should_remember_password = True
        message.body.supports_rate_limit_response = True
        message.body.chat_mode = self.chat_mode

        if login_id is None:
            message.body.obfuscated_private_ip.v4 = ip4_to_int(self.connection.local_address) ^ 0xF00DBAAD
        else:
            message.body.obfuscated_private_ip.v4 = login_id

        # 关键修正：使用 WebAPI Token 登录 CM 时，
        # CMsgClientLogon 的 access_token 字段必须填入 refresh_token，
        # 并且必须保持 account_name 和 password 字段为空。
        message.body.access_token = refresh_token
        
        sentry = self.get_sentry(username)
        if sentry is None:
            message.body.eresult_sentryfile = EResult.FileNotFound
        else:
            message.body.eresult_sentryfile = EResult.OK
            import hashlib
            message.body.sha_sentryfile = hashlib.sha1(sentry).digest()

        self.send(message)
        resp = self.wait_msg(EMsg.ClientLogOnResponse, timeout=30)
        if resp and resp.body.eresult == EResult.OK:
            self.sleep(0.5)
        return EResult(resp.body.eresult) if resp else EResult.Fail

    def relogin(self):
        if self._auto_relogin and self._last_username and self._last_refresh_token:
            self._LOG.info("自动使用 refresh_token 重新登录 CM...")
            return self.login_with_access_token(self._last_username, self._last_refresh_token)
        return super().relogin()

    def logout(self):
        self._auto_relogin = False
        super().logout()

# 辅助函数：构造副状态 protobuf 消息
def _build_games_played_msg(
    status_text: str,
    app_id: int | None,
    use_real_game_name: bool = False,
) -> MsgProto:
    """构建 ClientGamesPlayed 消息。

    use_real_game_name=True 时，不设置 game_extra_info，
    让 Steam 显示真实游戏名称和图标（Rich Presence 正常工作的前提）。
    use_real_game_name=False 时，设置 game_extra_info 展示自定义文字。
    """
    msg = MsgProto(EMsg.ClientGamesPlayed)
    game = msg.body.games_played.add()
    game.game_id = app_id if app_id is not None else NON_STEAM_GAME_ID
    if not use_real_game_name:
        game.game_extra_info = status_text
    return msg

def _build_rich_presence_msg(
    rich_text: str,
    friend_steamids: list[int],
    status_text: str = "",
) -> MsgProto:
    """构建 Rich Presence 上传消息。

    rich_text 是 token key（'#' 开头）。
    status_text 是可选的自定义文字，作为 raw 字符串嵌入（不需要 localization）。
    friend_steamids 是好友 SteamID 列表（必须填写）。

    VDF binary 格式说明：
    根节点必须是空字符串 ''（参考 SteamKit2 SetRichPresence 实现），
    不能是 'RP'。Steam CM 只接受根节点为空字符串的格式。
    """
    msg = MsgProto(EMsg.ClientRichPresenceUpload)
    kv: dict = {"steam_display": rich_text}
    if status_text:
        # status 字段作为 raw text fallback（当 token 无法解析时也能显示）
        kv["status"] = status_text
    # 根节点必须是空字符串（Steam CM 要求）
    rp_data = {"": kv}
    msg.body.rich_presence_kv = vdf.binary_dumps(rp_data)
    for sid in friend_steamids:
        msg.body.steamid_broadcast.append(sid)
    return msg

def _build_clear_rich_presence_msg(friend_steamids: list[int]) -> MsgProto:
    """清除 Rich Presence，通知所有好友。"""
    msg = MsgProto(EMsg.ClientRichPresenceUpload)
    # 清除 RP：空根节点 + 空 KV
    msg.body.rich_presence_kv = vdf.binary_dumps({"": {}})
    for sid in friend_steamids:
        msg.body.steamid_broadcast.append(sid)
    return msg



# ────────────────────────────────────────────────────────────────────────────
# SteamBot 主类
# ────────────────────────────────────────────────────────────────────────────

class SteamBot:
    def __init__(self, on_status_change=None):
        self.client = ModernSteamClient()
        self._on_status_change = on_status_change or (lambda e, d: None)
        self.client.set_credential_location(AUTH_DIR)

        self._logged_in = False
        self._username: str | None = None
        self._refresh_token: str | None = None
        
        # 轮询状态所需
        self._client_id: str | None = None
        self._request_id: str | None = None
        self._auth_steamid: int = 0
        self._poll_interval = 2.0
        self._is_polling = False

        self._current_status: str | None = None
        self._current_app_id: int | None = None
        self._current_rich_text: str | None = None
        self._current_persona_state: EPersonaState = EPersonaState.Online

        # RP 保活 greenlet（每 30 秒重发，确保好友随时能看到 RP）
        self._rp_keepalive_greenlet = None
        self._rp_keepalive_interval = 30.0

        self.client.on("error", self._handle_error)
        self.client.on("disconnected", self._handle_disconnected)
        self.client.on("logged_on", self._handle_logged_on)

        self._is_connecting = False
        # IP 变更检测：统计连续 TryAnotherCM 次数，超过阈值则判定 token 已与当前 IP 不匹配
        self._try_another_cm_count = 0
        _TRY_ANOTHER_CM_THRESHOLD = 4
        self._TRY_ANOTHER_CM_THRESHOLD = _TRY_ANOTHER_CM_THRESHOLD

    @property
    def is_logged_in(self) -> bool: return self._logged_in

    @property
    def username(self) -> str | None: return self._username

    @property
    def current_status(self) -> str | None: return self._current_status

    @property
    def current_app_id(self) -> int | None: return self._current_app_id

    @property
    def current_rich_text(self) -> str | None: return self._current_rich_text

    @property
    def current_persona_state(self) -> EPersonaState: return self._current_persona_state

    def _handle_error(self, result):
        result_val = getattr(result, "value", result)
        # TryAnotherCM (48)：可能是 CM 节点暂时不可用，也可能是 IP 变更导致 token 失效
        if result_val == EResult.TryAnotherCM or result_val == 48:
            self._try_another_cm_count += 1
            logger.debug(
                "Steam CM 节点不可用（TryAnotherCM），累计 %d 次",
                self._try_another_cm_count,
            )
            if self._try_another_cm_count >= self._TRY_ANOTHER_CM_THRESHOLD:
                self._try_another_cm_count = 0
                logger.warning(
                    "连续 %d 次 TryAnotherCM，疑似 IP 变更导致 Steam 拒绝连接。",
                    self._TRY_ANOTHER_CM_THRESHOLD,
                )
                self._on_status_change("error", {
                    "message": "Steam 持续拒绝连接，可能是因为当前 IP 与获取凭证时的 IP 不同。请切换回原来的网络环境后重试。",
                })
            return
        self._try_another_cm_count = 0
        err_msg = get_error_message(result)
        logger.error("Steam 报错：%s", err_msg)
        self._on_status_change("error", {"message": err_msg})

    def _handle_disconnected(self):
        self._logged_in = False
        self._stop_rp_keepalive()  # 断线时停止保活
        logger.warning("与 Steam 断开连接")
        self._on_status_change("disconnected", {})

    def _handle_logged_on(self):
        # 如果是在初次手动连接中抛出的 logged_on，由 _connect_cm 自行处理
        if getattr(self, '_is_connecting', False):
            return

        if not self._logged_in:
            logger.info("🎉 自动重连/登录成功，正在恢复之前的状态...")
            self._logged_in = True
            self._try_another_cm_count = 0  # 登录成功，重置计数器
            
            def _restore_state():
                gevent.sleep(2)
                # 恢复副状态
                if self._current_persona_state:
                    self.client.change_status(persona_state=self._current_persona_state, persona_set_by_user=True)
                
                # 恢复正在玩的游戏和自定义状态文字
                if self._current_app_id is not None or self._current_status is not None:
                    self.set_status(
                        self._current_status or "",
                        self._current_app_id,
                        noisy=False,
                        rich_text=self._current_rich_text
                    )
                
                # 通知前端刷新显示
                self._on_status_change("logged_on", {
                    "username": self._username,
                    "need_save_prompt": False,
                })
            
            gevent.spawn(_restore_state)

    def _stop_rp_keepalive(self) -> None:
        """停止 RP 保活 greenlet。"""
        g = self._rp_keepalive_greenlet
        if g is not None and not g.dead:
            g.kill(block=False)
        self._rp_keepalive_greenlet = None

    def _start_rp_keepalive(self) -> None:
        """启动 RP 保活 greenlet：每 30 秒重新发送一次 ClientRichPresenceUpload。

        原因：Steam CM 不持久广播 Rich Presence。
        好友后来上线时，需要重新广播才能看到 RP 子状态。
        """
        self._stop_rp_keepalive()

        def _keepalive_loop():
            while self._logged_in and self._current_rich_text:
                gevent.sleep(self._rp_keepalive_interval)
                if not self._logged_in or not self._current_rich_text:
                    break
                friend_ids = self._get_friend_steamids()
                if not friend_ids:
                    logger.debug("RP 保活：好友列表为空，跳过本次重发")
                    continue
                use_rp_status = bool(self._current_rich_text and self._current_app_id)
                rp_status = self._current_status if use_rp_status else ""
                try:
                    self.client.send(_build_rich_presence_msg(
                        self._current_rich_text, friend_ids, status_text=rp_status))
                    logger.debug("RP 保活：已重新广播 Rich Presence（%s）", self._current_rich_text)
                except Exception as e:
                    logger.warning("RP 保活重发异常：%s", e)

        self._rp_keepalive_greenlet = gevent.spawn(_keepalive_loop)
        logger.info("RP 保活已启动（间隔 %ss）", self._rp_keepalive_interval)


    def _connect_cm(self, refresh_token: str, _cm_retry: int = 0):
        """拿到 refresh_token 后连接 CM 服务器。

        当 login_with_access_token 返回 TryAnotherCM 时（_pre_login 超时），
        会断线后重试最多 3 次。若仍失败，判定为 IP 变更导致 token 失效，
        清除凭证并通知用户重新登录。
        """
        _MAX_CM_RETRIES = 3
        logger.info("使用 refresh_token 登录 Steam CM 服务器...")
        self._is_connecting = True
        try:
            result = self.client.login_with_access_token(self._username, refresh_token)
            if result == EResult.OK:
                self._logged_in = True
                self._try_another_cm_count = 0  # 登录成功，重置计数器
                logger.info("✅ 登录成功，账号：%s", self._username)
                self.client.change_status(persona_state=EPersonaState.Online)
                
                # 判断是否需要提示保存凭证
                need_save_prompt = False
                if self._refresh_token:
                    existing_rt = get_saved_refresh_token(self._username)
                    if existing_rt != self._refresh_token:
                        need_save_prompt = True

                self._on_status_change("logged_on", {
                    "username": self._username,
                    "need_save_prompt": need_save_prompt,
                })
            elif result == EResult.TryAnotherCM:
                if _cm_retry < _MAX_CM_RETRIES:
                    logger.warning(
                        "CM 节点拒绝登录（TryAnotherCM），第 %d/%d 次重试...",
                        _cm_retry + 1, _MAX_CM_RETRIES,
                    )
                    self._is_connecting = False
                    # 断开当前连接，让 _pre_login 重新选择 CM 节点
                    try:
                        self.client.disconnect()
                    except Exception:
                        pass
                    gevent.sleep(2 + _cm_retry)  # 递增退避
                    self._connect_cm(refresh_token, _cm_retry + 1)
                else:
                    logger.warning(
                        "连续 %d 次 TryAnotherCM，疑似 IP 变更，Steam 持续拒绝连接。",
                        _MAX_CM_RETRIES + 1,
                    )
                    self._on_status_change("error", {
                        "message": "Steam 持续拒绝连接，可能是因为当前 IP 与获取凭证时的 IP 不同。请切换回原来的网络环境后重试。",
                    })
            else:
                self._handle_error(result)
        finally:
            self._is_connecting = False

    def _encrypt_password_webapi(self, username, password):
        """WebAPI: 请求 RSA 公钥并加密密码"""
        url = "https://api.steampowered.com/IAuthenticationService/GetPasswordRSAPublicKey/v1/"
        resp = requests.get(url, params={"account_name": username}).json()
        if "response" not in resp or "publickey_mod" not in resp["response"]:
            raise Exception("无法获取 RSA 公钥")
        
        mod = resp["response"]["publickey_mod"]
        exp = resp["response"]["publickey_exp"]
        timestamp = resp["response"]["timestamp"]
        
        n = int(mod, 16)
        e = int(exp, 16)
        pubkey = rsa_publickey(n, e)
        encrypted = pkcs1v15_encrypt(pubkey, password.encode('utf-8'))
        
        return base64.b64encode(encrypted).decode('utf-8'), timestamp

    def _poll_login_status(self):
        """后台轮询 WebAPI 等待手机确认或 2FA 输入"""
        url = "https://api.steampowered.com/IAuthenticationService/PollAuthSessionStatus/v1/"
        self._is_polling = True
        
        while self._is_polling:
            gevent.sleep(self._poll_interval)
            try:
                data = {"client_id": self._client_id, "request_id": self._request_id}
                resp = requests.post(url, data=data).json()
                response = resp.get("response", {})
                
                if "refresh_token" in response:
                    logger.info("WebAPI 登录授权成功，拿到 refresh_token")
                    self._refresh_token = response["refresh_token"]
                    self._is_polling = False
                    self._connect_cm(self._refresh_token)
                    return
                
                # 如果被拒绝，或过期等
                if "new_client_id" in response:
                    self._client_id = response["new_client_id"]
                    
            except Exception as e:
                logger.warning("轮询登录状态异常: %s", e)
        
    def login_with_credentials(self, username: str, password: str) -> None:
        def _task():
            self._username = username
            self._refresh_token = None
            try:
                logger.info("请求 RSA 密钥并加密密码...")
                enc_pw, timestamp = self._encrypt_password_webapi(username, password)
                
                url = "https://api.steampowered.com/IAuthenticationService/BeginAuthSessionViaCredentials/v1/"
                data = {
                    "account_name": username,
                    "encrypted_password": enc_pw,
                    "encryption_timestamp": timestamp,
                    "remember_login": True,
                    "platform_type": 1,
                    "persistence": 1,
                    "device_friendly_name": "Steam Custom Status Bot"
                }
                resp = requests.post(url, data=data).json().get("response", {})
                
                # 处理失败情况（如密码错误）
                if "client_id" not in resp:
                    logger.warning("BeginAuthSession 失败: %s", resp)
                    self._on_status_change("error", {"message": "登录失败，请检查账号和密码。"})
                    return
                    
                self._client_id = resp["client_id"]
                self._request_id = resp["request_id"]
                self._auth_steamid = resp.get("steamid", 0)
                
                # 分析支持的确认方式
                allowed_confirmations = resp.get("allowed_confirmations", [])
                conf_types = [c.get("confirmation_type") for c in allowed_confirmations]
                
                # 检查验证方式
                if 2 in conf_types or 3 in conf_types:
                    logger.info("需要提供 Steam Guard 验证码")
                    self._on_status_change("auth_code_required", {
                        "is_two_factor": 3 in conf_types,
                        "mismatch": False,
                        "prompt": "请输入 Steam Guard 验证码："
                    })
                elif 4 in conf_types:
                    logger.info("需要手机 App 批准")
                    self._on_status_change("waiting_for_mobile_approval", {})
                
                # 启动轮询
                gevent.spawn(self._poll_login_status)

            except Exception as e:
                logger.error("WebAPI 登录异常: %s", e)
                self._on_status_change("error", {"message": f"WebAPI 异常: {e}"})

        gevent.spawn(_task)

    def provide_guard_code(self, code: str) -> None:
        """通过 WebAPI 提交 Steam Guard 验证码 (Email / Authenticator Code)"""
        code = code.strip()
        def _task():
            url = "https://api.steampowered.com/IAuthenticationService/UpdateAuthSessionWithSteamGuardCode/v1/"
            data = {
                "client_id": self._client_id,
                "steamid": self._auth_steamid,
                "code": code,
                "code_type": 3
            }
            try:
                requests.post(url, data=data)
                logger.info("已提交验证码，等待验证...")
            except Exception as e:
                logger.warning("提交验证码失败: %s", e)
        gevent.spawn(_task)

    def login_with_refresh_token(self, username: str) -> None:
        """使用保存的 refresh_token 换取 access_token 并登录"""
        def _task():
            self._username = username
            rt = get_saved_refresh_token(username)
            if not rt:
                self._on_status_change("error", {"message": "找不到保存的凭证，请重新登录。"})
                return
            self._refresh_token = rt
            logger.info("使用保存的 refresh_token 直接连接 CM 服务器...")
            self._connect_cm(rt)
        gevent.spawn(_task)

    def save_current_credentials(self) -> bool:
        if self._username and self._refresh_token:
            save_refresh_token(self._username, self._refresh_token)
            return True
        return False

    def logout(self) -> None:
        self._is_polling = False
        self.client.logout()
        self._logged_in = False

    def _get_friend_steamids(self) -> list[int]:
        """获取当前好友列表的 SteamID（用于 steamid_broadcast 字段）。"""
        try:
            ids = [int(user.steam_id) for user in self.client.friends]
            logger.debug("好友列表：%d 人", len(ids))
            return ids
        except Exception as e:
            logger.warning("获取好友列表失败：%s", e)
            return []

    def set_status(
        self,
        status_text: str,
        app_id: int | None = None,
        noisy: bool = False,
        rich_text: str | None = None,
    ) -> bool:
        if not self._logged_in:
            logger.warning("未登录，无法设置状态")
            return False

        if rich_text and not rich_text.startswith("#"):
            # 非法 token key 直接拒绝，避免 Steam CM 静默丢弃 RP 消息
            logger.error(
                "rich_text '%s' 不是有效的 token key（必须以 '#' 开头），拒绝发送。",
                rich_text,
            )
            return False

        # 当使用真实 app_id + rich_text 时，不设置 game_extra_info
        # 否则会覆盖 game_played_app_id 传播，导致好友端无法解析 RP token
        use_real_game_name = bool(rich_text and app_id)
        msg = _build_games_played_msg(status_text, app_id, use_real_game_name=use_real_game_name)

        if use_real_game_name:
            logger.info(
                "Rich Presence 模式：game_extra_info 留空，appid=%s，自定义文字放入 RP status",
                app_id,
            )

        self._current_status = status_text
        self._current_app_id = app_id
        self._current_rich_text = rich_text or None

        self._on_status_change("status_updated", {
            "status": status_text,
            "app_id": app_id,
            "rich_text": self._current_rich_text,
        })

        friend_ids = self._get_friend_steamids()
        rp_status = status_text if use_real_game_name else ""

        if noisy:
            def noisy_task():
                self.set_persona_state(EPersonaState.Invisible)
                self.client.send(MsgProto(EMsg.ClientGamesPlayed))
                self.client.send(_build_clear_rich_presence_msg(friend_ids))
                gevent.sleep(5.5)
                self.client.send(msg)
                if self._current_rich_text:
                    if not friend_ids:
                        logger.warning("好友列表为空，Rich Presence 无法推送（noisy 模式）")
                    else:
                        self.client.send(_build_rich_presence_msg(
                            self._current_rich_text, friend_ids, status_text=rp_status))
                        self._start_rp_keepalive()
                self.set_persona_state(EPersonaState.Online)
            gevent.spawn(noisy_task)
        else:
            self.client.send(msg)
            # 触发好友端 PersonaState 刷新（ClientGamesPlayed 后需要 ChangeStatus 才推送）
            self.client.change_status(
                persona_state=EPersonaState.Online,
                persona_set_by_user=True,
            )
            if rich_text:
                if not friend_ids:
                    logger.warning("好友列表为空，Rich Presence 无法推送。请稍后重试，或等待好友列表加载完成。")
                else:
                    # 短暂等待，确保 CM 先处理 ClientGamesPlayed，再关联 RP
                    gevent.sleep(0.3)
                    self.client.send(_build_rich_presence_msg(
                        rich_text, friend_ids, status_text=rp_status))
                    # 发完 RP 后再次广播 PersonaState，触发好友端刷新 Rich Presence 显示
                    gevent.sleep(0.1)
                    self.client.change_status(
                        persona_state=self._current_persona_state,
                        persona_set_by_user=True,
                    )
                    # 启动 RP 保活（每 30 秒重发，确保后来上线的好友也能看到 RP）
                    self._start_rp_keepalive()
            else:
                # 无 RP 时停止保活
                self._stop_rp_keepalive()

        return True

    def clear_status(self) -> bool:
        if not self._logged_in: return False
        friend_ids = self._get_friend_steamids()
        self.client.send(MsgProto(EMsg.ClientGamesPlayed))
        self.client.send(_build_clear_rich_presence_msg(friend_ids))
        self._stop_rp_keepalive()  # 清除状态时停止 RP 保活
        self._current_status = None
        self._current_app_id = None
        self._current_rich_text = None
        self._on_status_change("status_cleared", {})
        return True


    def set_persona_state(self, state: EPersonaState) -> bool:
        if not self._logged_in: return False
        self.client.change_status(persona_state=state, persona_set_by_user=True)
        self._current_persona_state = state
        self._on_status_change("persona_state_updated", {
            "persona_state": state.value,
            "persona_state_name": state.name,
        })
        return True

    def run(self) -> None:
        self.client.connect()
        self.client.run_forever()
