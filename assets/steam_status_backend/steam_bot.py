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
import socket
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
import requests

import vdf
import gevent
from cryptography.fernet import Fernet

from steam.client import SteamClient
from steam.enums import EResult, EPersonaState, EPersonaStateFlag
from steam.enums.emsg import EMsg
from steam.core.msg import MsgProto
from steam.steamid import SteamID
from steam.utils import ip4_to_int
from steam.core.crypto import rsa_publickey, pkcs1v15_encrypt

logger = logging.getLogger(__name__)

ALLOWED_PERSONA_STATE_FLAGS = sum(flag.value for flag in EPersonaStateFlag)
RICH_PRESENCE_PERSONA_FLAG = EPersonaStateFlag.HasRichPresence.value
MAX_RICH_PRESENCE_KEYS = 20
MAX_RICH_PRESENCE_KEY_BYTES = 64
MAX_RICH_PRESENCE_VALUE_BYTES = 256

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
        name = getattr(result, "name", str(result))
        if code in ERESULT_DESCRIPTIONS:
            return f"错误 {code}（{name}）：{ERESULT_DESCRIPTIONS[code]}"
        
        return f"未知错误 {code}：{name}"
    return str(result)


def _safe_detail_value(value):
    """将 CM 响应字段转成适合日志和 UI 展示的短文本。"""
    if isinstance(value, bytes):
        return value.hex()
    if isinstance(value, (list, tuple)):
        return [_safe_detail_value(item) for item in value]
    if hasattr(value, "name") and hasattr(value, "value"):
        return f"{value.name}({value.value})"
    return value


def _format_error_with_details(message: str, details: dict | None = None) -> str:
    if not details:
        return message

    visible_items = []
    for key, value in details.items():
        normalized_key = str(key).lower()
        if any(secret in normalized_key for secret in ("token", "password", "secret", "key", "session")):
            continue
        if value is None or value == "":
            continue
        visible_items.append(f"{key}={value}")

    if not visible_items:
        return message
    return f"{message}\nCM 返回详情：{'; '.join(visible_items)}"


def _truncate_utf8(value: str, max_bytes: int) -> str:
    """按 Steam Rich Presence 字节限制截断，避免切断 UTF-8 字符。"""
    raw = value.encode("utf-8")
    if len(raw) <= max_bytes:
        return value
    return raw[:max_bytes].decode("utf-8", errors="ignore")


def _sanitize_rich_presence_values(values: dict[str, str] | None) -> dict[str, str]:
    """清洗额外 Rich Presence KV，避免非法 key/value 被 CM 静默丢弃。"""
    if not values:
        return {}

    cleaned: dict[str, str] = {}
    for raw_key, raw_value in values.items():
        key = str(raw_key).strip()
        if not key or key == "steam_display":
            continue
        if len(key.encode("utf-8")) > MAX_RICH_PRESENCE_KEY_BYTES:
            logger.warning("跳过过长的 Rich Presence key：%s", key)
            continue
        value = _truncate_utf8(str(raw_value), MAX_RICH_PRESENCE_VALUE_BYTES)
        if value:
            cleaned[key] = value
    return cleaned

NON_STEAM_GAME_ID = 0x8000000000000000
CM_DIRECTORY_URL = "https://api.steampowered.com/ISteamDirectory/GetCMList/v1/"
IP_GEO_BATCH_URL = "http://ip-api.com/batch"
IP_GEO_FIELDS = "status,message,country,regionName,city,isp,org,as,query"

STEAM_DOMAIN_TARGETS = [
    {
        "domain": "api.steampowered.com",
        "label": "Steam WebAPI",
        "description": "账号登录、Steam Guard、登录轮询、CM 列表发现",
        "port": 443,
    },
    {
        "domain": "steamcommunity.com",
        "label": "Steam 社区",
        "description": "社区会话、WebAPI Key、个人资料、Rich Presence 测试页",
        "port": 443,
    },
    {
        "domain": "store.steampowered.com",
        "label": "Steam 商店",
        "description": "网页登录兼容、商店和账号页面",
        "port": 443,
    },
    {
        "domain": "help.steampowered.com",
        "label": "Steam 帮助",
        "description": "Steam Guard、账号安全和支持页面",
        "port": 443,
    },
    {
        "domain": "steamstatic.com",
        "label": "Steam 静态资源",
        "description": "Steam 页面静态资源与图片",
        "port": 443,
    },
    {
        "domain": "steamusercontent.com",
        "label": "Steam 用户内容",
        "description": "社区头像、截图、用户上传内容",
        "port": 443,
    },
    {
        "domain": "steamcontent.com",
        "label": "Steam 内容分发",
        "description": "SteamPipe 内容、下载和更新相关域名",
        "port": 443,
    },
    {
        "domain": "steamgames.com",
        "label": "Steam 游戏服务",
        "description": "Steam 客户端和游戏服务兼容域名",
        "port": 443,
    },
    {
        "domain": "steam-chat.com",
        "label": "Steam 聊天",
        "description": "好友、聊天与在线体验相关域名",
        "port": 443,
    },
    {
        "domain": "steamcdn-a.akamaihd.net",
        "label": "Steam CDN",
        "description": "Akamai 边缘 CDN 上的 Steam 静态资源",
        "port": 443,
    },
]

