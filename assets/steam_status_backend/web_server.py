"""
web_server.py — Flask Web 控制面板

REST API 端点：
  GET  /                    控制面板页面
  GET  /api/state           获取当前连接状态和游戏状态
  GET  /api/rich_presence_tokens  获取指定 AppID 的 Rich Presence 可用 token 列表
  POST /api/status          设置自定义状态
  DELETE /api/status        清除状态
  GET  /api/cm_preference   获取 Steam CM 服务器优选状态
  POST /api/cm_preference   开关登录前自动 CM 优选
  POST /api/cm_test         立即测速并应用 Steam CM 优选
  GET  /api/domain_preference 获取 Steam 全流程域名优选状态
  POST /api/domain_preference 选择域名解析出的 IP
  POST /api/domain_resolve   解析全流程域名 IP 与中文属地
  POST /api/login           使用账号密码登录
  POST /api/login_session   使用保存的凭证免密登录
  POST /api/save_credentials 保存当前登录凭证
  GET  /api/saved_accounts  获取所有已保存的账号列表
  DELETE /api/saved_account 删除已保存的账号
  POST /api/guard_code      提交 Steam Guard 验证码
  POST /api/logout          登出（保留凭证）
"""

import logging
import re
from flask import Flask, jsonify, render_template, request

logger = logging.getLogger(__name__)

RICH_PRESENCE_PLACEHOLDER_RE = re.compile(r"%([A-Za-z0-9_:]+)%")


def _extract_rich_presence_placeholders(display_text: str) -> list[str]:
    """从 localization 展示串里提取 %key% 占位符，保持出现顺序。"""
    placeholders: list[str] = []
    seen = set()
    for match in RICH_PRESENCE_PLACEHOLDER_RE.finditer(display_text or ""):
        key = match.group(1)
        if key not in seen:
            placeholders.append(key)
            seen.add(key)
    return placeholders


def _fetch_rich_presence_tokens(steam_client, app_id: int, language: str = "english") -> list[dict]:
    """
    通过 Steam Unified Messages 协议获取指定 AppID 的 Rich Presence localization tokens。

    使用 Community.GetAppRichPresenceLocalization#1 接口，而非 PICS/appinfo，
    因为 Rich Presence localization 数据不存储在 appinfo 中。

    返回格式：
    [{"token": "#Status_Playing", "display": "Playing on %map%", "placeholders": ["map"]}, ...]
    其中 display 为对应语言的展示字符串（含变量占位符的原始格式）。

    Args:
        steam_client: 已登录的 SteamClient 实例
        app_id:       目标游戏 AppID
        language:     语言代码（如 english、schinese）

    Raises:
        RuntimeError: 请求失败或 AppID 不存在时
    """
    resp = steam_client.send_um_and_wait(
        "Community.GetAppRichPresenceLocalization#1",
        {"appid": app_id, "language": language},
        timeout=10,
    )

    if resp is None:
        raise RuntimeError(f"AppID {app_id} 的 Rich Presence localization 请求超时")

    # EResult 非 1 表示失败（1 = k_EResultOK）
    eresult = getattr(resp, "eresult", 1)
    if eresult != 1:
        raise RuntimeError(f"AppID {app_id} 请求失败，EResult={eresult}")

    body = resp.body
    token_lists = list(body.token_lists)

    if not token_lists:
        raise RuntimeError(f"AppID {app_id} 没有配置 Rich Presence localization 数据")

    # 按优先级选语言：用户指定 → english → 第一个可用语言
    def _find_lang(lang_code: str):
        for tl in token_lists:
            if tl.language == lang_code:
                return tl
        return None

    lang_data = (
        _find_lang(language)
        or _find_lang("english")
        or token_lists[0]
    )

    tokens = [
        {
            "token": t.name,
            "display": t.value,
            "placeholders": _extract_rich_presence_placeholders(t.value),
        }
        for t in lang_data.tokens
        if t.name and isinstance(t.value, str)
    ]

    # 按 token key 排序，方便用户查找
    tokens.sort(key=lambda t: t["token"])
    return tokens


def _resolve_rich_presence_values(
    steam_client,
    app_id: int | None,
    rich_text: str | None,
    placeholder_text: str,
    language: str = "english",
) -> dict[str, str]:
    """根据 token localization 自动补齐 Rich Presence 占位符 KV。"""
    if not app_id or not rich_text or not placeholder_text:
        return {}

    tokens = _fetch_rich_presence_tokens(steam_client, app_id, language)
    token = next((item for item in tokens if item["token"] == rich_text), None)
    if token is None:
        logger.warning("未找到 Rich Presence token：appid=%s token=%s", app_id, rich_text)
        return {}

    placeholders = token.get("placeholders") or []
    values = {key: placeholder_text for key in placeholders if key != "steam_display"}
    if values:
        logger.info(
            "Rich Presence token %s 需要占位符 %s，已使用富文本内容自动填充",
            rich_text,
            ", ".join(values.keys()),
        )
    return values


