package com.w847.personal_toolbox

import android.Manifest
import android.app.Activity
import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothHidDevice
import android.bluetooth.BluetoothHidDeviceAppSdpSettings
import android.bluetooth.BluetoothServerSocket
import android.bluetooth.BluetoothSocket
import android.bluetooth.BluetoothProfile
import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.CallLog
import android.provider.ContactsContract
import android.provider.OpenableColumns
import android.provider.Telephony
import android.util.Base64
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject
import java.io.BufferedReader
import java.io.ByteArrayOutputStream
import java.io.Closeable
import java.io.IOException
import java.io.InputStreamReader
import java.io.OutputStreamWriter
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
    private var phoneCompanionChannel: PhoneCompanionChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        natTraversalChannel = NatTraversalChannel(flutterEngine)
        phoneCompanionChannel = PhoneCompanionChannel(this, flutterEngine)
    }

    override fun onDestroy() {
        natTraversalChannel?.dispose()
        natTraversalChannel = null
        phoneCompanionChannel?.dispose()
        phoneCompanionChannel = null
        super.onDestroy()
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        phoneCompanionChannel?.onActivityResult(requestCode, resultCode, data)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        phoneCompanionChannel?.onRequestPermissionsResult(requestCode)
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
                "probeTcpStun" -> probeTcpStun(call, result)
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

    private fun probeTcpStun(call: MethodCall, result: MethodChannel.Result) {
        val stunHost = call.argument<String>("stunHost").orEmpty()
        val stunPort = call.argument<Int>("stunPort") ?: 3478

        executor.execute {
            try {
                val probe = probeTcpStunEndpoint(stunHost, stunPort)
                postSuccess(
                    result,
                    mapOf(
                        "publicIp" to probe.first,
                        "publicPort" to probe.second,
                    ),
                )
            } catch (error: Exception) {
                postError(result, "probe_failed", error.message ?: error.toString())
            }
        }
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

private class PhoneCompanionChannel(
    private val activity: MainActivity,
    flutterEngine: FlutterEngine,
) {
    private val mainHandler = Handler(Looper.getMainLooper())
    private val executor = Executors.newCachedThreadPool()
    private var serverSocket: BluetoothServerSocket? = null
    private val serverRunning = AtomicBoolean(false)
    private val selectedFiles = mutableListOf<SessionFileItem>()
    private var pendingFilePickResult: MethodChannel.Result? = null
    private var pendingPermissionResult: MethodChannel.Result? = null
    private var pendingHidResult: MethodChannel.Result? = null
    private var hidDevice: BluetoothHidDevice? = null
    private var hidRegistered = false
    private var hidConnectedDevice: BluetoothDevice? = null
    private var hidLastStatus = "NotRegistered"
    private val channel = MethodChannel(
        flutterEngine.dartExecutor.binaryMessenger,
        "personal_toolbox/phone_companion",
    )

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "companionStatus" -> result.success(companionStatus())
                "requestPermissions" -> requestPermissions(result)
                "startCompanionServer" -> startCompanionServer(result)
                "stopCompanionServer" -> stopCompanionServer(result)
                "listContacts" -> runList(result) { listContacts() }
                "listMessages" -> runList(result) { listMessages() }
                "listCallLogs" -> runList(result) { listCallLogs() }
                "selectFiles" -> selectFiles(result)
                "listFiles" -> result.success(listFiles())
                "getDiagnostics" -> result.success(diagnostics())
                "registerHid" -> registerHid(result)
                "sendHidKey" -> sendHidKey(call, result)
                "sendHidMouse" -> sendHidMouse(call, result)
                else -> result.notImplemented()
            }
        }
    }

    fun dispose() {
        stopServer()
        unregisterHid()
        executor.shutdownNow()
        channel.setMethodCallHandler(null)
    }

    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode != PHONE_COMPANION_FILE_PICK_REQUEST) {
            return
        }
        val result = pendingFilePickResult ?: return
        pendingFilePickResult = null
        if (resultCode != Activity.RESULT_OK || data == null) {
            result.success(
                mapOf(
                    "available" to false,
                    "source" to "androidCompanion",
                    "status" to "Canceled",
                    "message" to "没有选择文件。",
                ),
            )
            return
        }
        val uris = mutableListOf<Uri>()
        data.clipData?.let { clip ->
            for (index in 0 until clip.itemCount) {
                clip.getItemAt(index)?.uri?.let { uris += it }
            }
        }
        data.data?.let { uris += it }
        selectedFiles.clear()
        selectedFiles += uris.distinct().mapIndexed { index, uri ->
            fileItemFromUri(uri, index)
        }
        result.success(
            mapOf(
                "available" to selectedFiles.isNotEmpty(),
                "source" to "androidCompanion",
                "status" to if (selectedFiles.isNotEmpty()) "Selected" else "Empty",
                "message" to if (selectedFiles.isNotEmpty()) {
                    "已选择 ${selectedFiles.size} 个会话文件。"
                } else {
                    "没有选择可读取文件。"
                },
            ),
        )
    }

    fun onRequestPermissionsResult(requestCode: Int) {
        if (requestCode != PHONE_COMPANION_PERMISSION_REQUEST) {
            return
        }
        val result = pendingPermissionResult ?: return
        pendingPermissionResult = null
        val missing = missingPermissions()
        result.success(
            mapOf(
                "available" to missing.isEmpty(),
                "source" to "androidCompanion",
                "status" to if (missing.isEmpty()) "Granted" else "MissingPermissions",
                "message" to if (missing.isEmpty()) {
                    "Android 伴随端权限已具备。"
                } else {
                    "仍缺少权限：${missing.joinToString("、")}"
                },
            ),
        )
    }

    private fun companionStatus(): Map<String, Any?> {
        val missing = missingPermissions()
        val adapter = bluetoothAdapter()
        return mapOf(
            "available" to (missing.isEmpty() && adapter != null && adapter.isEnabled),
            "source" to "androidCompanion",
            "status" to when {
                adapter == null -> "NoBluetoothAdapter"
                !adapter.isEnabled -> "BluetoothDisabled"
                missing.isNotEmpty() -> "MissingPermissions"
                serverRunning.get() -> "ServerRunning"
                else -> "Ready"
            },
            "message" to when {
                adapter == null -> "当前 Android 设备没有可用蓝牙适配器。"
                !adapter.isEnabled -> "请先开启 Android 蓝牙。"
                missing.isNotEmpty() -> "请授权附近设备、通讯录、短信和通话记录权限。"
                serverRunning.get() -> "Android 伴随服务正在运行。"
                else -> "Android 伴随端已就绪。"
            },
            "missingPermissions" to missing,
        )
    }

    private fun requestPermissions(result: MethodChannel.Result) {
        val missing = missingPermissions()
        if (missing.isNotEmpty() && Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (pendingPermissionResult != null) {
                result.success(
                    mapOf(
                        "available" to false,
                        "source" to "androidCompanion",
                        "status" to "RequestInProgress",
                        "message" to "已有 Android 权限请求正在等待系统结果。",
                    ),
                )
                return
            }
            pendingPermissionResult = result
            activity.requestPermissions(missing.toTypedArray(), PHONE_COMPANION_PERMISSION_REQUEST)
            return
        }
        val available = missing.isEmpty()
        result.success(
            mapOf(
                "available" to available,
                "source" to "androidCompanion",
                "status" to if (available) "Granted" else "Requested",
                "message" to if (available) {
                    "Android 伴随端权限已具备。"
                } else {
                    "已请求 Android 伴随端权限，请在系统弹窗中允许。"
                },
            ),
        )
    }

    @SuppressLint("MissingPermission")
    private fun startCompanionServer(result: MethodChannel.Result) {
        val missing = missingPermissions().filter {
            it == Manifest.permission.BLUETOOTH_CONNECT ||
                it == Manifest.permission.BLUETOOTH ||
                it == Manifest.permission.BLUETOOTH_ADMIN
        }
        if (missing.isNotEmpty()) {
            result.success(
                mapOf(
                    "available" to false,
                    "source" to "androidCompanion",
                    "status" to "MissingPermissions",
                    "message" to "缺少蓝牙连接权限，无法启动 RFCOMM 伴随服务。",
                ),
            )
            return
        }
        val adapter = bluetoothAdapter()
        if (adapter == null || !adapter.isEnabled) {
            result.success(
                mapOf(
                    "available" to false,
                    "source" to "androidCompanion",
                    "status" to "BluetoothDisabled",
                    "message" to "请先开启 Android 蓝牙。",
                ),
            )
            return
        }
        executor.execute {
            try {
                stopServer()
                startForegroundCompanionService()
                val socket = adapter.listenUsingRfcommWithServiceRecord(
                    "personal_toolbox_phone_companion",
                    PHONE_COMPANION_UUID,
                )
                serverSocket = socket
                serverRunning.set(true)
                thread(name = "phone-companion-rfcomm", isDaemon = true) {
                    acceptLoop(socket)
                }
                postSuccess(
                    result,
                    mapOf(
                        "available" to true,
                        "source" to "androidCompanion",
                        "status" to "ServerRunning",
                        "message" to "Android RFCOMM 伴随服务已启动。",
                    ),
                )
            } catch (error: Exception) {
                serverRunning.set(false)
                postSuccess(
                    result,
                    mapOf(
                        "available" to false,
                        "source" to "androidCompanion",
                        "status" to "StartFailed",
                        "message" to "启动 Android RFCOMM 伴随服务失败：${error.message ?: error}",
                    ),
                )
            }
        }
    }

    private fun stopCompanionServer(result: MethodChannel.Result) {
        executor.execute {
            stopServer()
            postSuccess(
                result,
                mapOf(
                    "available" to true,
                    "source" to "androidCompanion",
                    "status" to "Stopped",
                    "message" to "Android RFCOMM 伴随服务已停止。",
                ),
            )
        }
    }

    private fun startForegroundCompanionService() {
        val serviceIntent = Intent(activity, PhoneCompanionService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            activity.startForegroundService(serviceIntent)
        } else {
            activity.startService(serviceIntent)
        }
    }

    private fun registerHid(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.P) {
            result.success(
                mapOf(
                    "available" to false,
                    "source" to "androidCompanion",
                    "status" to "Unsupported",
                    "message" to "Android 9 以下系统不支持 BluetoothHidDevice。",
                ),
            )
            return
        }
        val missing = missingPermissions().filter {
            it == Manifest.permission.BLUETOOTH_CONNECT ||
                it == Manifest.permission.BLUETOOTH ||
                it == Manifest.permission.BLUETOOTH_ADMIN
        }
        if (missing.isNotEmpty()) {
            result.success(
                mapOf(
                    "available" to false,
                    "source" to "androidCompanion",
                    "status" to "MissingPermissions",
                    "message" to "缺少蓝牙连接权限，无法注册 Android HID。",
                ),
            )
            return
        }
        val adapter = bluetoothAdapter()
        if (adapter == null || !adapter.isEnabled) {
            result.success(
                mapOf(
                    "available" to false,
                    "source" to "androidCompanion",
                    "status" to "BluetoothDisabled",
                    "message" to "请先开启 Android 蓝牙。",
                ),
            )
            return
        }
        if (hidRegistered) {
            result.success(
                mapOf(
                    "available" to true,
                    "source" to "androidCompanion",
                    "status" to "Registered",
                    "message" to "Android HID 已注册。",
                ),
            )
            return
        }
        if (pendingHidResult != null) {
            result.success(
                mapOf(
                    "available" to false,
                    "source" to "androidCompanion",
                    "status" to "RequestInProgress",
                    "message" to "HID Profile 正在连接或注册中。",
                ),
            )
            return
        }
        pendingHidResult = result
        startForegroundCompanionService()
        val existing = hidDevice
        if (existing != null) {
            registerHidApp(existing)
            return
        }
        @SuppressLint("MissingPermission")
        val requested = adapter.getProfileProxy(activity, hidProfileListener, BluetoothProfile.HID_DEVICE)
        if (!requested) {
            pendingHidResult = null
            result.success(
                mapOf(
                    "available" to false,
                    "source" to "androidCompanion",
                    "status" to "ProfileUnavailable",
                    "message" to "Android 系统没有返回 HID Device Profile 代理。",
                ),
            )
        }
    }

    private fun selectFiles(result: MethodChannel.Result) {
        if (pendingFilePickResult != null) {
            result.success(
                mapOf(
                    "available" to false,
                    "source" to "androidCompanion",
                    "status" to "PickerInProgress",
                    "message" to "已有文件选择器正在等待结果。",
                ),
            )
            return
        }
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "*/*"
            putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        pendingFilePickResult = result
        try {
            activity.startActivityForResult(intent, PHONE_COMPANION_FILE_PICK_REQUEST)
        } catch (error: ActivityNotFoundException) {
            pendingFilePickResult = null
            result.success(
                mapOf(
                    "available" to false,
                    "source" to "androidCompanion",
                    "status" to "PickerUnavailable",
                    "message" to "当前 Android 系统没有可用文件选择器。",
                ),
            )
        }
    }

    private fun runList(
        result: MethodChannel.Result,
        block: () -> List<Map<String, Any?>>,
    ) {
        executor.execute {
            try {
                postSuccess(result, block())
            } catch (error: SecurityException) {
                postError(result, "permission_denied", error.message ?: error.toString())
            } catch (error: Exception) {
                postError(result, "read_failed", error.message ?: error.toString())
            }
        }
    }

    private fun stopServer() {
        serverRunning.set(false)
        serverSocket.closeQuietly()
        serverSocket = null
        activity.stopService(Intent(activity, PhoneCompanionService::class.java))
    }

    private fun acceptLoop(socket: BluetoothServerSocket) {
        while (serverRunning.get()) {
            try {
                val client = socket.accept()
                thread(name = "phone-companion-client", isDaemon = true) {
                    handleClient(client)
                }
            } catch (_: IOException) {
                if (serverRunning.get()) {
                    stopServer()
                }
                break
            }
        }
    }

    private fun handleClient(socket: BluetoothSocket) {
        socket.use { client ->
            val reader = BufferedReader(InputStreamReader(client.inputStream, Charsets.UTF_8))
            val writer = OutputStreamWriter(client.outputStream, Charsets.UTF_8)
            while (serverRunning.get()) {
                val line = reader.readLine() ?: break
                val request = runCatching { JSONObject(line) }.getOrNull()
                val command = request?.optString("command").orEmpty()
                val response = try {
                    when (command) {
                        "status" -> JSONObject(companionStatus())
                        "contacts" -> JSONObject().put("items", JSONArray(listContacts()))
                        "messages" -> JSONObject().put("items", JSONArray(listMessages()))
                        "callLogs" -> JSONObject().put("items", JSONArray(listCallLogs()))
                        "files" -> JSONObject().put("items", JSONArray(listFiles()))
                        "fileContent" -> JSONObject(fileContent(request?.optString("id").orEmpty()))
                        else -> JSONObject()
                            .put("available", false)
                            .put("source", "androidCompanion")
                            .put("status", "UnknownCommand")
                            .put("message", "未知 Android 伴随端命令：$command")
                    }
                } catch (error: SecurityException) {
                    JSONObject()
                        .put("available", false)
                        .put("source", "androidCompanion")
                        .put("status", "PermissionDenied")
                        .put("message", error.message ?: error.toString())
                } catch (error: Exception) {
                    JSONObject()
                        .put("available", false)
                        .put("source", "androidCompanion")
                        .put("status", "Failed")
                        .put("message", error.message ?: error.toString())
                }
                writer.write(response.toString())
                writer.write("\n")
                writer.flush()
            }
        }
    }

    private fun listFiles(): List<Map<String, Any?>> {
        return selectedFiles.map { it.toMap() }
    }

    private fun fileContent(id: String): Map<String, Any?> {
        val item = selectedFiles.firstOrNull { it.id == id }
            ?: return mapOf(
                "available" to false,
                "source" to "androidCompanion",
                "status" to "NotFound",
                "message" to "会话文件不存在或已被清空。",
            )
        if (item.size > MAX_FILE_TRANSFER_BYTES) {
            return mapOf(
                "available" to false,
                "source" to "androidCompanion",
                "status" to "TooLarge",
                "message" to "当前仅允许通过伴随通道读取 ${MAX_FILE_TRANSFER_BYTES / 1024 / 1024} MB 以内的小文件。",
            )
        }
        val bytes = activity.contentResolver.openInputStream(item.uri)?.use { input ->
            readLimitedBytes(input, MAX_FILE_TRANSFER_BYTES)
        } ?: ByteArray(0)
        return mapOf(
            "available" to true,
            "source" to "androidCompanion",
            "status" to "Success",
            "message" to "已读取会话文件内容。",
            "id" to item.id,
            "name" to item.name,
            "size" to bytes.size,
            "mimeType" to item.mimeType,
            "base64" to Base64.encodeToString(bytes, Base64.NO_WRAP),
        )
    }

    private fun listContacts(): List<Map<String, Any?>> {
        requirePermission(Manifest.permission.READ_CONTACTS)
        val contacts = mutableListOf<Map<String, Any?>>()
        val projection = arrayOf(
            ContactsContract.Contacts._ID,
            ContactsContract.Contacts.DISPLAY_NAME_PRIMARY,
            ContactsContract.Contacts.HAS_PHONE_NUMBER,
        )
        activity.contentResolver.query(
            ContactsContract.Contacts.CONTENT_URI,
            projection,
            null,
            null,
            ContactsContract.Contacts.DISPLAY_NAME_PRIMARY + " COLLATE LOCALIZED ASC",
        )?.use { cursor ->
            val idIndex = cursor.getColumnIndexOrThrow(ContactsContract.Contacts._ID)
            val nameIndex = cursor.getColumnIndexOrThrow(ContactsContract.Contacts.DISPLAY_NAME_PRIMARY)
            val hasPhoneIndex = cursor.getColumnIndexOrThrow(ContactsContract.Contacts.HAS_PHONE_NUMBER)
            while (cursor.moveToNext() && contacts.size < SESSION_DATA_LIMIT) {
                val id = cursor.getString(idIndex)
                val phones = if (cursor.getInt(hasPhoneIndex) > 0) contactPhones(id) else emptyList()
                contacts.add(
                    mapOf(
                        "id" to id,
                        "name" to (cursor.getString(nameIndex) ?: "未命名联系人"),
                        "phones" to phones,
                        "emails" to contactEmails(id),
                        "source" to "androidCompanion",
                    ),
                )
            }
        }
        return contacts
    }

    private fun contactPhones(contactId: String): List<String> {
        val phones = mutableListOf<String>()
        activity.contentResolver.query(
            ContactsContract.CommonDataKinds.Phone.CONTENT_URI,
            arrayOf(ContactsContract.CommonDataKinds.Phone.NUMBER),
            ContactsContract.CommonDataKinds.Phone.CONTACT_ID + "=?",
            arrayOf(contactId),
            null,
        )?.use { cursor ->
            val numberIndex = cursor.getColumnIndexOrThrow(ContactsContract.CommonDataKinds.Phone.NUMBER)
            while (cursor.moveToNext()) {
                cursor.getString(numberIndex)?.let { phones.add(it) }
            }
        }
        return phones
    }

    private fun contactEmails(contactId: String): List<String> {
        val emails = mutableListOf<String>()
        activity.contentResolver.query(
            ContactsContract.CommonDataKinds.Email.CONTENT_URI,
            arrayOf(ContactsContract.CommonDataKinds.Email.ADDRESS),
            ContactsContract.CommonDataKinds.Email.CONTACT_ID + "=?",
            arrayOf(contactId),
            null,
        )?.use { cursor ->
            val addressIndex = cursor.getColumnIndexOrThrow(ContactsContract.CommonDataKinds.Email.ADDRESS)
            while (cursor.moveToNext()) {
                cursor.getString(addressIndex)?.let { emails.add(it) }
            }
        }
        return emails
    }

    private fun listMessages(): List<Map<String, Any?>> {
        requirePermission(Manifest.permission.READ_SMS)
        val messages = mutableListOf<Map<String, Any?>>()
        val projection = arrayOf(
            Telephony.Sms._ID,
            Telephony.Sms.ADDRESS,
            Telephony.Sms.BODY,
            Telephony.Sms.DATE,
            Telephony.Sms.TYPE,
        )
        activity.contentResolver.query(
            Telephony.Sms.CONTENT_URI,
            projection,
            null,
            null,
            Telephony.Sms.DATE + " DESC",
        )?.use { cursor ->
            val idIndex = cursor.getColumnIndexOrThrow(Telephony.Sms._ID)
            val addressIndex = cursor.getColumnIndexOrThrow(Telephony.Sms.ADDRESS)
            val bodyIndex = cursor.getColumnIndexOrThrow(Telephony.Sms.BODY)
            val dateIndex = cursor.getColumnIndexOrThrow(Telephony.Sms.DATE)
            val typeIndex = cursor.getColumnIndexOrThrow(Telephony.Sms.TYPE)
            while (cursor.moveToNext() && messages.size < SESSION_DATA_LIMIT) {
                messages.add(
                    mapOf(
                        "id" to cursor.getString(idIndex),
                        "address" to (cursor.getString(addressIndex) ?: ""),
                        "body" to (cursor.getString(bodyIndex) ?: ""),
                        "timestampMs" to cursor.getLong(dateIndex),
                        "type" to smsTypeName(cursor.getInt(typeIndex)),
                        "source" to "androidCompanion",
                    ),
                )
            }
        }
        return messages
    }

    private fun listCallLogs(): List<Map<String, Any?>> {
        requirePermission(Manifest.permission.READ_CALL_LOG)
        val logs = mutableListOf<Map<String, Any?>>()
        val projection = arrayOf(
            CallLog.Calls._ID,
            CallLog.Calls.CACHED_NAME,
            CallLog.Calls.NUMBER,
            CallLog.Calls.DATE,
            CallLog.Calls.DURATION,
            CallLog.Calls.TYPE,
        )
        activity.contentResolver.query(
            CallLog.Calls.CONTENT_URI,
            projection,
            null,
            null,
            CallLog.Calls.DATE + " DESC",
        )?.use { cursor ->
            val idIndex = cursor.getColumnIndexOrThrow(CallLog.Calls._ID)
            val nameIndex = cursor.getColumnIndexOrThrow(CallLog.Calls.CACHED_NAME)
            val numberIndex = cursor.getColumnIndexOrThrow(CallLog.Calls.NUMBER)
            val dateIndex = cursor.getColumnIndexOrThrow(CallLog.Calls.DATE)
            val durationIndex = cursor.getColumnIndexOrThrow(CallLog.Calls.DURATION)
            val typeIndex = cursor.getColumnIndexOrThrow(CallLog.Calls.TYPE)
            while (cursor.moveToNext() && logs.size < SESSION_DATA_LIMIT) {
                logs.add(
                    mapOf(
                        "id" to cursor.getString(idIndex),
                        "name" to (cursor.getString(nameIndex) ?: ""),
                        "number" to (cursor.getString(numberIndex) ?: ""),
                        "timestampMs" to cursor.getLong(dateIndex),
                        "durationSeconds" to cursor.getLong(durationIndex),
                        "type" to callTypeName(cursor.getInt(typeIndex)),
                        "source" to "androidCompanion",
                    ),
                )
            }
        }
        return logs
    }

    @SuppressLint("MissingPermission")
    private fun registerHidApp(proxy: BluetoothHidDevice) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.P) {
            pendingHidResult?.let { result ->
                postSuccess(
                    result,
                    mapOf(
                        "available" to false,
                        "source" to "androidCompanion",
                        "status" to "Unsupported",
                        "message" to "Android 9 以下系统不支持 BluetoothHidDevice。",
                    ),
                )
            }
            pendingHidResult = null
            return
        }
        val settings = BluetoothHidDeviceAppSdpSettings(
            "Personal Toolbox Input",
            "Windows 手机管理远程输入",
            "w847",
            BluetoothHidDevice.SUBCLASS1_COMBO,
            HID_REPORT_DESCRIPTOR,
        )
        val requested = proxy.registerApp(settings, null, null, executor, hidCallback)
        val result = pendingHidResult
        pendingHidResult = null
        result?.let {
            postSuccess(
                it,
                mapOf(
                    "available" to requested,
                    "source" to "androidCompanion",
                    "status" to if (requested) "RegisterRequested" else "RegisterRejected",
                    "message" to if (requested) {
                        "已向 Android 蓝牙栈提交 HID 注册请求，最终状态以诊断页回调为准。"
                    } else {
                        "Android 蓝牙栈拒绝提交 HID 注册请求。"
                    },
                ),
            )
        }
    }

    private val hidProfileListener = object : BluetoothProfile.ServiceListener {
        override fun onServiceConnected(profile: Int, proxy: BluetoothProfile?) {
            if (profile != BluetoothProfile.HID_DEVICE || proxy !is BluetoothHidDevice) {
                return
            }
            hidDevice = proxy
            hidLastStatus = "ProfileConnected"
            registerHidApp(proxy)
        }

        override fun onServiceDisconnected(profile: Int) {
            if (profile == BluetoothProfile.HID_DEVICE) {
                hidDevice = null
                hidRegistered = false
                hidConnectedDevice = null
                hidLastStatus = "ProfileDisconnected"
            }
        }
    }

    private val hidCallback = object : BluetoothHidDevice.Callback() {
        override fun onAppStatusChanged(pluggedDevice: BluetoothDevice?, registered: Boolean) {
            hidRegistered = registered
            hidConnectedDevice = pluggedDevice
            hidLastStatus = if (registered) "Registered" else "Unregistered"
        }

        override fun onConnectionStateChanged(device: BluetoothDevice?, state: Int) {
            hidConnectedDevice = if (state == BluetoothProfile.STATE_CONNECTED) device else null
            hidLastStatus = when (state) {
                BluetoothProfile.STATE_CONNECTED -> "HostConnected"
                BluetoothProfile.STATE_CONNECTING -> "HostConnecting"
                BluetoothProfile.STATE_DISCONNECTING -> "HostDisconnecting"
                BluetoothProfile.STATE_DISCONNECTED -> "HostDisconnected"
                else -> "HostStateUnknown"
            }
        }

        override fun onGetReport(device: BluetoothDevice?, type: Byte, id: Byte, bufferSize: Int) {
            if (device != null) {
                hidDevice?.replyReport(device, type, id, ByteArray(0))
            }
        }

        override fun onSetReport(device: BluetoothDevice?, type: Byte, id: Byte, data: ByteArray?) {
            if (device != null) {
                hidDevice?.reportError(device, BluetoothHidDevice.ERROR_RSP_SUCCESS)
            }
        }
    }

    private fun sendHidKey(call: MethodCall, result: MethodChannel.Result) {
        val key = call.argument<String>("key").orEmpty()
        val usage = hidUsageForKey(key)
        if (usage == null) {
            result.success(
                mapOf(
                    "available" to false,
                    "source" to "androidCompanion",
                    "status" to "UnsupportedKey",
                    "message" to "暂不支持该 HID 按键：$key",
                ),
            )
            return
        }
        sendHidReports(
            result,
            byteArrayOf(0x00, 0x00, usage.toByte(), 0x00, 0x00, 0x00, 0x00, 0x00),
            byteArrayOf(0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00),
            "已发送 HID 按键：$key",
        )
    }

    private fun sendHidMouse(call: MethodCall, result: MethodChannel.Result) {
        val dx = (call.argument<Int>("dx") ?: 0).coerceIn(-127, 127)
        val dy = (call.argument<Int>("dy") ?: 0).coerceIn(-127, 127)
        val wheel = (call.argument<Int>("wheel") ?: 0).coerceIn(-127, 127)
        val buttons = (call.argument<Int>("buttons") ?: 0).coerceIn(0, 7)
        sendHidReports(
            result,
            byteArrayOf(buttons.toByte(), dx.toByte(), dy.toByte(), wheel.toByte()),
            byteArrayOf(0x00, 0x00, 0x00, 0x00),
            "已发送 HID 鼠标报告。",
            reportId = 2,
        )
    }

    @SuppressLint("MissingPermission")
    private fun sendHidReports(
        result: MethodChannel.Result,
        down: ByteArray,
        up: ByteArray,
        successMessage: String,
        reportId: Int = 1,
    ) {
        val proxy = hidDevice
        val device = hidConnectedDevice
        if (!hidRegistered || proxy == null || device == null) {
            result.success(
                mapOf(
                    "available" to false,
                    "source" to "androidCompanion",
                    "status" to "NoHidHost",
                    "message" to "HID 尚未注册或还没有连接到 Windows HID 主机。",
                ),
            )
            return
        }
        val downOk = proxy.sendReport(device, reportId, down)
        val upOk = proxy.sendReport(device, reportId, up)
        result.success(
            mapOf(
                "available" to (downOk && upOk),
                "source" to "androidCompanion",
                "status" to if (downOk && upOk) "Success" else "Rejected",
                "message" to if (downOk && upOk) successMessage else "Android 蓝牙栈拒绝发送 HID 报告。",
            ),
        )
    }

    private fun unregisterHid() {
        val proxy = hidDevice
        if (proxy != null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            try {
                proxy.unregisterApp()
                bluetoothAdapter()?.closeProfileProxy(BluetoothProfile.HID_DEVICE, proxy)
            } catch (_: Exception) {
            }
        }
        hidDevice = null
        hidRegistered = false
        hidConnectedDevice = null
        hidLastStatus = "Unregistered"
    }

    private fun diagnostics(): List<Map<String, Any?>> {
        val missing = missingPermissions()
        return listOf(
            mapOf(
                "area" to "Android 权限",
                "status" to if (missing.isEmpty()) "Granted" else "MissingPermissions",
                "message" to if (missing.isEmpty()) {
                    "附近设备、通讯录、短信和通话记录权限已具备。"
                } else {
                    "缺少权限：${missing.joinToString("、")}"
                },
                "severity" to if (missing.isEmpty()) "info" else "warning",
            ),
            mapOf(
                "area" to "RFCOMM 伴随服务",
                "status" to if (serverRunning.get()) "ServerRunning" else "Stopped",
                "message" to "服务 UUID：$PHONE_COMPANION_SERVICE_UUID",
                "severity" to "info",
            ),
            mapOf(
                "area" to "HID",
                "status" to when {
                    Build.VERSION.SDK_INT < Build.VERSION_CODES.P -> "Unsupported"
                    hidRegistered && hidConnectedDevice != null -> "HostConnected"
                    hidRegistered -> "Registered"
                    else -> hidLastStatus
                },
                "message" to when {
                    Build.VERSION.SDK_INT < Build.VERSION_CODES.P -> "Android 9 以下系统不支持 BluetoothHidDevice。"
                    hidRegistered && hidConnectedDevice != null -> "Android HID 已连接 Windows HID 主机。"
                    hidRegistered -> "Android HID 已注册，等待 Windows 主机连接。"
                    else -> "HID Device Profile 由 Android 系统和厂商蓝牙栈决定是否允许注册。"
                },
                "severity" to if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) "info" else "warning",
            ),
            mapOf(
                "area" to "文件选择",
                "status" to if (selectedFiles.isEmpty()) "Empty" else "Selected",
                "message" to if (selectedFiles.isEmpty()) {
                    "当前会话还没有用户选择的文件。"
                } else {
                    "当前会话已选择 ${selectedFiles.size} 个文件；文件 URI 只保存在内存中。"
                },
                "severity" to "info",
            ),
            mapOf(
                "area" to "会话缓存",
                "status" to "MemoryOnly",
                "message" to "联系人、短信、通话记录和文件列表只在当前会话返回给界面，不写入本地数据库。",
                "severity" to "info",
            ),
        )
    }

    private fun missingPermissions(): List<String> {
        val permissions = mutableListOf<String>()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            permissions += Manifest.permission.BLUETOOTH_CONNECT
            permissions += Manifest.permission.BLUETOOTH_SCAN
            permissions += Manifest.permission.BLUETOOTH_ADVERTISE
        } else {
            permissions += Manifest.permission.BLUETOOTH
            permissions += Manifest.permission.BLUETOOTH_ADMIN
        }
        permissions += Manifest.permission.READ_CONTACTS
        permissions += Manifest.permission.READ_SMS
        permissions += Manifest.permission.READ_CALL_LOG
        permissions += Manifest.permission.READ_PHONE_STATE
        return permissions.filter { !hasPermission(it) }
    }

    private fun requirePermission(permission: String) {
        if (!hasPermission(permission)) {
            throw SecurityException("missing_permission:$permission")
        }
    }

    private fun hasPermission(permission: String): Boolean {
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.M ||
            activity.checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED
    }

    private fun bluetoothAdapter(): BluetoothAdapter? {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val manager = activity.getSystemService(Context.BLUETOOTH_SERVICE) as? android.bluetooth.BluetoothManager
            manager?.adapter
        } else {
            @Suppress("DEPRECATION")
            BluetoothAdapter.getDefaultAdapter()
        }
    }

    private fun fileItemFromUri(uri: Uri, index: Int): SessionFileItem {
        var name = uri.lastPathSegment ?: "会话文件-$index"
        var size = -1L
        val mimeType = activity.contentResolver.getType(uri) ?: "application/octet-stream"
        activity.contentResolver.query(
            uri,
            arrayOf(OpenableColumns.DISPLAY_NAME, OpenableColumns.SIZE),
            null,
            null,
            null,
        )?.use { cursor ->
            if (cursor.moveToFirst()) {
                val nameIndex = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                val sizeIndex = cursor.getColumnIndex(OpenableColumns.SIZE)
                if (nameIndex >= 0) {
                    name = cursor.getString(nameIndex) ?: name
                }
                if (sizeIndex >= 0 && !cursor.isNull(sizeIndex)) {
                    size = cursor.getLong(sizeIndex)
                }
            }
        }
        return SessionFileItem(
            id = "file-$index-${System.nanoTime()}",
            uri = uri,
            name = name,
            size = size.coerceAtLeast(0),
            mimeType = mimeType,
        )
    }

    private fun postSuccess(result: MethodChannel.Result, value: Any?) {
        mainHandler.post { result.success(value) }
    }

    private fun postError(result: MethodChannel.Result, code: String, message: String) {
        mainHandler.post { result.error(code, message, null) }
    }
}