AUTH_DIR = os.path.join(os.path.dirname(__file__), "auth")
SESSIONS_FILE = os.path.join(AUTH_DIR, "sessions.json")
KEY_FILE = os.path.join(AUTH_DIR, "session.key")
DOMAIN_PREFS_FILE = os.path.join(AUTH_DIR, "domain_preferences.json")

_ORIGINAL_GETADDRINFO = socket.getaddrinfo
_DNS_OVERRIDE_PROVIDER = None


def _dns_override_getaddrinfo(host, port, family=0, type=0, proto=0, flags=0):
    """让已选择的域名 IP 优先参与解析，同时保留系统 DNS 作为兜底。"""
    provider = _DNS_OVERRIDE_PROVIDER
    selected_ips = []
    if provider is not None and isinstance(host, str):
        selected_ips = provider.selected_ips_for_host(host)

    if not selected_ips:
        return _ORIGINAL_GETADDRINFO(host, port, family, type, proto, flags)

    merged = []
    seen = set()
    for ip in selected_ips:
        try:
            for item in _ORIGINAL_GETADDRINFO(ip, port, family, type, proto, flags):
                key = (item[0], item[1], item[2], item[4])
                if key not in seen:
                    merged.append(item)
                    seen.add(key)
        except OSError:
            continue

    try:
        for item in _ORIGINAL_GETADDRINFO(host, port, family, type, proto, flags):
            key = (item[0], item[1], item[2], item[4])
            if key not in seen:
                merged.append(item)
                seen.add(key)
    except OSError:
        if not merged:
            raise

    return merged


def _install_dns_override(provider) -> None:
    global _DNS_OVERRIDE_PROVIDER
    _DNS_OVERRIDE_PROVIDER = provider
    if socket.getaddrinfo is not _dns_override_getaddrinfo:
        socket.getaddrinfo = _dns_override_getaddrinfo


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


def _parse_cm_endpoint(endpoint: str) -> tuple[str, int] | None:
    """解析 SteamDirectory 返回的 host:port。"""
    host, separator, port_text = endpoint.rpartition(":")
    if not separator or not host or not port_text:
        return None
    try:
        port = int(port_text)
    except ValueError:
        return None
    if port <= 0 or port > 65535:
        return None
    return host, port


