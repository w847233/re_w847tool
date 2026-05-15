package com.w847.personal_toolbox

import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.Closeable
import java.io.IOException
import java.net.Inet4Address
import java.net.InetSocketAddress
import java.net.ServerSocket
import java.net.Socket
import java.nio.ByteBuffer
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.concurrent.thread
import kotlin.math.min

class MainActivity : FlutterActivity() {
    private var natTraversalChannel: NatTraversalChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        natTraversalChannel = NatTraversalChannel(flutterEngine)
    }

    override fun onDestroy() {
        natTraversalChannel?.dispose()
        natTraversalChannel = null
        super.onDestroy()
    }
}

private class NatTraversalChannel(flutterEngine: FlutterEngine) {
    private val mainHandler = Handler(Looper.getMainLooper())
    private val executor = Executors.newCachedThreadPool()
    private val mappings = ConcurrentHashMap<String, TcpForwardMapping>()
    private val channel = MethodChannel(
        flutterEngine.dartExecutor.binaryMessenger,
        "personal_toolbox/nat_traversal",
    )

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "startTcpForward" -> startTcpForward(call, result)
                "stopTcpForward" -> stopTcpForward(call, result)
                "stopAllTcpForward" -> stopAllTcpForward(result)
                else -> result.notImplemented()
            }
        }
    }

    fun dispose() {
        stopAll()
        executor.shutdownNow()
        channel.setMethodCallHandler(null)
    }

    private fun startTcpForward(call: MethodCall, result: MethodChannel.Result) {
        val ruleId = call.argument<String>("ruleId").orEmpty()
        if (ruleId.isBlank()) {
            result.error("bad_args", "start_tcp_forward_missing_rule_id", null)
            return
        }
        val stunHost = call.argument<String>("stunHost").orEmpty()
        val stunPort = call.argument<Int>("stunPort") ?: 3478
        val httpHost = call.argument<String>("httpHost").orEmpty()
        val httpPort = call.argument<Int>("httpPort") ?: 80
        val targetHost = call.argument<String>("targetHost").orEmpty()
        val targetPort = call.argument<Int>("targetPort") ?: 0
        val keepAliveSeconds = call.argument<Int>("keepAliveSeconds") ?: 30

        executor.execute {
            stopRule(ruleId)
            val mapping = TcpForwardMapping(
                ruleId = ruleId,
                stunHost = stunHost,
                stunPort = stunPort,
                httpHost = httpHost,
                httpPort = httpPort,
                targetHost = targetHost,
                targetPort = targetPort,
                keepAliveSeconds = keepAliveSeconds,
            )
            try {
                val start = mapping.start()
                mappings[ruleId] = mapping
                postSuccess(
                    result,
                    mapOf(
                        "publicIp" to start.publicIp,
                        "publicPort" to start.publicPort,
                        "localBindPort" to start.localBindPort,
                    ),
                )
            } catch (error: Exception) {
                mapping.stop()
                postError(result, "start_failed", error.message ?: error.toString())
            }
        }
    }

    private fun stopTcpForward(call: MethodCall, result: MethodChannel.Result) {
        val ruleId = call.argument<String>("ruleId").orEmpty()
        executor.execute {
            stopRule(ruleId)
            postSuccess(result, true)
        }
    }

    private fun stopAllTcpForward(result: MethodChannel.Result) {
        executor.execute {
            stopAll()
            postSuccess(result, true)
        }
    }

    private fun stopRule(ruleId: String) {
        mappings.remove(ruleId)?.stop()
    }

    private fun stopAll() {
        val current = mappings.values.toList()
        mappings.clear()
        current.forEach { it.stop() }
    }

    private fun postSuccess(result: MethodChannel.Result, value: Any?) {
        mainHandler.post { result.success(value) }
    }

    private fun postError(result: MethodChannel.Result, code: String, message: String) {
        mainHandler.post { result.error(code, message, null) }
    }
}

private data class MappingStartResult(
    val publicIp: String,
    val publicPort: Int,
    val localBindPort: Int,
)