private data class SessionFileItem(
    val id: String,
    val uri: Uri,
    val name: String,
    val size: Long,
    val mimeType: String,
) {
    fun toMap(): Map<String, Any?> {
        return mapOf(
            "id" to id,
            "name" to name,
            "size" to size,
            "mimeType" to mimeType,
            "source" to "androidCompanion",
        )
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

private fun probeTcpStunEndpoint(stunHost: String, stunPort: Int): Pair<String, Int> {
    createReusableSocket().use { socket ->
        socket.connect(InetSocketAddress(stunHost, stunPort), CONNECT_TIMEOUT_MS)
        socket.tcpNoDelay = true
        socket.soTimeout = CONNECT_TIMEOUT_MS
        return performTcpStun(socket)
    }
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

private fun createReusableSocket(): Socket {
    val socket = Socket()
    socket.reuseAddress = true
    socket.keepAlive = true
    return socket
}

private fun smsTypeName(type: Int): String {
    return when (type) {
        Telephony.Sms.MESSAGE_TYPE_INBOX -> "inbox"
        Telephony.Sms.MESSAGE_TYPE_SENT -> "sent"
        Telephony.Sms.MESSAGE_TYPE_DRAFT -> "draft"
        Telephony.Sms.MESSAGE_TYPE_OUTBOX -> "outbox"
        Telephony.Sms.MESSAGE_TYPE_FAILED -> "failed"
        Telephony.Sms.MESSAGE_TYPE_QUEUED -> "queued"
        else -> "unknown"
    }
}

private fun callTypeName(type: Int): String {
    return when (type) {
        CallLog.Calls.INCOMING_TYPE -> "incoming"
        CallLog.Calls.OUTGOING_TYPE -> "outgoing"
        CallLog.Calls.MISSED_TYPE -> "missed"
        CallLog.Calls.REJECTED_TYPE -> "rejected"
        CallLog.Calls.BLOCKED_TYPE -> "blocked"
        CallLog.Calls.VOICEMAIL_TYPE -> "voicemail"
        else -> "unknown"
    }
}

private fun readLimitedBytes(input: java.io.InputStream, maxBytes: Long): ByteArray {
    val output = ByteArrayOutputStream()
    val buffer = ByteArray(64 * 1024)
    var total = 0L
    while (true) {
        val read = input.read(buffer)
        if (read <= 0) {
            break
        }
        total += read
        if (total > maxBytes) {
            throw IOException("file_too_large")
        }
        output.write(buffer, 0, read)
    }
    return output.toByteArray()
}

private fun hidUsageForKey(key: String): Int? {
    return when (key.lowercase()) {
        "enter" -> 0x28
        "escape" -> 0x29
        "backspace" -> 0x2a
        "tab" -> 0x2b
        "space" -> 0x2c
        "right" -> 0x4f
        "left" -> 0x50
        "down" -> 0x51
        "up" -> 0x52
        else -> null
    }
}

private fun Closeable?.closeQuietly() {
    try {
        this?.close()
    } catch (_: IOException) {
    }
}

private const val PHONE_COMPANION_SERVICE_UUID = "7b01f6f2-64d8-42e0-9b52-2f6cb11c7d34"
private val PHONE_COMPANION_UUID: UUID = UUID.fromString(PHONE_COMPANION_SERVICE_UUID)
private const val PHONE_COMPANION_PERMISSION_REQUEST = 8047
private const val PHONE_COMPANION_FILE_PICK_REQUEST = 8048
private const val SESSION_DATA_LIMIT = 200
private const val MAX_FILE_TRANSFER_BYTES = 8L * 1024L * 1024L
private const val CONNECT_TIMEOUT_MS = 10_000
private const val MAX_STUN_BODY_SIZE = 4096
private const val STUN_MAGIC_COOKIE = 0x2112A442.toInt()

private val HID_REPORT_DESCRIPTOR = byteArrayOf(
    0x05, 0x01, // Generic Desktop
    0x09, 0x06, // Keyboard
    0xa1.toByte(), 0x01, // Application
    0x85.toByte(), 0x01, // Report ID 1
    0x05, 0x07, // Keyboard/Keypad
    0x19, 0xe0.toByte(),
    0x29, 0xe7.toByte(),
    0x15, 0x00,
    0x25, 0x01,
    0x75, 0x01,
    0x95.toByte(), 0x08,
    0x81.toByte(), 0x02, // Modifier bits
    0x95.toByte(), 0x01,
    0x75, 0x08,
    0x81.toByte(), 0x01, // Reserved
    0x95.toByte(), 0x06,
    0x75, 0x08,
    0x15, 0x00,
    0x25, 0x65,
    0x05, 0x07,
    0x19, 0x00,
    0x29, 0x65,
    0x81.toByte(), 0x00, // Key array
    0xc0.toByte(),
    0x05, 0x01, // Generic Desktop
    0x09, 0x02, // Mouse
    0xa1.toByte(), 0x01,
    0x85.toByte(), 0x02, // Report ID 2
    0x09, 0x01, // Pointer
    0xa1.toByte(), 0x00,
    0x05, 0x09, // Buttons
    0x19, 0x01,
    0x29, 0x03,
    0x15, 0x00,
    0x25, 0x01,
    0x95.toByte(), 0x03,
    0x75, 0x01,
    0x81.toByte(), 0x02,
    0x95.toByte(), 0x01,
    0x75, 0x05,
    0x81.toByte(), 0x01,
    0x05, 0x01,
    0x09, 0x30, // X
    0x09, 0x31, // Y
    0x09, 0x38, // Wheel
    0x15, 0x81.toByte(),
    0x25, 0x7f,
    0x75, 0x08,
    0x95.toByte(), 0x03,
    0x81.toByte(), 0x06,
    0xc0.toByte(),
    0xc0.toByte(),
)