class SteamCMOptimizer:
    """获取、测速并向 SteamClient 注入优选 CM 节点。"""

    def __init__(self) -> None:
        self.enabled = True
        self.last_results: list[dict] = []
        self.last_checked_at: float | None = None
        self.last_error: str | None = None
        self.last_applied: list[str] = []
        self.max_count = 24
        self.timeout_seconds = 1.8
        self.cache_ttl_seconds = 15 * 60

    def status(self) -> dict:
        return {
            "enabled": self.enabled,
            "last_checked_at": self.last_checked_at,
            "last_error": self.last_error,
            "last_applied": self.last_applied,
            "max_count": self.max_count,
            "timeout_seconds": self.timeout_seconds,
            "servers": self.last_results,
        }

    def set_enabled(self, enabled: bool) -> dict:
        self.enabled = enabled
        return self.status()

    def should_refresh(self) -> bool:
        if not self.last_results or self.last_checked_at is None:
            return True
        return time.time() - self.last_checked_at > self.cache_ttl_seconds

    def test_servers(
        self,
        max_count: int | None = None,
        timeout_seconds: float | None = None,
    ) -> dict:
        max_count = self._normalize_max_count(max_count)
        timeout_seconds = self._normalize_timeout(timeout_seconds)
        logger.info(
            "开始获取并测速 Steam CM 节点：max_count=%s timeout=%ss",
            max_count,
            timeout_seconds,
        )

        try:
            endpoints = self._fetch_cm_endpoints(max_count)
            results = self._measure_endpoints(endpoints, timeout_seconds)
            self.last_results = results
            self.last_checked_at = time.time()
            self.last_error = None
            self.max_count = max_count
            self.timeout_seconds = timeout_seconds
            logger.info(
                "Steam CM 测速完成：成功 %d/%d",
                len([item for item in results if item["success"]]),
                len(results),
            )
        except Exception as e:
            self.last_error = str(e)
            logger.warning("Steam CM 测速失败：%s", e)

        return self.status()

    def apply_to_client(self, steam_client: SteamClient) -> dict:
        if not self.enabled:
            logger.info("Steam CM 自动优选已关闭，跳过节点注入")
            return self.status()

        if self.should_refresh():
            self.test_servers()

        preferred = [
            item for item in self.last_results
            if item.get("success") and item.get("latency_ms") is not None
        ]
        if not preferred:
            logger.warning("没有可用的 Steam CM 测速结果，保留 steam-py 默认节点列表")
            return self.status()

        server_tuples = []
        applied = []
        for item in preferred:
            parsed = _parse_cm_endpoint(item["endpoint"])
            if parsed is None:
                continue
            server_tuples.append(parsed)
            applied.append(item["endpoint"])

        if not server_tuples:
            return self.status()

        try:
            steam_client.cm_servers.clear()
            steam_client.cm_servers.merge_list(server_tuples)
            self.last_applied = applied
            logger.info("已注入 %d 个优选 Steam CM 节点", len(server_tuples))
        except Exception as e:
            self.last_error = f"应用优选 CM 节点失败：{e}"
            logger.warning(self.last_error)

        return self.status()

    def _fetch_cm_endpoints(self, max_count: int) -> list[str]:
        response = requests.get(
            CM_DIRECTORY_URL,
            params={"cellid": 0, "maxcount": max_count},
            timeout=15,
        )
        response.raise_for_status()
        payload = response.json().get("response", {})
        endpoints = payload.get("serverlist", [])
        if not isinstance(endpoints, list):
            endpoints = []
        unique = []
        seen = set()
        for endpoint in endpoints:
            if not isinstance(endpoint, str):
                continue
            endpoint = endpoint.strip()
            if endpoint and endpoint not in seen and _parse_cm_endpoint(endpoint):
                unique.append(endpoint)
                seen.add(endpoint)
        if not unique:
            raise RuntimeError("SteamDirectory 未返回可用的 CM 节点")
        return unique[:max_count]

    def _measure_endpoints(self, endpoints: list[str], timeout_seconds: float) -> list[dict]:
        workers = min(12, max(1, len(endpoints)))
        results = []
        with ThreadPoolExecutor(max_workers=workers) as executor:
            futures = [
                executor.submit(self._measure_one, endpoint, timeout_seconds)
                for endpoint in endpoints
            ]
            for future in as_completed(futures):
                results.append(future.result())

        results.sort(
            key=lambda item: (
                not item["success"],
                item["latency_ms"] if item["latency_ms"] is not None else 999999,
                item["endpoint"],
            )
        )
        return results

    def _measure_one(self, endpoint: str, timeout_seconds: float) -> dict:
        parsed = _parse_cm_endpoint(endpoint)
        if parsed is None:
            return {
                "endpoint": endpoint,
                "host": "",
                "port": 0,
                "success": False,
                "latency_ms": None,
                "error": "端点格式无效",
            }

        host, port = parsed
        start = time.perf_counter()
        try:
            with socket.create_connection((host, port), timeout=timeout_seconds):
                latency_ms = round((time.perf_counter() - start) * 1000, 1)
            return {
                "endpoint": endpoint,
                "host": host,
                "port": port,
                "success": True,
                "latency_ms": latency_ms,
                "error": None,
            }
        except Exception as e:
            return {
                "endpoint": endpoint,
                "host": host,
                "port": port,
                "success": False,
                "latency_ms": None,
                "error": str(e),
            }

    def _normalize_max_count(self, value: int | None) -> int:
        if value is None:
            return self.max_count
        return max(4, min(int(value), 64))

    def _normalize_timeout(self, value: float | None) -> float:
        if value is None:
            return self.timeout_seconds
        return max(0.5, min(float(value), 5.0))