private class TcpForwardMapping(
    private val ruleId: String,
    private val stunHost: String,
    private val stunPort: Int,
    private val httpHost: String,
    private val httpPort: Int,
    private val targetHost: String,
    private val targetPort: Int,
    keepAliveSeconds: Int,
) {
    private val stopped = AtomicBoolean(false)
    private val keepAliveDelayMs = (if (keepAliveSeconds <= 0) 30 else keepAliveSeconds) * 1000L
    private var keepSocket: Socket? = null
    private var serverSocket: ServerSocket? = null

    fun start(): MappingStartResult {
        if (targetPort <= 0) {
            throw IOException("target_port_invalid")
        }

        val httpAddress = InetSocketAddress(httpHost, httpPort)
        val stunAddress = InetSocketAddress(stunHost, stunPort)

        val keep = createReusableSocket()
        keep.bind(InetSocketAddress("0.0.0.0", 0))
        keep.connect(httpAddress, CONNECT_TIMEOUT_MS)
        keep.tcpNoDelay = true
        keepSocket = keep

        val localAddress = keep.localAddress
        val localPort = keep.localPort

        createReusableSocket().use { stunSocket ->
            stunSocket.bind(InetSocketAddress(localAddress, localPort))
            stunSocket.connect(stunAddress, CONNECT_TIMEOUT_MS)
            stunSocket.tcpNoDelay = true
            stunSocket.soTimeout = CONNECT_TIMEOUT_MS
            val publicEndpoint = performTcpStun(stunSocket)

            val listener = ServerSocket()
            listener.reuseAddress = true
            listener.bind(InetSocketAddress(localAddress, localPort))
            serverSocket = listener

            thread(
                name = "nat-tcp-keepalive-$ruleId",
                isDaemon = true,
                block = ::keepAliveLoop,
            )
            thread(
                name = "nat-tcp-accept-$ruleId",
                isDaemon = true,
                block = ::acceptLoop,
            )

            return MappingStartResult(
                publicIp = publicEndpoint.first,
                publicPort = publicEndpoint.second,
                localBindPort = localPort,
            )
        }
    }

    fun stop() {
        if (!stopped.compareAndSet(false, true)) {
            return
        }
        keepSocket.closeQuietly()
        serverSocket.closeQuietly()
    }

    private fun keepAliveLoop() {
        val socket = keepSocket ?: return
        val request = (
            "HEAD / HTTP/1.1\r\n" +
                "Host: $httpHost\r\n" +
                "Connection: keep-alive\r\n\r\n"
            ).toByteArray(Charsets.US_ASCII)
        val buffer = ByteArray(4096)
        try {
            socket.soTimeout = 2000
            while (!stopped.get()) {
                socket.getOutputStream().write(request)
                socket.getOutputStream().flush()
                try {
                    socket.getInputStream().read(buffer)
                } catch (_: IOException) {
                }
                sleepInterruptibly(keepAliveDelayMs)
            }
        } catch (_: IOException) {
            stop()
        }
    }

    private fun acceptLoop() {
        val listener = serverSocket ?: return
        while (!stopped.get()) {
            try {
                val client = listener.accept()
                thread(name = "nat-tcp-client-$ruleId", isDaemon = true) {
                    handleClient(client)
                }
            } catch (_: IOException) {
                if (!stopped.get()) {
                    stop()
                }
                break
            }
        }
    }

    private fun handleClient(client: Socket) {
        createReusableSocket().use { target ->
            try {
                target.connect(InetSocketAddress(targetHost, targetPort), CONNECT_TIMEOUT_MS)
                target.tcpNoDelay = true
                val leftDone = AtomicBoolean(false)
                val rightDone = AtomicBoolean(false)
                val left = thread(name = "nat-tcp-c2t-$ruleId", isDaemon = true) {
                    pipe(client, target, leftDone)
                }
                val right = thread(name = "nat-tcp-t2c-$ruleId", isDaemon = true) {
                    pipe(target, client, rightDone)
                }
                while (!leftDone.get() && !rightDone.get() && !stopped.get()) {
                    Thread.sleep(100)
                }
                client.closeQuietly()
                target.closeQuietly()
                left.join(1000)
                right.join(1000)
            } finally {
                client.closeQuietly()
            }
        }
    }

    private fun pipe(inputSocket: Socket, outputSocket: Socket, done: AtomicBoolean) {
        val buffer = ByteArray(8192)
        try {
            val input = inputSocket.getInputStream()
            val output = outputSocket.getOutputStream()
            while (!stopped.get()) {
                val read = input.read(buffer)
                if (read <= 0) {
                    break
                }
                output.write(buffer, 0, read)
                output.flush()
            }
        } catch (_: IOException) {
        } finally {
            done.set(true)
            inputSocket.closeQuietly()
            outputSocket.closeQuietly()
        }
    }

    private fun sleepInterruptibly(durationMs: Long) {
        var remaining = durationMs
        while (remaining > 0 && !stopped.get()) {
            val step = min(remaining, 200L)
            Thread.sleep(step)
            remaining -= step
        }
    }

    private fun createReusableSocket(): Socket {
        val socket = Socket()
        socket.reuseAddress = true
        socket.keepAlive = true
        return socket
    }
}