def create_app(bot) -> Flask:
    # 创建 Flask 应用
    app = Flask(__name__)

    # ── 页面路由 ─────────────────────────────────────────────────────────────

    @app.route("/")
    def index():
        return render_template("index.html")

    # ── API 路由 ─────────────────────────────────────────────────────────────

    @app.route("/api/saved_accounts", methods=["GET"])
    def saved_accounts():
        """获取所有已保存的账号"""
        from steam_bot import get_saved_accounts
        names = get_saved_accounts()
        accounts = [
            {"username": name}
            for name in names
        ]
        return jsonify({"accounts": accounts})

    @app.route("/api/login", methods=["POST"])
    def login():
        """使用账号密码登录"""
        data = request.get_json(silent=True) or {}
        username = (data.get("username") or "").strip()
        password = data.get("password") or ""
        if not username or not password:
            return jsonify({"success": False, "error": "用户名和密码不能为空"}), 400
        
        bot.login_with_credentials(username, password)
        return jsonify({"success": True, "message": "正在登录..."})

    @app.route("/api/login_session", methods=["POST"])
    def login_session():
        """使用保存的凭证免密登录"""
        data = request.get_json(silent=True) or {}
        username = (data.get("username") or "").strip()
        if not username:
            return jsonify({"success": False, "error": "缺少账号参数"}), 400
            
        from steam_bot import get_saved_refresh_token
        rt = get_saved_refresh_token(username)
        if not rt:
            return jsonify({"success": False, "error": "未找到该账号的有效凭证"}), 400
        
        bot.login_with_refresh_token(username)
        return jsonify({"success": True, "message": f"正在使用 {username} 免密登录..."})

    @app.route("/api/save_credentials", methods=["POST"])
    def save_credentials_api():
        """保存当前登录的凭证"""
        ok = bot.save_current_credentials()
        if ok:
            return jsonify({"success": True})
        return jsonify({"success": False, "error": "当前无可保存的凭证"}), 400

    @app.route("/api/saved_account", methods=["DELETE"])
    def delete_saved_account():
        """删除已保存的账号"""
        data = request.get_json(silent=True) or {}
        username = (data.get("username") or "").strip()
        if not username:
            return jsonify({"success": False, "error": "缺少账号参数"}), 400
            
        from steam_bot import delete_session
        ok = delete_session(username)
        if ok:
            return jsonify({"success": True})
        return jsonify({"success": False, "error": "删除失败，账号可能不存在"}), 404

    @app.route("/api/state", methods=["GET"])
    def get_state():
        """返回当前连接状态 + 游戏状态"""
        return jsonify({
            "logged_in": bot.is_logged_in,
            "username": bot.username,
            "current_status": bot.current_status,
            "current_app_id": bot.current_app_id,
            "current_rich_text": bot.current_rich_text,
            "current_rich_presence_status": bot.current_rich_presence_status,
            "current_persona_state": bot.current_persona_state.value,
            "current_persona_state_name": bot.current_persona_state.name,
            "current_persona_state_flags": bot.current_persona_state_flags,
            "cm_preference": bot.get_cm_preference_status(),
            "domain_preference": bot.get_domain_preference_status(),
        })

    @app.route("/api/cm_preference", methods=["GET"])
    def get_cm_preference():
        """获取 Steam CM 服务器优选状态。"""
        return jsonify({"success": True, "cm_preference": bot.get_cm_preference_status()})

    @app.route("/api/cm_preference", methods=["POST"])
    def set_cm_preference():
        """开启或关闭登录前自动应用 CM 优选。"""
        data = request.get_json(silent=True) or {}
        enabled = bool(data.get("enabled", True))
        status = bot.set_cm_auto_preference(enabled)
        return jsonify({"success": True, "cm_preference": status})

    @app.route("/api/cm_test", methods=["POST"])
    def test_cm_servers():
        """立即拉取、测速并应用 Steam CM 优选节点。"""
        data = request.get_json(silent=True) or {}
        max_count = data.get("max_count")
        timeout_seconds = data.get("timeout_seconds")
        try:
            max_count = int(max_count) if max_count is not None else None
            timeout_seconds = (
                float(timeout_seconds) if timeout_seconds is not None else None
            )
        except (TypeError, ValueError):
            return jsonify({"success": False, "error": "测速参数无效"}), 400

        status = bot.test_cm_servers(
            max_count=max_count,
            timeout_seconds=timeout_seconds,
            apply=True,
        )
        if status.get("last_error"):
            return jsonify({"success": False, "error": status["last_error"], "cm_preference": status}), 500
        return jsonify({"success": True, "cm_preference": status})

    @app.route("/api/domain_preference", methods=["GET"])
    def get_domain_preference():
        """获取 Steam 全流程域名优选状态。"""
        return jsonify({
            "success": True,
            "domain_preference": bot.get_domain_preference_status(),
        })

    @app.route("/api/domain_resolve", methods=["POST"])
    def resolve_domains():
        """解析 Steam 全流程域名，返回 IP、延迟和中文属地。"""
        data = request.get_json(silent=True) or {}
        domains = data.get("domains")
        if domains is not None and not isinstance(domains, list):
            return jsonify({"success": False, "error": "domains 必须是数组"}), 400
        status = bot.resolve_steam_domains(domains=domains)
        return jsonify({"success": True, "domain_preference": status})

    @app.route("/api/domain_preference", methods=["POST"])
    def set_domain_preference():
        """更新某个域名是否启用 DNS 优选及选择的 IP。"""
        data = request.get_json(silent=True) or {}
        domain = (data.get("domain") or "").strip()
        if not domain:
            return jsonify({"success": False, "error": "缺少 domain 参数"}), 400
        selected_ips = data.get("selected_ips")
        if selected_ips is not None and not isinstance(selected_ips, list):
            return jsonify({"success": False, "error": "selected_ips 必须是数组"}), 400
        try:
            status = bot.update_domain_preference(
                domain,
                enabled=data.get("enabled"),
                selected_ips=selected_ips,
            )
        except ValueError as e:
            return jsonify({"success": False, "error": str(e)}), 400
        return jsonify({"success": True, "domain_preference": status})

    @app.route("/api/rich_presence_tokens", methods=["GET"])
    def get_rich_presence_tokens():
        """
        获取指定 AppID 的 Rich Presence localization tokens。
        通过 Steam Unified Messages 获取 Community 配置里的 Rich Presence localization。

        Query params:
            app_id: 游戏的 AppID（整数）
            language: 语言（默认 english）
        """
        if not bot.is_logged_in:
            return jsonify({"success": False, "error": "请先登录 Steam", "tokens": []}), 403

        app_id_raw = request.args.get("app_id", "")
        if not app_id_raw:
            return jsonify({"success": False, "error": "缺少 app_id 参数", "tokens": []}), 400
        try:
            app_id = int(app_id_raw)
        except ValueError:
            return jsonify({"success": False, "error": "app_id 必须是整数", "tokens": []}), 400

        language = request.args.get("language", "english")

        try:
            tokens = _fetch_rich_presence_tokens(bot.client, app_id, language)
            return jsonify({"success": True, "app_id": app_id, "tokens": tokens})
        except Exception as e:
            logger.warning("fetch RP tokens 失败 (appid=%s): %s", app_id, e)
            return jsonify({"success": False, "error": str(e), "tokens": []}), 500

    @app.route("/api/debug/appinfo", methods=["GET"])
    def debug_appinfo():
        """
        [调试] dump 指定 AppID 的完整 appinfo 结构（仅用于开发诊断）。
        Query params: app_id
        """
        if not bot.is_logged_in:
            return jsonify({"error": "未登录"}), 403
        app_id_raw = request.args.get("app_id", "730")
        app_id = int(app_id_raw)

        result = bot.client.get_product_info(apps=[app_id], auto_access_tokens=True, timeout=15)
        if not result or app_id not in result.get("apps", {}):
            return jsonify({"error": f"AppID {app_id} 不存在"}), 404

        app_data = result["apps"][app_id]

        def _safe_dump(obj, depth=0):
            """递归转换为 JSON 可序列化结构，截断过深或过长的内容"""
            if depth > 6:
                return "<<max_depth>>"
            if isinstance(obj, dict):
                return {k: _safe_dump(v, depth+1) for k, v in obj.items()}
            if isinstance(obj, (list, tuple)):
                return [_safe_dump(i, depth+1) for i in obj[:20]]
            if isinstance(obj, (bytes, bytearray)):
                return f"<bytes len={len(obj)}>"
            return obj

        return jsonify(_safe_dump(app_data))

    @app.route("/api/debug/friends", methods=["GET"])
    def debug_friends():
        """[调试] 查看当前好友列表数量和 steamid_broadcast 是否正常。"""
        if not bot.is_logged_in:
            return jsonify({"error": "未登录"}), 403
        try:
            friends = list(bot.client.friends)
            friend_ids = [int(u.steam_id) for u in friends]
            return jsonify({
                "friends_count": len(friends),
                "friends_ready": bot.client.friends.ready,
                "first_3_steamids": friend_ids[:3],
            })
        except Exception as e:
            return jsonify({"error": str(e)}), 500

    @app.route("/api/debug/my_rich_presence", methods=["GET"])
    def debug_my_rp():
        """
        [调试] 读取 Steam CM 上当前账号的 Rich Presence 数据。
        通过 ClientRequestFriendData 触发 CM 推送自身的 PersonaState，
        从 PersonaState.friends[].rich_presence[]{key,value} 中读出实际的 RP KV 对。
        """
        if not bot.is_logged_in:
            return jsonify({"error": "未登录"}), 403

        import gevent
        from steam.core.msg import MsgProto
        from steam.enums.emsg import EMsg

        my_steamid = int(bot.client.steam_id)

        # 通过 ClientRequestFriendData 请求自己，触发 PersonaState 推送
        req = MsgProto(EMsg.ClientRequestFriendData)
        req.body.friends.append(my_steamid)
        req.body.persona_state_requested = 0xFFFF  # 请求所有字段
        bot.client.send(req)

        # 等待 PersonaState，找到包含自己 SteamID 的 entry
        my_rp = None
        deadline = 8.0
        start = gevent.time.time()
        while gevent.time.time() - start < deadline:
            resp = bot.client.wait_msg(EMsg.ClientPersonaState, timeout=2)
            if resp is None:
                break
            for friend in resp.body.friends:
                if int(friend.friendid) == my_steamid:
                    my_rp = friend
                    break
            if my_rp is not None:
                break

        if my_rp is None:
            # 方法 2：直接发 ClientRichPresenceRequest 读 raw kv
            req2 = MsgProto(EMsg.ClientRichPresenceRequest)
            req2.body.steamid_request.append(my_steamid)
            bot.client.send(req2)
            resp2 = bot.client.wait_msg(EMsg.ClientRichPresenceInfo, timeout=5)
            if resp2 is None:
                return jsonify({"error": "两种方法均超时", "my_steamid": str(my_steamid)}), 504

            result = []
            for entry in resp2.body.rich_presence:
                kv_bytes = entry.rich_presence_kv
                import vdf as _vdf
                parsed = {}
                if kv_bytes:
                    try:
                        parsed = _vdf.binary_loads(kv_bytes)
                    except Exception as e:
                        parsed = {"error": str(e)}
                result.append({
                    "steamid": str(entry.steamid_user),
                    "kv_hex": kv_bytes.hex() if kv_bytes else "",
                    "kv_parsed": parsed,
                })
            return jsonify({"method": "ClientRichPresenceInfo", "entries": result,
                            "my_steamid": str(my_steamid)})

        # 解析 rich_presence 字段（repeated {key, value}）
        rp_kv = {pair.key: pair.value for pair in my_rp.rich_presence}

        return jsonify({
            "method": "PersonaState",
            "my_steamid": str(my_steamid),
            "game_played_app_id": my_rp.game_played_app_id,
            "game_name": my_rp.game_name,
            "gameid": str(my_rp.gameid),
            "rich_presence_kv": rp_kv,
            "raw_rich_presence_count": len(my_rp.rich_presence),
        })


    @app.route("/api/debug/my_rp_direct", methods=["GET"])
    def debug_my_rp_direct():
        """
        [调试] 直接用 ClientRichPresenceRequest 读取自己的 RP 数据（不经过 PersonaState）。
        用于准确验证 ClientRichPresenceUpload 是否真的存储在 Steam CM 上。
        """
        if not bot.is_logged_in:
            return jsonify({"error": "未登录"}), 403

        import gevent
        from steam.core.msg import MsgProto
        from steam.enums.emsg import EMsg
        import vdf as _vdf

        my_steamid = int(bot.client.steam_id)

        req = MsgProto(EMsg.ClientRichPresenceRequest)
        req.body.steamid_request.append(my_steamid)
        bot.client.send(req)

        resp = bot.client.wait_msg(EMsg.ClientRichPresenceInfo, timeout=8)
        if resp is None:
            return jsonify({"error": "ClientRichPresenceInfo 超时，Steam CM 未响应"}), 504

        result = []
        for entry in resp.body.rich_presence:
            kv_bytes = entry.rich_presence_kv
            parsed = {}
            hex_str = ""
            if kv_bytes:
                hex_str = kv_bytes.hex()
                try:
                    parsed = _vdf.binary_loads(kv_bytes)
                except Exception as e:
                    parsed = {"parse_error": str(e), "raw_hex": hex_str}
            result.append({
                "steamid": str(entry.steamid_user),
                "has_kv": bool(kv_bytes),
                "kv_hex": hex_str,
                "kv_parsed": parsed,
            })

        return jsonify({
            "my_steamid": str(my_steamid),
            "entries_count": len(result),
            "entries": result,
        })

    @app.route("/api/status", methods=["POST"])
    def set_status():
        """设置自定义游戏状态"""
        data = request.get_json(silent=True) or {}
        status_text = (data.get("text") or "").strip()
        app_id_raw = data.get("app_id")

        if not status_text:
            return jsonify({"success": False, "error": "状态文字不能为空"}), 400

        # app_id 可以是整数或 null
        app_id = int(app_id_raw) if app_id_raw not in (None, "", 0) else None
        noisy = bool(data.get("noisy", False))
        rich_text = (data.get("rich_text") or "").strip() or None
        rich_presence_status = (data.get("rich_presence_status") or "").strip()
        language = (data.get("language") or "english").strip() or "english"
        raw_rp_values = data.get("rich_presence_values")
        rich_presence_values = (
            raw_rp_values
            if isinstance(raw_rp_values, dict)
            else {}
        )
        if rich_text and app_id and not rich_presence_values:
            try:
                rich_presence_values = _resolve_rich_presence_values(
                    bot.client,
                    app_id,
                    rich_text,
                    rich_presence_status or status_text,
                    language,
                )
            except Exception as e:
                logger.warning("解析 Rich Presence 占位符失败 (appid=%s token=%s): %s", app_id, rich_text, e)

        ok = bot.set_status(
            status_text,
            app_id,
            noisy,
            rich_text=rich_text,
            rich_presence_status=rich_presence_status or (status_text if rich_text else None),
            rich_presence_values=rich_presence_values,
        )
        if not ok:
            return jsonify({"success": False, "error": "未登录，请先登录 Steam"}), 403
        return jsonify({
            "success": True,
            "status": status_text,
            "app_id": app_id,
            "noisy": noisy,
            "rich_text": rich_text,
            "rich_presence_status": rich_presence_status or (status_text if rich_text else None),
            "rich_presence_placeholders": list(rich_presence_values.keys()),
        })

    @app.route("/api/status", methods=["DELETE"])
    def clear_status():
        """清除游戏状态"""
        ok = bot.clear_status()
        if not ok:
            return jsonify({"success": False, "error": "未登录"}), 403
        return jsonify({"success": True})

    @app.route("/api/persona_state", methods=["POST"])
    def set_persona_state():
        """设置副状态（在线/忙碌/离开等）"""
        from steam.enums import EPersonaState
        data = request.get_json(silent=True) or {}
        state_value = data.get("state")
        if state_value is None:
            return jsonify({"success": False, "error": "缺少 state 参数"}), 400
        try:
            state = EPersonaState(int(state_value))
        except (ValueError, KeyError):
            return jsonify({"success": False, "error": f"无效的副状态值: {state_value}"}), 400
        ok = bot.set_persona_state(state)
        if not ok:
            return jsonify({"success": False, "error": "未登录，请先登录 Steam"}), 403
        return jsonify({"success": True, "persona_state": state.value, "persona_state_name": state.name})

    @app.route("/api/persona_state_flags", methods=["POST"])
    def set_persona_state_flags():
        """设置 Persona State Flags（客户端类型、VR、RP 等特殊标记）"""
        data = request.get_json(silent=True) or {}
        flags_value = data.get("flags")
        if flags_value is None:
            return jsonify({"success": False, "error": "缺少 flags 参数"}), 400
        try:
            flags = int(flags_value)
        except (TypeError, ValueError):
            return jsonify({"success": False, "error": f"无效的 flags 值: {flags_value}"}), 400
        ok = bot.set_persona_state_flags(flags)
        if not ok:
            return jsonify({"success": False, "error": "未登录或 flags 包含不支持的位"}), 403
        return jsonify({"success": True, "persona_state_flags": flags})

    @app.route("/api/guard_code", methods=["POST"])
    def submit_guard_code():
        """接收来自 Web UI 的 Steam Guard 验证码"""
        data = request.get_json(silent=True) or {}
        code = (data.get("code") or "").strip()
        if not code:
            return jsonify({"success": False, "error": "验证码不能为空"}), 400
        bot.provide_guard_code(code)
        return jsonify({"success": True})

    @app.route("/api/logout", methods=["POST"])
    def logout():
        """登出（保留凭证）"""
        bot.logout()
        return jsonify({"success": True})

    return app