class SteamDomainOptimizer:
    """管理 Steam 全流程域名的解析结果和用户选择的优选 IP。"""

    def __init__(self) -> None:
        self.targets = STEAM_DOMAIN_TARGETS
        self.preferences = self._load_preferences()
        self.last_results: dict[str, dict] = {}

    def status(self) -> dict:
        return {
            "domains": [
                self._domain_status(target["domain"])
                for target in self.targets
            ],
        }

    def selected_ips_for_host(self, host: str) -> list[str]:
        domain = host.lower().strip(".")
        pref = self.preferences.get(domain, {})
        if not pref.get("enabled", True):
            return []
        selected = pref.get("selected_ips", [])
        return [ip for ip in selected if isinstance(ip, str) and ip]

    def resolve_domains(
        self,
        domains: list[str] | None = None,
        max_ips: int = 12,
        timeout_seconds: float = 1.8,
    ) -> dict:
        requested = {domain.lower() for domain in domains or [] if isinstance(domain, str)}
        targets = [
            target for target in self.targets
            if not requested or target["domain"] in requested
        ]
        max_ips = max(1, min(int(max_ips), 32))
        timeout_seconds = max(0.5, min(float(timeout_seconds), 5.0))

        ip_records: dict[str, list[dict]] = {}
        all_ips: list[str] = []
        for target in targets:
            domain = target["domain"]
            port = int(target.get("port", 443))
            try:
                ips = self._resolve_domain_ips(domain, port, max_ips)
                measured = self._measure_domain_ips(ips, port, timeout_seconds)
                ip_records[domain] = measured
                all_ips.extend([item["address"] for item in measured])
                self.last_results[domain] = {
                    "last_resolved_at": time.time(),
                    "last_error": None,
                    "ips": measured,
                }
            except Exception as e:
                self.last_results[domain] = {
                    "last_resolved_at": time.time(),
                    "last_error": str(e),
                    "ips": [],
                }

        geo_map = self._lookup_ip_geo(all_ips)
        for domain, items in ip_records.items():
            pref = self.preferences.get(domain, {})
            selected = set(pref.get("selected_ips", []))
            for item in items:
                geo = geo_map.get(item["address"], {})
                item.update(geo)
                item["location"] = self._geo_description(geo)
                item["selected"] = item["address"] in selected
            self.last_results[domain]["ips"] = items

        return self.status()

    def update_domain_preference(
        self,
        domain: str,
        enabled: bool | None = None,
        selected_ips: list[str] | None = None,
    ) -> dict:
        domain = domain.lower().strip()
        if domain not in {target["domain"] for target in self.targets}:
            raise ValueError(f"未知域名：{domain}")

        pref = self.preferences.get(domain, {"enabled": True, "selected_ips": []})
        if enabled is not None:
            pref["enabled"] = bool(enabled)
        if selected_ips is not None:
            known_ips = {
                item["address"]
                for item in self.last_results.get(domain, {}).get("ips", [])
            }
            clean_ips = []
            for ip in selected_ips:
                if not isinstance(ip, str) or not ip:
                    continue
                if known_ips and ip not in known_ips:
                    continue
                clean_ips.append(ip)
            pref["selected_ips"] = list(dict.fromkeys(clean_ips))

        self.preferences[domain] = pref
        self._save_preferences()
        return self.status()

    def _domain_status(self, domain: str) -> dict:
        target = next(item for item in self.targets if item["domain"] == domain)
        pref = self.preferences.get(domain, {"enabled": True, "selected_ips": []})
        result = self.last_results.get(domain, {})
        selected = set(pref.get("selected_ips", []))
        ips = []
        for item in result.get("ips", []):
            copied = dict(item)
            copied["selected"] = copied.get("address") in selected
            ips.append(copied)
        return {
            "domain": domain,
            "label": target["label"],
            "description": target["description"],
            "port": target.get("port", 443),
            "enabled": pref.get("enabled", True),
            "selected_ips": list(selected),
            "last_resolved_at": result.get("last_resolved_at"),
            "last_error": result.get("last_error"),
            "ips": ips,
        }

    def _resolve_domain_ips(self, domain: str, port: int, max_ips: int) -> list[str]:
        infos = _ORIGINAL_GETADDRINFO(
            domain,
            port,
            socket.AF_UNSPEC,
            socket.SOCK_STREAM,
        )
        ips = []
        for info in infos:
            address = info[4][0]
            if address not in ips:
                ips.append(address)
        if not ips:
            raise RuntimeError("系统 DNS 未返回 IP")
        return ips[:max_ips]

    def _measure_domain_ips(
        self,
        ips: list[str],
        port: int,
        timeout_seconds: float,
    ) -> list[dict]:
        results = []
        workers = min(10, max(1, len(ips)))
        with ThreadPoolExecutor(max_workers=workers) as executor:
            futures = [
                executor.submit(self._measure_ip, ip, port, timeout_seconds)
                for ip in ips
            ]
            for future in as_completed(futures):
                results.append(future.result())
        results.sort(
            key=lambda item: (
                not item["success"],
                item["latency_ms"] if item["latency_ms"] is not None else 999999,
                item["address"],
            )
        )
        return results

    def _measure_ip(self, ip: str, port: int, timeout_seconds: float) -> dict:
        start = time.perf_counter()
        try:
            with socket.create_connection((ip, port), timeout=timeout_seconds):
                latency_ms = round((time.perf_counter() - start) * 1000, 1)
            return {
                "address": ip,
                "success": True,
                "latency_ms": latency_ms,
                "error": None,
            }
        except Exception as e:
            return {
                "address": ip,
                "success": False,
                "latency_ms": None,
                "error": str(e),
            }

    def _lookup_ip_geo(self, ips: list[str]) -> dict[str, dict]:
        unique_ips = list(dict.fromkeys(ips))
        if not unique_ips:
            return {}
        try:
            response = requests.post(
                IP_GEO_BATCH_URL,
                params={"fields": IP_GEO_FIELDS, "lang": "zh-CN"},
                json=[{"query": ip} for ip in unique_ips[:100]],
                timeout=12,
            )
            response.raise_for_status()
            payload = response.json()
        except Exception as e:
            logger.warning("IP 属地查询失败：%s", e)
            return {}

        result = {}
        if not isinstance(payload, list):
            return result
        for item in payload:
            if not isinstance(item, dict):
                continue
            query = item.get("query")
            if query:
                result[query] = item
        return result

    def _geo_description(self, geo: dict) -> str:
        if geo.get("status") != "success":
            return "属地未知"
        parts = [
            geo.get("country"),
            geo.get("regionName"),
            geo.get("city"),
        ]
        location = " ".join([part for part in parts if part])
        network = geo.get("isp") or geo.get("org") or geo.get("as")
        if location and network:
            return f"{location} · {network}"
        return location or network or "属地未知"

    def _load_preferences(self) -> dict:
        try:
            with open(DOMAIN_PREFS_FILE, "r", encoding="utf-8") as f:
                data = json.load(f)
        except Exception:
            data = {}
        if not isinstance(data, dict):
            return {}
        allowed = {target["domain"] for target in self.targets}
        return {
            domain: value
            for domain, value in data.items()
            if domain in allowed and isinstance(value, dict)
        }

    def _save_preferences(self) -> None:
        os.makedirs(AUTH_DIR, exist_ok=True)
        with open(DOMAIN_PREFS_FILE, "w", encoding="utf-8") as f:
            json.dump(self.preferences, f, ensure_ascii=False, indent=2)