private fun performTcpStun(socket: Socket): Pair<String, Int> {
    val output = socket.getOutputStream()
    val input = socket.getInputStream()
    val request = buildStunBindingRequest()
    output.write(request)
    output.flush()

    val header = input.readExactly(20)
    val bodyLength = readUInt16(header, 2)
    if (bodyLength <= 0 || bodyLength > MAX_STUN_BODY_SIZE) {
        throw IOException("tcp_stun_body_size_invalid")
    }
    val body = input.readExactly(bodyLength)
    return parseStunMappedAddress(header, body)
        ?: throw IOException("tcp_stun_response_has_no_mapped_address")
}

private fun buildStunBindingRequest(): ByteArray {
    val buffer = ByteBuffer.allocate(20)
    buffer.putShort(0x0001)
    buffer.putShort(0x0000)
    buffer.putInt(STUN_MAGIC_COOKIE)
    val id = UUID.randomUUID()
    buffer.putLong(id.mostSignificantBits)
    buffer.putInt((id.leastSignificantBits ushr 32).toInt())
    return buffer.array()
}

private fun parseStunMappedAddress(header: ByteArray, body: ByteArray): Pair<String, Int>? {
    var offset = 0
    while (offset + 4 <= body.size) {
        val type = readUInt16(body, offset)
        val length = readUInt16(body, offset + 2)
        val valueOffset = offset + 4
        if (valueOffset + length > body.size) {
            return null
        }
        if ((type == 0x0001 || type == 0x0020) && length >= 8 && body[valueOffset + 1].toInt() == 0x01) {
            var port = readUInt16(body, valueOffset + 2)
            val address = body.copyOfRange(valueOffset + 4, valueOffset + 8)
            if (type == 0x0020) {
                port = port xor (STUN_MAGIC_COOKIE ushr 16)
                for (index in address.indices) {
                    address[index] = (address[index].toInt() xor header[4 + index].toInt()).toByte()
                }
            }
            return Pair(Inet4Address.getByAddress(address).hostAddress ?: "", port)
        }
        offset += 4 + ((length + 3) and 3.inv())
    }
    return null
}

private fun java.io.InputStream.readExactly(length: Int): ByteArray {
    val output = ByteArrayOutputStream(length)
    val buffer = ByteArray(1024)
    while (output.size() < length) {
        val read = read(buffer, 0, min(buffer.size, length - output.size()))
        if (read <= 0) {
            throw IOException("unexpected_eof")
        }
        output.write(buffer, 0, read)
    }
    return output.toByteArray()
}

private fun readUInt16(data: ByteArray, offset: Int): Int {
    return ((data[offset].toInt() and 0xff) shl 8) or (data[offset + 1].toInt() and 0xff)
}

private fun Closeable?.closeQuietly() {
    try {
        this?.close()
    } catch (_: IOException) {
    }
}

private const val CONNECT_TIMEOUT_MS = 10_000
private const val MAX_STUN_BODY_SIZE = 4096
private const val STUN_MAGIC_COOKIE = 0x2112A442.toInt()
