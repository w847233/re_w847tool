"""
app.py — 主入口

启动流程：
1. 在 gevent greenlet 中运行 Steam 客户端后台循环
2. 启动 Flask 服务器（localhost:5000）
3. 登录交互全部转移到 Web 控制面板
"""

# ⚠️ gevent monkey patch 必须是文件中第一个执行的代码
from gevent import monkey
monkey.patch_all()

import logging
import os
import sys
sys.stdout.reconfigure(encoding='utf-8')
import threading

import gevent

from steam_bot import SteamBot
from web_server import create_app

# ── 日志配置 ────────────────────────────────────────────────────────────────
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    datefmt="%H:%M:%S",
)
logger = logging.getLogger(__name__)

HOST = os.environ.get("STATUSHACK_HOST", "127.0.0.1")
PORT = int(os.environ.get("STATUSHACK_PORT", "5000"))

# ── 事件状态（用于跨线程通知 Web UI）────────────────────────────────────────
_client_queues: set = set()
_events_lock = threading.Lock()


def on_status_change(event_type: str, data: dict) -> None:
    """统一的状态变更回调（线程安全）"""
    event = {"type": event_type, "data": data}
    with _events_lock:
        for q in _client_queues:
            q.put(event)

    if event_type == "auth_code_required":
        # 同时在终端提示（兼容无 Web UI 的情况）
        prompt = data.get("prompt", "请输入 Steam Guard 验证码：")
        logger.info("⚠️  %s", prompt)

    elif event_type == "logged_on":
        logger.info("🎮 Steam 控制面板已就绪：http://%s:%s", HOST, PORT)

    elif event_type == "error":
        logger.error("❌ %s", data.get("message"))

    elif event_type == "disconnected":
        logger.warning("🔌 已断开连接")


def main() -> None:
    print("\n🎮 Steam 自定义状态工具")
    print("─" * 40)

    # ── 1. 创建 SteamBot 实例 ────────────────────────────────────────────
    bot = SteamBot(on_status_change=on_status_change)

    # ── 4. 将 pending_events 注入 Flask 上下文（通过 bot 引用） ────────────
    flask_app = create_app(bot)

    # 添加 SSE（Server-Sent Events）端点，Web UI 用它轮询事件
    from flask import Response
    import json as json_mod
    from gevent.queue import Queue, Empty

    @flask_app.route("/api/events")
    def sse_events():
        """Server-Sent Events：推送连接状态变更到 Web UI"""
        def generate():
            q = Queue()
            with _events_lock:
                _client_queues.add(q)
            try:
                while True:
                    try:
                        evt = q.get(timeout=1.0)
                        yield f"data: {json_mod.dumps(evt, ensure_ascii=False)}\n\n"
                    except Empty:
                        # 每 1 秒发一次心跳（避免连接超时）
                        yield ": heartbeat\n\n"
            except GeneratorExit:
                pass
            finally:
                with _events_lock:
                    _client_queues.discard(q)

        return Response(generate(), mimetype="text/event-stream",
                        headers={"Cache-Control": "no-cache",
                                 "X-Accel-Buffering": "no"})

    # ── 3. 启动 Steam 客户端（gevent greenlet）───────────────────────────
    # 启动客户端连接循环，此时未登录
    gevent.spawn(bot.run)

    # ── 4. 启动 Flask 服务器（阻塞）────────────────────────────────────────
    logger.info("🌐 Web 控制面板启动中：http://%s:%s", HOST, PORT)
    print("\n" + "─" * 40)
    print(f"  控制面板地址：http://{HOST}:{PORT}")
    print("  按 Ctrl+C 退出")
    print("─" * 40 + "\n")

    from gevent.pywsgi import WSGIServer
    server = WSGIServer((HOST, PORT), flask_app, log=None)
    
    # 捕获 Ctrl+C 信号，避免 gevent 打印烦人的 KeyboardInterrupt 堆栈
    import signal
    def handle_sigint(*args):
        print("\n\n👋 已收到退出信号。")
        print("正在停止服务并释放端口，请稍候...")
        server.stop()
        bot.client.disconnect()
        sys.exit(0)
        
    gevent.signal_handler(signal.SIGINT, handle_sigint)

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        pass


if __name__ == "__main__":
    main()