class ModernSteamClient(SteamClient):
    """继承 SteamClient 以提供通过 access_token 登录 CM 服务器的功能"""

    CHANNEL_SECURED_TIMEOUT = 20
    
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self._last_username = None
        self._last_refresh_token = None
        self._last_cm_logon_details = None
        self._auto_relogin = True
        self.on('logged_off', self._handle_logged_off_override)

    @property
    def last_cm_logon_details(self):
        return self._last_cm_logon_details

    def _handle_logged_off_override(self, result):
        if self._auto_relogin and self._last_refresh_token:
            self._LOG.info("检测到服务器登出，因为配置了自动重连，恢复 _logged_on_once 以便网络重连后触发 relogin")
            self._logged_on_once = True

    def _pre_login(self):
        if self.logged_on:
            self._LOG.debug("Trying to login while logged on???")
            raise RuntimeError("Already logged on")

        if not self.connected and not self._connecting:
            if not self.connect():
                return EResult.Fail

        if not self.channel_secured:
            resp = self.wait_event(
                self.EVENT_CHANNEL_SECURED,
                timeout=self.CHANNEL_SECURED_TIMEOUT,
            )

            if resp is None:
                server_addr = getattr(self, "current_server_addr", None)
                self._last_cm_logon_details = {
                    "phase": "channel_secured",
                    "eresult": f"{EResult.TryAnotherCM.name}({EResult.TryAnotherCM.value})",
                    "cm_server": server_addr,
                    "timeout_seconds": self.CHANNEL_SECURED_TIMEOUT,
                    "reason": "等待 CM channel_secured 握手超时",
                }
                if server_addr:
                    self.cm_servers.mark_bad(server_addr)
                    self._LOG.warning(
                        "Steam CM %s channel_secured handshake timed out; marked as bad.",
                        server_addr,
                    )
                return EResult.TryAnotherCM

        return EResult.OK

    def login_with_access_token(self, username: str, refresh_token: str, login_id=None) -> EResult:
        self._last_username = username
        self._last_refresh_token = refresh_token
        self._auto_relogin = True
        self._last_cm_logon_details = None
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
        self._last_cm_logon_details = self._extract_logon_response_details(resp)
        if resp and resp.body.eresult == EResult.OK:
            self.sleep(0.5)
        return EResult(resp.body.eresult) if resp else EResult.Fail

    def _extract_logon_response_details(self, resp):
        server_addr = getattr(self, "current_server_addr", None)
        if resp is None:
            return {
                "phase": "ClientLogOnResponse",
                "eresult": f"{EResult.Fail.name}({EResult.Fail.value})",
                "cm_server": server_addr,
                "timeout_seconds": 30,
                "reason": "等待 CM ClientLogOnResponse 超时",
            }

        result = EResult(resp.body.eresult)
        details = {
            "phase": "ClientLogOnResponse",
            "eresult": f"{result.name}({result.value})",
            "cm_server": server_addr,
        }

        try:
            for field, value in resp.body.ListFields():
                details[field.name] = _safe_detail_value(value)
        except Exception as e:
            details["parse_error"] = str(e)

        return details

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
    app_id: int | None,
    status_text: str = "",
    rich_presence_values: dict[str, str] | None = None,
) -> MsgProto:
    """构建 Rich Presence 上传消息。

    rich_text 是 token key（'#' 开头）。
    status_text 会写入默认 status key，额外占位符由 rich_presence_values 提供。
    friend_steamids 是好友 SteamID 列表（必须填写）。
    app_id 写入 protobuf header.routing_appid，否则 CM 无法可靠关联游戏配置。

    VDF binary 格式说明：
    根节点必须是空字符串 ''（参考 SteamKit2 SetRichPresence 实现），
    不能是 'RP'。Steam CM 只接受根节点为空字符串的格式。
    """
    msg = MsgProto(EMsg.ClientRichPresenceUpload)
    if app_id is not None:
        msg.header.routing_appid = int(app_id)
    kv: dict = {"steam_display": rich_text}
    if status_text:
        kv["status"] = _truncate_utf8(status_text, MAX_RICH_PRESENCE_VALUE_BYTES)
    for key, value in _sanitize_rich_presence_values(rich_presence_values).items():
        if key in kv:
            continue
        if len(kv) >= MAX_RICH_PRESENCE_KEYS:
            logger.warning("Rich Presence key 数量超过 Steam 限制，已跳过：%s", key)
            break
        kv[key] = value
    # 根节点必须是空字符串（Steam CM 要求）
    rp_data = {"": kv}
    msg.body.rich_presence_kv = vdf.binary_dumps(rp_data)
    for sid in friend_steamids:
        msg.body.steamid_broadcast.append(sid)
    return msg

def _build_clear_rich_presence_msg(
    friend_steamids: list[int],
    app_id: int | None = None,
) -> MsgProto:
    """清除 Rich Presence，通知所有好友。"""
    msg = MsgProto(EMsg.ClientRichPresenceUpload)
    if app_id is not None:
        msg.header.routing_appid = int(app_id)
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
        self.cm_optimizer = SteamCMOptimizer()
        self.domain_optimizer = SteamDomainOptimizer()
        _install_dns_override(self.domain_optimizer)
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
        self._current_persona_state_flags: int = 0

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

    @property
    def current_persona_state_flags(self) -> int: return self._current_persona_state_flags

    def get_cm_preference_status(self) -> dict:
        """返回当前 CM 优选设置和最近一次测速结果。"""
        return self.cm_optimizer.status()

    def set_cm_auto_preference(self, enabled: bool) -> dict:
        """开启或关闭登录前自动应用 CM 优选。"""
        status = self.cm_optimizer.set_enabled(enabled)
        self._on_status_change("cm_preference_updated", status)
        return status

    def test_cm_servers(
        self,
        max_count: int | None = None,
        timeout_seconds: float | None = None,
        apply: bool = True,
    ) -> dict:
        """立即拉取并测速 Steam CM 节点，必要时把结果注入客户端。"""
        self._on_status_change("cm_testing", {
            "message": "正在拉取并测速 Steam CM 节点..."
        })
        status = self.cm_optimizer.test_servers(max_count, timeout_seconds)
        if apply:
            status = self.cm_optimizer.apply_to_client(self.client)
        self._on_status_change("cm_preference_updated", status)
        return status

    def get_domain_preference_status(self) -> dict:
        """返回 Steam 全流程域名解析和用户 IP 选择状态。"""
        return self.domain_optimizer.status()

    def resolve_steam_domains(self, domains: list[str] | None = None) -> dict:
        """解析 Steam 全流程域名，补充 TCP 延迟和中文 IP 属地。"""
        self._on_status_change("domain_resolving", {
            "message": "正在解析 Steam 全流程域名并查询 IP 属地..."
        })
        status = self.domain_optimizer.resolve_domains(domains=domains)
        self._on_status_change("domain_preference_updated", status)
        return status

    def update_domain_preference(
        self,
        domain: str,
        enabled: bool | None = None,
        selected_ips: list[str] | None = None,
    ) -> dict:
        """更新某个 Steam 域名是否启用 DNS 优选及选择的 IP。"""
        status = self.domain_optimizer.update_domain_preference(
            domain,
            enabled=enabled,
            selected_ips=selected_ips,
        )
        self._on_status_change("domain_preference_updated", status)
        return status

    def _handle_error(self, result):
        result_val = getattr(result, "value", result)
        # TryAnotherCM (48)：通常是当前 CM 节点握手超时或节点暂时不可用。
        if result_val == EResult.TryAnotherCM or result_val == 48:
            self._try_another_cm_count += 1
            logger.debug(
                "Steam CM 节点握手失败（TryAnotherCM），累计 %d 次",
                self._try_another_cm_count,
            )
            if self._try_another_cm_count >= self._TRY_ANOTHER_CM_THRESHOLD:
                self._try_another_cm_count = 0
                logger.warning(
                    "连续 %d 次 TryAnotherCM，Steam CM 握手持续失败。",
                    self._TRY_ANOTHER_CM_THRESHOLD,
                )
                self._on_status_change("error", {
                    "message": _format_error_with_details(
                        "Steam CM 节点连续握手失败，请稍后重试；如果一直失败，请检查代理、防火墙或本机到 Steam CM 的网络连接。",
                        self.client.last_cm_logon_details,
                    ),
                })
            return
        self._try_another_cm_count = 0
        err_msg = get_error_message(result)
        logger.error("Steam 报错：%s", err_msg)
        self._on_status_change("error", {
            "message": _format_error_with_details(
                err_msg,
                self.client.last_cm_logon_details,
            )
        })

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
                    self.client.change_status(
                        persona_state=self._current_persona_state,
                        persona_state_flags=self._current_persona_state_flags,
                        persona_set_by_user=True,
                    )
                
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

        当 login_with_access_token 返回 TryAnotherCM 时（CM 握手超时），
        会标记当前 CM 节点不可用，断线后重试最多 3 次。
        """
        _MAX_CM_RETRIES = 3
        logger.info("使用 refresh_token 登录 Steam CM 服务器...")
        self._on_status_change("cm_connecting", {
            "message": "Steam 已授权，正在连接 Steam CM 服务器..."
        })
        self._is_connecting = True
        try:
            if _cm_retry == 0:
                self.cm_optimizer.apply_to_client(self.client)
            result = self.client.login_with_access_token(self._username, refresh_token)
            if result == EResult.OK:
                self._logged_in = True
                self._try_another_cm_count = 0  # 登录成功，重置计数器
                logger.info("✅ 登录成功，账号：%s", self._username)
                self.client.change_status(
                    persona_state=EPersonaState.Online,
                    persona_state_flags=self._current_persona_state_flags,
                )
                
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
                        "CM 节点握手超时（TryAnotherCM），第 %d/%d 次切换节点重试...",
                        _cm_retry + 1, _MAX_CM_RETRIES,
                    )
                    self._on_status_change("cm_connecting", {
                        "message": f"Steam CM 节点握手超时，正在切换节点重试（{_cm_retry + 1}/{_MAX_CM_RETRIES}）..."
                    })
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
                        "连续 %d 次 TryAnotherCM，Steam CM 握手持续失败。",
                        _MAX_CM_RETRIES + 1,
                    )
                    self._on_status_change("error", {
                        "message": _format_error_with_details(
                            "Steam CM 节点连续握手失败，请稍后重试；如果一直失败，请检查代理、防火墙或本机到 Steam CM 的网络连接。",
                            self.client.last_cm_logon_details,
                        ),
                    })
            else:
                self._handle_error(result)
        except Exception as e:
            logger.exception("连接 Steam CM 服务器异常")
            self._logged_in = False
            self._on_status_change("error", {
                "message": f"连接 Steam CM 服务器失败：{e}"
            })
        finally:
            self._is_connecting = False

    def _encrypt_password_webapi(self, username, password):
        """WebAPI: 请求 RSA 公钥并加密密码"""
        url = "https://api.steampowered.com/IAuthenticationService/GetPasswordRSAPublicKey/v1/"
        resp = requests.get(url, params={"account_name": username}, timeout=20).json()
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
        consecutive_errors = 0
        
        while self._is_polling:
            gevent.sleep(self._poll_interval)
            try:
                data = {"client_id": self._client_id, "request_id": self._request_id}
                resp = requests.post(url, data=data, timeout=20).json()
                response = resp.get("response", {})
                consecutive_errors = 0
                
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
                consecutive_errors += 1
                logger.warning("轮询登录状态异常: %s", e)
                if consecutive_errors >= 3:
                    self._is_polling = False
                    self._on_status_change("error", {
                        "message": f"轮询 Steam 登录状态失败：{e}"
                    })
                    return
        
    def login_with_credentials(self, username: str, password: str) -> None:
        def _task():
            self._username = username
            self._refresh_token = None
            try:
                logger.info("请求 RSA 密钥并加密密码...")
                self._on_status_change("login_started", {
                    "message": "正在请求 Steam RSA 密钥并加密密码..."
                })
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
                self._on_status_change("login_waiting", {
                    "message": "正在向 Steam 提交登录请求..."
                })
                resp = requests.post(url, data=data, timeout=30).json().get("response", {})
                
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
                else:
                    self._on_status_change("login_waiting", {
                        "message": "登录请求已提交，正在等待 Steam 授权..."
                    })
                
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
                self._on_status_change("login_waiting", {
                    "message": "验证码已提交，正在等待 Steam 授权..."
                })
                requests.post(url, data=data, timeout=20)
                logger.info("已提交验证码，等待验证...")
            except Exception as e:
                logger.warning("提交验证码失败: %s", e)
                self._on_status_change("error", {"message": f"提交验证码失败：{e}"})
        gevent.spawn(_task)

    def login_with_refresh_token(self, username: str) -> None:
        """使用保存的 refresh_token 换取 access_token 并登录"""
        def _task():
            self._username = username
            self._on_status_change("login_started", {
                "message": "正在读取已保存的 Steam 登录凭证..."
            })
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
                persona_state_flags=self._current_persona_state_flags,
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
                        persona_state_flags=self._current_persona_state_flags,
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
        self.client.change_status(
            persona_state=state,
            persona_state_flags=self._current_persona_state_flags,
            persona_set_by_user=True,
        )
        self._current_persona_state = state
        self._on_status_change("persona_state_updated", {
            "persona_state": state.value,
            "persona_state_name": state.name,
        })
        return True

    def set_persona_state_flags(self, flags: int) -> bool:
        if not self._logged_in: return False
        if flags < 0 or flags & ~ALLOWED_PERSONA_STATE_FLAGS:
            logger.warning("拒绝无效 Persona State Flags：%s", flags)
            return False

        self.client.change_status(
            persona_state=self._current_persona_state,
            persona_state_flags=flags,
            persona_set_by_user=True,
        )
        self._current_persona_state_flags = flags
        self._on_status_change("persona_state_flags_updated", {
            "persona_state_flags": flags,
        })
        return True

    def run(self) -> None:
        self.client.connect()
        self.client.run_forever()
