#include "phone_manager_channel.h"

#include <windows.h>
#include <shellapi.h>

#include <flutter/method_result_functions.h>
#include <flutter/standard_method_codec.h>

#include <Audioclient.h>
#include <appmodel.h>
#include <endpointvolume.h>
#include <mmdeviceapi.h>
#include <propidl.h>
#include <propkeydef.h>
#include <propsys.h>
#include <Functiondiscoverykeys_devpkey.h>
#include <winrt/Windows.Devices.Bluetooth.h>
#include <winrt/Windows.Devices.Bluetooth.Rfcomm.h>
#include <winrt/Windows.Devices.Enumeration.h>
#include <winrt/Windows.Foundation.h>
#include <winrt/Windows.Foundation.Collections.h>
#include <winrt/Windows.Foundation.Metadata.h>
#include <winrt/Windows.Media.Audio.h>
#include <winrt/Windows.Media.Control.h>
#include <winrt/Windows.Networking.Sockets.h>
#include <winrt/Windows.Storage.Streams.h>
#include <winrt/base.h>

#include <atomic>
#include <chrono>
#include <cstdio>
#include <map>
#include <memory>
#include <mutex>
#include <string>
#include <thread>
#include <vector>

namespace {

namespace audio = winrt::Windows::Media::Audio;
namespace bluetooth = winrt::Windows::Devices::Bluetooth;
namespace control = winrt::Windows::Media::Control;
namespace devices = winrt::Windows::Devices::Enumeration;
namespace foundation = winrt::Windows::Foundation;
namespace metadata = winrt::Windows::Foundation::Metadata;
namespace rfcomm = winrt::Windows::Devices::Bluetooth::Rfcomm;
namespace sockets = winrt::Windows::Networking::Sockets;
namespace streams = winrt::Windows::Storage::Streams;

constexpr winrt::guid kPhoneCompanionServiceGuid{
    0x7b01f6f2,
    0x64d8,
    0x42e0,
    {0x9b, 0x52, 0x2f, 0x6c, 0xb1, 0x1c, 0x7d, 0x34}};
constexpr uint32_t kCompanionResponseLimit = 12 * 1024 * 1024;

std::string WideToUtf8(const std::wstring& value) {
  if (value.empty()) {
    return "";
  }
  const int size = ::WideCharToMultiByte(CP_UTF8, 0, value.data(),
                                         static_cast<int>(value.size()), nullptr,
                                         0, nullptr, nullptr);
  std::string result(size, '\0');
  ::WideCharToMultiByte(CP_UTF8, 0, value.data(),
                        static_cast<int>(value.size()), result.data(), size,
                        nullptr, nullptr);
  return result;
}

std::wstring Utf8ToWide(const std::string& value) {
  if (value.empty()) {
    return L"";
  }
  const int size =
      ::MultiByteToWideChar(CP_UTF8, 0, value.data(),
                            static_cast<int>(value.size()), nullptr, 0);
  std::wstring result(size, L'\0');
  ::MultiByteToWideChar(CP_UTF8, 0, value.data(),
                        static_cast<int>(value.size()), result.data(), size);
  return result;
}

std::string HStringToUtf8(const winrt::hstring& value) {
  return WideToUtf8(std::wstring(value.c_str(), value.size()));
}

std::string GetStringArg(const flutter::EncodableMap& args,
                         const char* name) {
  const auto it = args.find(flutter::EncodableValue(name));
  if (it == args.end()) {
    return "";
  }
  if (const auto* value = std::get_if<std::string>(&it->second)) {
    return *value;
  }
  return "";
}

double GetDoubleArg(const flutter::EncodableMap& args,
                    const char* name,
                    double fallback) {
  const auto it = args.find(flutter::EncodableValue(name));
  if (it == args.end()) {
    return fallback;
  }
  if (const auto* value = std::get_if<double>(&it->second)) {
    return *value;
  }
  if (const auto* value = std::get_if<int32_t>(&it->second)) {
    return static_cast<double>(*value);
  }
  if (const auto* value = std::get_if<int64_t>(&it->second)) {
    return static_cast<double>(*value);
  }
  return fallback;
}

bool GetBoolArg(const flutter::EncodableMap& args,
                const char* name,
                bool fallback) {
  const auto it = args.find(flutter::EncodableValue(name));
  if (it == args.end()) {
    return fallback;
  }
  if (const auto* value = std::get_if<bool>(&it->second)) {
    return *value;
  }
  return fallback;
}

std::string HResultMessage(HRESULT hr) {
  char buffer[32];
  snprintf(buffer, sizeof(buffer), "0x%08X", static_cast<unsigned int>(hr));
  return std::string(buffer);
}

flutter::EncodableMap StatusMap(bool available,
                                const std::string& source,
                                const std::string& status,
                                const std::string& message) {
  flutter::EncodableMap value;
  value[flutter::EncodableValue("available")] =
      flutter::EncodableValue(available);
  value[flutter::EncodableValue("source")] = flutter::EncodableValue(source);
  value[flutter::EncodableValue("status")] = flutter::EncodableValue(status);
  value[flutter::EncodableValue("message")] = flutter::EncodableValue(message);
  return value;
}

flutter::EncodableMap CapabilityMap(const std::string& id,
                                    const std::string& label,
                                    bool available,
                                    const std::string& source,
                                    const std::string& status,
                                    const std::string& message) {
  auto value = StatusMap(available, source, status, message);
  value[flutter::EncodableValue("id")] = flutter::EncodableValue(id);
  value[flutter::EncodableValue("label")] = flutter::EncodableValue(label);
  return value;
}

flutter::EncodableMap DiagnosticMap(const std::string& area,
                                    const std::string& status,
                                    const std::string& message,
                                    const std::string& severity = "info") {
  flutter::EncodableMap value;
  value[flutter::EncodableValue("area")] = flutter::EncodableValue(area);
  value[flutter::EncodableValue("status")] = flutter::EncodableValue(status);
  value[flutter::EncodableValue("message")] = flutter::EncodableValue(message);
  value[flutter::EncodableValue("severity")] = flutter::EncodableValue(severity);
  return value;
}

std::string StateName(audio::AudioPlaybackConnectionState state) {
  switch (state) {
    case audio::AudioPlaybackConnectionState::Opened:
      return "AudioOpened";
    case audio::AudioPlaybackConnectionState::Closed:
      return "Disconnected";
  }
  return "Unknown";
}

std::string OpenStatusName(audio::AudioPlaybackConnectionOpenResultStatus status) {
  switch (status) {
    case audio::AudioPlaybackConnectionOpenResultStatus::Success:
      return "Success";
    case audio::AudioPlaybackConnectionOpenResultStatus::RequestTimedOut:
      return "RequestTimedOut";
    case audio::AudioPlaybackConnectionOpenResultStatus::DeniedBySystem:
      return "DeniedBySystem";
    case audio::AudioPlaybackConnectionOpenResultStatus::UnknownFailure:
      return "UnknownFailure";
  }
  return "Unknown";
}

std::string PlaybackStatusName(
    control::GlobalSystemMediaTransportControlsSessionPlaybackStatus status) {
  switch (status) {
    case control::GlobalSystemMediaTransportControlsSessionPlaybackStatus::
        Closed:
      return "Closed";
    case control::GlobalSystemMediaTransportControlsSessionPlaybackStatus::
        Opened:
      return "Opened";
    case control::GlobalSystemMediaTransportControlsSessionPlaybackStatus::
        Changing:
      return "Changing";
    case control::GlobalSystemMediaTransportControlsSessionPlaybackStatus::
        Stopped:
      return "Stopped";
    case control::GlobalSystemMediaTransportControlsSessionPlaybackStatus::
        Playing:
      return "Playing";
    case control::GlobalSystemMediaTransportControlsSessionPlaybackStatus::
        Paused:
      return "Paused";
  }
  return "Unknown";
}

bool IsPackagedProcess() {
  UINT32 length = 0;
  const LONG result = GetCurrentPackageFullName(&length, nullptr);
  return result != APPMODEL_ERROR_NO_PACKAGE;
}

std::wstring DeviceFriendlyName(IMMDevice* device) {
  IPropertyStore* store = nullptr;
  if (FAILED(device->OpenPropertyStore(STGM_READ, &store)) || store == nullptr) {
    return L"";
  }
  PROPVARIANT value;
  PropVariantInit(&value);
  std::wstring name;
  if (SUCCEEDED(store->GetValue(PKEY_Device_FriendlyName, &value)) &&
      value.vt == VT_LPWSTR && value.pwszVal != nullptr) {
    name = value.pwszVal;
  }
  PropVariantClear(&value);
  store->Release();
  return name;
}

IMMDeviceEnumerator* CreateDeviceEnumerator() {
  IMMDeviceEnumerator* enumerator = nullptr;
  const HRESULT hr = CoCreateInstance(__uuidof(MMDeviceEnumerator), nullptr,
                                      CLSCTX_ALL,
                                      IID_PPV_ARGS(&enumerator));
  if (FAILED(hr)) {
    return nullptr;
  }
  return enumerator;
}

struct EndpointVolumeSnapshot {
  bool available = false;
  std::string status = "Unavailable";
  std::string message = "没有读取到 Windows 输出端点。";
  std::string endpoint_name;
  float volume = 0.0f;
  bool muted = false;
};

EndpointVolumeSnapshot ReadEndpointVolume() {
  EndpointVolumeSnapshot snapshot;
  winrt::init_apartment(winrt::apartment_type::multi_threaded);
  IMMDeviceEnumerator* enumerator = CreateDeviceEnumerator();
  if (enumerator == nullptr) {
    snapshot.message = "无法创建 Windows 音频端点枚举器。";
    return snapshot;
  }

  IMMDevice* device = nullptr;
  const HRESULT device_hr =
      enumerator->GetDefaultAudioEndpoint(eRender, eMultimedia, &device);
  enumerator->Release();
  if (FAILED(device_hr) || device == nullptr) {
    snapshot.status = HResultMessage(device_hr);
    snapshot.message = "无法读取 Windows 默认播放设备。";
    return snapshot;
  }

  snapshot.endpoint_name = WideToUtf8(DeviceFriendlyName(device));
  IAudioEndpointVolume* endpoint = nullptr;
  const HRESULT activate_hr = device->Activate(
      __uuidof(IAudioEndpointVolume), CLSCTX_ALL, nullptr,
      reinterpret_cast<void**>(&endpoint));
  if (FAILED(activate_hr) || endpoint == nullptr) {
    device->Release();
    snapshot.status = HResultMessage(activate_hr);
    snapshot.message = "无法打开 Windows 输出音量控制接口。";
    return snapshot;
  }

  float volume = 0.0f;
  BOOL muted = FALSE;
  endpoint->GetMasterVolumeLevelScalar(&volume);
  endpoint->GetMute(&muted);
  endpoint->Release();
  device->Release();

  if (volume < 0.0f) {
    volume = 0.0f;
  }
  if (volume > 1.0f) {
    volume = 1.0f;
  }
  snapshot.available = true;
  snapshot.status = "Success";
  snapshot.message = "已读取 Windows 输出音量。";
  snapshot.volume = volume;
  snapshot.muted = muted != FALSE;
  return snapshot;
}

flutter::EncodableMap SetEndpointVolume(float volume) {
  winrt::init_apartment(winrt::apartment_type::multi_threaded);
  if (volume < 0.0f) {
    volume = 0.0f;
  }
  if (volume > 1.0f) {
    volume = 1.0f;
  }
  IMMDeviceEnumerator* enumerator = CreateDeviceEnumerator();
  if (enumerator == nullptr) {
    return StatusMap(false, "windowsProfile", "Unavailable",
                     "无法创建 Windows 音频端点枚举器。");
  }
  IMMDevice* device = nullptr;
  HRESULT hr = enumerator->GetDefaultAudioEndpoint(eRender, eMultimedia, &device);
  enumerator->Release();
  if (FAILED(hr) || device == nullptr) {
    return StatusMap(false, "windowsProfile", HResultMessage(hr),
                     "无法读取 Windows 默认播放设备。");
  }
  IAudioEndpointVolume* endpoint = nullptr;
  hr = device->Activate(__uuidof(IAudioEndpointVolume), CLSCTX_ALL, nullptr,
                        reinterpret_cast<void**>(&endpoint));
  if (SUCCEEDED(hr) && endpoint != nullptr) {
    hr = endpoint->SetMasterVolumeLevelScalar(volume, nullptr);
    endpoint->Release();
  }
  device->Release();
  return StatusMap(SUCCEEDED(hr), "windowsProfile", HResultMessage(hr),
                   SUCCEEDED(hr) ? "已更新 Windows 输出音量。"
                                 : "更新 Windows 输出音量失败。");
}

flutter::EncodableMap SetEndpointMuted(bool muted) {
  winrt::init_apartment(winrt::apartment_type::multi_threaded);
  IMMDeviceEnumerator* enumerator = CreateDeviceEnumerator();
  if (enumerator == nullptr) {
    return StatusMap(false, "windowsProfile", "Unavailable",
                     "无法创建 Windows 音频端点枚举器。");
  }
  IMMDevice* device = nullptr;
  HRESULT hr = enumerator->GetDefaultAudioEndpoint(eRender, eMultimedia, &device);
  enumerator->Release();
  if (FAILED(hr) || device == nullptr) {
    return StatusMap(false, "windowsProfile", HResultMessage(hr),
                     "无法读取 Windows 默认播放设备。");
  }
  IAudioEndpointVolume* endpoint = nullptr;
  hr = device->Activate(__uuidof(IAudioEndpointVolume), CLSCTX_ALL, nullptr,
                        reinterpret_cast<void**>(&endpoint));
  if (SUCCEEDED(hr) && endpoint != nullptr) {
    hr = endpoint->SetMute(muted ? TRUE : FALSE, nullptr);
    endpoint->Release();
  }
  device->Release();
  return StatusMap(SUCCEEDED(hr), "windowsProfile", HResultMessage(hr),
                   SUCCEEDED(hr) ? "已更新 Windows 输出静音状态。"
                                 : "更新 Windows 输出静音状态失败。");
}

int64_t ToMilliseconds(foundation::TimeSpan value) {
  return std::chrono::duration_cast<std::chrono::milliseconds>(value).count();
}

flutter::EncodableMap EmptyCompanionOnlyResult(const std::string& message) {
  return StatusMap(false, "androidCompanion", "CompanionRequired", message);
}

bool SupportsRfcommProtection(const rfcomm::RfcommDeviceService& service) {
  switch (service.ProtectionLevel()) {
    case sockets::SocketProtectionLevel::PlainSocket:
      return service.MaxProtectionLevel() ==
                 sockets::SocketProtectionLevel::
                     BluetoothEncryptionWithAuthentication ||
             service.MaxProtectionLevel() ==
                 sockets::SocketProtectionLevel::
                     BluetoothEncryptionAllowNullAuthentication;
    case sockets::SocketProtectionLevel::BluetoothEncryptionWithAuthentication:
    case sockets::SocketProtectionLevel::BluetoothEncryptionAllowNullAuthentication:
      return true;
    default:
      return false;
  }
}

std::string ReadRfcommLine(const sockets::StreamSocket& socket) {
  streams::DataReader reader(socket.InputStream());
  reader.InputStreamOptions(streams::InputStreamOptions::Partial);
  std::string line;
  while (line.size() < kCompanionResponseLimit) {
    const uint32_t loaded = reader.LoadAsync(4096).get();
    if (loaded == 0) {
      break;
    }
    while (reader.UnconsumedBufferLength() > 0 &&
           line.size() < kCompanionResponseLimit) {
      const auto byte = reader.ReadByte();
      if (byte == '\n') {
        reader.DetachStream();
        return line;
      }
      if (byte != '\r') {
        line.push_back(static_cast<char>(byte));
      }
    }
  }
  reader.DetachStream();
  return line;
}

flutter::EncodableMap CompanionRequestRawInternal(
    const std::string& request_json) {
  if (request_json.empty()) {
    return StatusMap(false, "androidCompanion", "BadRequest",
                     "伴随端请求内容为空。");
  }
  try {
    winrt::init_apartment(winrt::apartment_type::multi_threaded);
    const auto service_id = rfcomm::RfcommServiceId::FromUuid(
        kPhoneCompanionServiceGuid);
    const auto selector = rfcomm::RfcommDeviceService::GetDeviceSelector(
        service_id);
    const auto services = devices::DeviceInformation::FindAllAsync(selector)
                              .get();
    if (services.Size() == 0) {
      return StatusMap(false, "androidCompanion", "NotFound",
                       "未发现 Android RFCOMM 伴随服务。请确认手机已配对，并已启动伴随服务。");
    }

    rfcomm::RfcommDeviceService service{nullptr};
    for (const auto& item : services) {
      service = rfcomm::RfcommDeviceService::FromIdAsync(item.Id()).get();
      if (service && SupportsRfcommProtection(service)) {
        break;
      }
      service = nullptr;
    }
    if (!service) {
      return StatusMap(false, "androidCompanion", "AccessDenied",
                       "发现了伴随服务，但 Windows 无法获得可用的加密 RFCOMM 连接。");
    }

    sockets::StreamSocket socket;
    socket.Control().KeepAlive(true);
    socket
        .ConnectAsync(service.ConnectionHostName(),
                      service.ConnectionServiceName(),
                      sockets::SocketProtectionLevel::
                          BluetoothEncryptionAllowNullAuthentication)
        .get();

    streams::DataWriter writer(socket.OutputStream());
    writer.UnicodeEncoding(streams::UnicodeEncoding::Utf8);
    writer.WriteString(winrt::to_hstring(request_json + "\n"));
    writer.StoreAsync().get();
    writer.FlushAsync().get();
    writer.DetachStream();

    auto value = StatusMap(true, "androidCompanion", "Success",
                           "已通过 Android RFCOMM 伴随通道完成请求。");
    value[flutter::EncodableValue("responseJson")] =
        flutter::EncodableValue(ReadRfcommLine(socket));
    socket.Close();
    return value;
  } catch (const winrt::hresult_error& error) {
    return StatusMap(false, "androidCompanion", "Failed",
                     "Android RFCOMM 伴随请求失败：" +
                         HStringToUtf8(error.message()));
  } catch (const std::exception& error) {
    return StatusMap(false, "androidCompanion", "Failed",
                     std::string("Android RFCOMM 伴随请求失败：") +
                         error.what());
  }
}

bool CompanionServiceAvailable() {
  try {
    winrt::init_apartment(winrt::apartment_type::multi_threaded);
    const auto service_id = rfcomm::RfcommServiceId::FromUuid(
        kPhoneCompanionServiceGuid);
    const auto selector = rfcomm::RfcommDeviceService::GetDeviceSelector(
        service_id);
    return devices::DeviceInformation::FindAllAsync(selector).get().Size() > 0;
  } catch (...) {
    return false;
  }
}

}  // namespace

class PhoneManagerChannel::Impl {
 public:
  explicit Impl(flutter::BinaryMessenger* messenger)
      : channel_(std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
            messenger, "personal_toolbox/phone_manager",
            &flutter::StandardMethodCodec::GetInstance())) {
    channel_->SetMethodCallHandler(
        [this](const flutter::MethodCall<flutter::EncodableValue>& call,
               std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
                   result) { HandleMethodCall(call, std::move(result)); });
  }

  ~Impl() {
    shutting_down_.store(true);
    channel_->SetMethodCallHandler(nullptr);
    ReleaseAllConnectionsInternal();
    JoinWorkers();
    ReleaseAllConnectionsInternal();
  }

 private:
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
    if (call.method_name() == "checkSupport") {
      RunWorker(std::thread([result = std::move(result)]() mutable {
        result->Success(flutter::EncodableValue(CheckSupportInternal()));
      }));
      return;
    }
    if (call.method_name() == "listDevices") {
      ListDevices(std::move(result));
      return;
    }
    if (call.method_name() == "connectDevice") {
      ConnectDevice(call, std::move(result));
      return;
    }
    if (call.method_name() == "disconnectDevice") {
      DisconnectDevice(call, std::move(result));
      return;
    }
    if (call.method_name() == "startAudioTransfer") {
      StartAudioTransfer(call, std::move(result));
      return;
    }
    if (call.method_name() == "stopAudioTransfer") {
      StopAudioTransfer(call, std::move(result));
      return;
    }
    if (call.method_name() == "getMediaSession") {
      GetMediaSession(std::move(result));
      return;
    }
    if (call.method_name() == "sendMediaCommand") {
      SendMediaCommand(call, std::move(result));
      return;
    }
    if (call.method_name() == "getVolumeState") {
      GetVolumeState(std::move(result));
      return;
    }
    if (call.method_name() == "setVolume") {
      SetVolume(call, std::move(result));
      return;
    }
    if (call.method_name() == "setMuted") {
      SetMuted(call, std::move(result));
      return;
    }
    if (call.method_name() == "companionRequestRaw") {
      std::string request_json;
      if (const auto* args =
              std::get_if<flutter::EncodableMap>(call.arguments())) {
        request_json = GetStringArg(*args, "requestJson");
      }
      RunWorker(std::thread([request_json, result = std::move(result)]() mutable {
        result->Success(
            flutter::EncodableValue(CompanionRequestRawInternal(request_json)));
      }));
      return;
    }
    if (call.method_name() == "listContacts" ||
        call.method_name() == "listMessages" ||
        call.method_name() == "listCallLogs" ||
        call.method_name() == "listFiles") {
      RunWorker(std::thread([result = std::move(result)]() mutable {
        result->Success(flutter::EncodableValue(flutter::EncodableList{}));
      }));
      return;
    }
    if (call.method_name() == "getDiagnostics") {
      RunWorker(std::thread([result = std::move(result)]() mutable {
        result->Success(flutter::EncodableValue(DiagnosticsInternal()));
      }));
      return;
    }
    if (call.method_name() == "openPanSettings") {
      RunWorker(std::thread([result = std::move(result)]() mutable {
        const auto shell_result = reinterpret_cast<intptr_t>(ShellExecuteW(
            nullptr, L"open", L"ms-settings:network-bluetooth", nullptr,
            nullptr, SW_SHOWNORMAL));
        result->Success(flutter::EncodableValue(StatusMap(
            shell_result > 32, "systemGuided",
            shell_result > 32 ? "Opened" : "Failed",
            shell_result > 32 ? "已打开 Windows 蓝牙网络设置。"
                              : "无法打开 Windows 蓝牙网络设置。")));
      }));
      return;
    }
    result->NotImplemented();
  }

  static flutter::EncodableMap CheckSupportInternal() {
    try {
      winrt::init_apartment(winrt::apartment_type::multi_threaded);
      const bool audio_supported = metadata::ApiInformation::IsTypePresent(
          L"Windows.Media.Audio.AudioPlaybackConnection");
      const bool media_supported = metadata::ApiInformation::IsTypePresent(
          L"Windows.Media.Control.GlobalSystemMediaTransportControlsSessionManager");
      auto value = StatusMap(
          audio_supported, "windowsProfile",
          audio_supported ? "Ready" : "Unsupported",
          audio_supported
              ? "Windows 支持蓝牙 A2DP 接收。媒体控制、音量和伴随端数据会按能力显示。"
              : "当前 Windows 不支持 AudioPlaybackConnection，至少需要 Windows 10 2004。");
      flutter::EncodableList missing;
      flutter::EncodableList warnings;
      if (!IsPackagedProcess()) {
        warnings.push_back(flutter::EncodableValue(
            "当前是普通 Windows 运行模式；完整蓝牙/媒体/通话能力请使用带 capability manifest 的 MSIX 安装版验收。"));
      }
      if (!media_supported) {
        warnings.push_back(flutter::EncodableValue(
            "当前 Windows 不支持 GlobalSystemMediaTransportControlsSessionManager。"));
      }
      value[flutter::EncodableValue("missingPermissions")] =
          flutter::EncodableValue(missing);
      value[flutter::EncodableValue("runtimeWarnings")] =
          flutter::EncodableValue(warnings);
      return value;
    } catch (const winrt::hresult_error& error) {
      return StatusMap(false, "windowsProfile", "Failed",
                       "手机管理能力检测失败：" + HStringToUtf8(error.message()));
    } catch (const std::exception& error) {
      return StatusMap(false, "windowsProfile", "Failed",
                       std::string("手机管理能力检测失败：") + error.what());
    }
  }

  void ListDevices(
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
    RunWorker(std::thread([this, result = std::move(result)]() mutable {
      try {
        winrt::init_apartment(winrt::apartment_type::multi_threaded);
        const auto selector = audio::AudioPlaybackConnection::GetDeviceSelector();
        const auto discovered =
            devices::DeviceInformation::FindAllAsync(selector).get();
        const bool companion_available = CompanionServiceAvailable();
        flutter::EncodableList list;
        for (const auto& device : discovered) {
          const auto id = std::wstring(device.Id().c_str(), device.Id().size());
          flutter::EncodableMap item;
          item[flutter::EncodableValue("id")] =
              flutter::EncodableValue(WideToUtf8(id));
          item[flutter::EncodableValue("name")] =
              flutter::EncodableValue(HStringToUtf8(device.Name()));
          item[flutter::EncodableValue("enabled")] =
              flutter::EncodableValue(device.IsEnabled());
          item[flutter::EncodableValue("state")] =
              flutter::EncodableValue(StateForDevice(id));
          item[flutter::EncodableValue("companionOnline")] =
              flutter::EncodableValue(companion_available);
          item[flutter::EncodableValue("lastError")] =
              flutter::EncodableValue();
          item[flutter::EncodableValue("missingPermissions")] =
              flutter::EncodableValue(flutter::EncodableList{});
          item[flutter::EncodableValue("capabilities")] =
              flutter::EncodableValue(
                  CapabilitiesForDevice(device.IsEnabled(), companion_available));
          list.push_back(flutter::EncodableValue(item));
        }
        result->Success(flutter::EncodableValue(list));
      } catch (const winrt::hresult_error& error) {
        result->Error("phone_manager_list_failed",
                      HStringToUtf8(error.message()));
      } catch (const std::exception& error) {
        result->Error("phone_manager_list_failed", error.what());
      }
    }));
  }

  void ConnectDevice(
      const flutter::MethodCall<flutter::EncodableValue>& call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
    const auto device_id = DeviceIdFromCall(call, result.get());
    if (device_id.empty()) {
      return;
    }
    RunWorker(std::thread([this, device_id, result = std::move(result)]() mutable {
      try {
        auto connection = GetOrCreateConnection(device_id);
        if (!connection) {
          result->Success(flutter::EncodableValue(EmptyCompanionOnlyResult(
              "该设备没有可用的 A2DP 接收连接。")));
          return;
        }
        connection.StartAsync().get();
        auto value = StatusMap(true, "windowsProfile", "Success",
                               "已连接设备并启用蓝牙音频接收。");
        value[flutter::EncodableValue("state")] =
            flutter::EncodableValue(StateForConnection(connection));
        result->Success(flutter::EncodableValue(value));
      } catch (const winrt::hresult_error& error) {
        result->Error("phone_manager_connect_failed",
                      HStringToUtf8(error.message()));
      } catch (const std::exception& error) {
        result->Error("phone_manager_connect_failed", error.what());
      }
    }));
  }

  void DisconnectDevice(
      const flutter::MethodCall<flutter::EncodableValue>& call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
    const auto device_id = DeviceIdFromCall(call, result.get());
    if (device_id.empty()) {
      return;
    }
    RunWorker(std::thread([this, device_id, result = std::move(result)]() mutable {
      ReleaseConnectionInternal(device_id);
      auto value = StatusMap(true, "windowsProfile", "Success",
                             "已断开设备并释放蓝牙音频连接。");
      value[flutter::EncodableValue("state")] =
          flutter::EncodableValue("Disconnected");
      result->Success(flutter::EncodableValue(value));
    }));
  }

  void StartAudioTransfer(
      const flutter::MethodCall<flutter::EncodableValue>& call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
    const auto device_id = DeviceIdFromCall(call, result.get());
    if (device_id.empty()) {
      return;
    }
    RunWorker(std::thread([this, device_id, result = std::move(result)]() mutable {
      try {
        auto connection = GetOrCreateConnection(device_id);
        if (!connection) {
          result->Success(flutter::EncodableValue(EmptyCompanionOnlyResult(
              "该设备没有可用的 A2DP 接收连接。")));
          return;
        }
        connection.StartAsync().get();
        const auto open_result = connection.OpenAsync().get();
        const auto status = open_result.Status();
        const bool success =
            status == audio::AudioPlaybackConnectionOpenResultStatus::Success;
        auto value = StatusMap(
            success, "windowsProfile", OpenStatusName(status),
            success ? "已开始传输手机蓝牙音频。"
                    : "开始传输手机蓝牙音频失败：" + OpenStatusName(status));
        value[flutter::EncodableValue("state")] =
            flutter::EncodableValue(StateForConnection(connection));
        result->Success(flutter::EncodableValue(value));
      } catch (const winrt::hresult_error& error) {
        result->Error("phone_manager_audio_start_failed",
                      HStringToUtf8(error.message()));
      } catch (const std::exception& error) {
        result->Error("phone_manager_audio_start_failed", error.what());
      }
    }));
  }

  void StopAudioTransfer(
      const flutter::MethodCall<flutter::EncodableValue>& call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
    const auto device_id = DeviceIdFromCall(call, result.get());
    if (device_id.empty()) {
      return;
    }
    RunWorker(std::thread([this, device_id, result = std::move(result)]() mutable {
      try {
        auto connection = ConnectionForId(device_id);
        if (connection) {
          connection.Close();
          connection.StartAsync().get();
        }
        auto value = StatusMap(true, "windowsProfile", "Success",
                               "已关闭音频传输，设备连接授权仍保留。");
        value[flutter::EncodableValue("state")] =
            flutter::EncodableValue(connection ? "AudioEnabled"
                                               : "Disconnected");
        result->Success(flutter::EncodableValue(value));
      } catch (const winrt::hresult_error& error) {
        result->Error("phone_manager_audio_stop_failed",
                      HStringToUtf8(error.message()));
      } catch (const std::exception& error) {
        result->Error("phone_manager_audio_stop_failed", error.what());
      }
    }));
  }

  void GetMediaSession(
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
    RunWorker(std::thread([result = std::move(result)]() mutable {
      try {
        result->Success(flutter::EncodableValue(MediaSessionInternal()));
      } catch (const winrt::hresult_error& error) {
        result->Success(flutter::EncodableValue(StatusMap(
            false, "windowsProfile", "Failed",
            "读取 Windows 媒体会话失败：" + HStringToUtf8(error.message()))));
      } catch (const std::exception& error) {
        result->Success(flutter::EncodableValue(StatusMap(
            false, "windowsProfile", "Failed",
            std::string("读取 Windows 媒体会话失败：") + error.what())));
      }
    }));
  }

  void SendMediaCommand(
      const flutter::MethodCall<flutter::EncodableValue>& call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
    std::string command;
    int64_t position_ms = 0;
    if (const auto* args = std::get_if<flutter::EncodableMap>(call.arguments())) {
      command = GetStringArg(*args, "command");
      position_ms = static_cast<int64_t>(GetDoubleArg(*args, "positionMs", 0));
    }
    RunWorker(std::thread([command, position_ms, result = std::move(result)]() mutable {
      try {
        winrt::init_apartment(winrt::apartment_type::multi_threaded);
        const auto manager =
            control::GlobalSystemMediaTransportControlsSessionManager::
                RequestAsync()
                    .get();
        const auto session = manager.GetCurrentSession();
        if (!session) {
          result->Success(flutter::EncodableValue(StatusMap(
              false, "windowsProfile", "NoSession",
              "当前没有可控制的 Windows 媒体会话。")));
          return;
        }
        bool ok = false;
        if (command == "play") {
          ok = session.TryPlayAsync().get();
        } else if (command == "pause") {
          ok = session.TryPauseAsync().get();
        } else if (command == "togglePlayPause") {
          ok = session.TryTogglePlayPauseAsync().get();
        } else if (command == "stop") {
          ok = session.TryStopAsync().get();
        } else if (command == "next") {
          ok = session.TrySkipNextAsync().get();
        } else if (command == "previous") {
          ok = session.TrySkipPreviousAsync().get();
        } else if (command == "seek") {
          foundation::TimeSpan position{std::chrono::milliseconds(position_ms)};
          ok = session.TryChangePlaybackPositionAsync(position.count()).get();
        }
        result->Success(flutter::EncodableValue(StatusMap(
            ok, "windowsProfile", ok ? "Success" : "Rejected",
            ok ? "媒体控制命令已发送。" : "当前媒体会话拒绝该控制命令。")));
      } catch (const winrt::hresult_error& error) {
        result->Success(flutter::EncodableValue(StatusMap(
            false, "windowsProfile", "Failed",
            "媒体控制命令失败：" + HStringToUtf8(error.message()))));
      } catch (const std::exception& error) {
        result->Success(flutter::EncodableValue(StatusMap(
            false, "windowsProfile", "Failed",
            std::string("媒体控制命令失败：") + error.what())));
      }
    }));
  }

  void GetVolumeState(
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
    RunWorker(std::thread([result = std::move(result)]() mutable {
      const auto snapshot = ReadEndpointVolume();
      auto value = StatusMap(snapshot.available, "windowsProfile",
                             snapshot.status, snapshot.message);
      value[flutter::EncodableValue("volume")] =
          flutter::EncodableValue(static_cast<double>(snapshot.volume));
      value[flutter::EncodableValue("muted")] =
          flutter::EncodableValue(snapshot.muted);
      value[flutter::EncodableValue("endpointName")] =
          flutter::EncodableValue(snapshot.endpoint_name);
      result->Success(flutter::EncodableValue(value));
    }));
  }

  void SetVolume(
      const flutter::MethodCall<flutter::EncodableValue>& call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
    double volume = 0.0;
    if (const auto* args = std::get_if<flutter::EncodableMap>(call.arguments())) {
      volume = GetDoubleArg(*args, "volume", 0.0);
    }
    RunWorker(std::thread([volume, result = std::move(result)]() mutable {
      result->Success(
          flutter::EncodableValue(SetEndpointVolume(static_cast<float>(volume))));
    }));
  }

  void SetMuted(
      const flutter::MethodCall<flutter::EncodableValue>& call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
    bool muted = false;
    if (const auto* args = std::get_if<flutter::EncodableMap>(call.arguments())) {
      muted = GetBoolArg(*args, "muted", false);
    }
    RunWorker(std::thread([muted, result = std::move(result)]() mutable {
      result->Success(flutter::EncodableValue(SetEndpointMuted(muted)));
    }));
  }

  static flutter::EncodableMap MediaSessionInternal() {
    winrt::init_apartment(winrt::apartment_type::multi_threaded);
    if (!metadata::ApiInformation::IsTypePresent(
            L"Windows.Media.Control.GlobalSystemMediaTransportControlsSessionManager")) {
      return StatusMap(false, "windowsProfile", "Unsupported",
                       "当前 Windows 不支持全局媒体会话 API。");
    }
    const auto manager =
        control::GlobalSystemMediaTransportControlsSessionManager::RequestAsync()
            .get();
    const auto session = manager.GetCurrentSession();
    if (!session) {
      return StatusMap(false, "windowsProfile", "NoSession",
                       "当前没有可读取的 Windows 媒体会话。");
    }

    const auto media = session.TryGetMediaPropertiesAsync().get();
    const auto playback = session.GetPlaybackInfo();
    const auto controls = playback.Controls();
    const auto timeline = session.GetTimelineProperties();

    auto value = StatusMap(true, "windowsProfile", "Success",
                           "已读取当前 Windows 媒体会话。");
    value[flutter::EncodableValue("title")] =
        flutter::EncodableValue(HStringToUtf8(media.Title()));
    value[flutter::EncodableValue("artist")] =
        flutter::EncodableValue(HStringToUtf8(media.Artist()));
    value[flutter::EncodableValue("album")] =
        flutter::EncodableValue(HStringToUtf8(media.AlbumTitle()));
    value[flutter::EncodableValue("thumbnailBase64")] =
        flutter::EncodableValue();
    value[flutter::EncodableValue("playbackStatus")] =
        flutter::EncodableValue(PlaybackStatusName(playback.PlaybackStatus()));
    value[flutter::EncodableValue("positionMs")] =
        flutter::EncodableValue(ToMilliseconds(timeline.Position()));
    value[flutter::EncodableValue("durationMs")] =
        flutter::EncodableValue(ToMilliseconds(timeline.EndTime()));
    value[flutter::EncodableValue("canPlay")] =
        flutter::EncodableValue(controls.IsPlayEnabled());
    value[flutter::EncodableValue("canPause")] =
        flutter::EncodableValue(controls.IsPauseEnabled());
    value[flutter::EncodableValue("canStop")] =
        flutter::EncodableValue(controls.IsStopEnabled());
    value[flutter::EncodableValue("canNext")] =
        flutter::EncodableValue(controls.IsNextEnabled());
    value[flutter::EncodableValue("canPrevious")] =
        flutter::EncodableValue(controls.IsPreviousEnabled());
    value[flutter::EncodableValue("canSeek")] =
        flutter::EncodableValue(controls.IsPlaybackPositionEnabled());
    return value;
  }

  static flutter::EncodableList DiagnosticsInternal() {
    flutter::EncodableList list;
    const bool packaged = IsPackagedProcess();
    const bool companion_available = CompanionServiceAvailable();
    list.push_back(flutter::EncodableValue(DiagnosticMap(
        "Windows 打包", packaged ? "Packaged" : "Unpackaged",
        packaged
            ? "当前进程以包身份运行，可以使用 MSIX manifest 声明的 capability。"
            : "当前进程不是 MSIX 包身份运行；globalMediaControl、bluetooth、phoneLineTransportManagement 可能被系统拒绝。",
        packaged ? "info" : "warning")));
    list.push_back(flutter::EncodableValue(DiagnosticMap(
        "A2DP",
        metadata::ApiInformation::IsTypePresent(
            L"Windows.Media.Audio.AudioPlaybackConnection")
            ? "Ready"
            : "Unsupported",
        "使用 AudioPlaybackConnection 管理手机向 Windows 传输音频。")));
    list.push_back(flutter::EncodableValue(DiagnosticMap(
        "AVRCP/媒体",
        metadata::ApiInformation::IsTypePresent(
            L"Windows.Media.Control.GlobalSystemMediaTransportControlsSessionManager")
            ? "Ready"
            : "Unsupported",
        "使用 GlobalSystemMediaTransportControlsSessionManager 读取媒体元数据和控制播放。")));
    list.push_back(flutter::EncodableValue(DiagnosticMap(
        "PBAP/MAP/OPP/SPP",
        companion_available ? "CompanionOnline" : "CompanionPreferred",
        companion_available
            ? "已发现 Android RFCOMM 伴随服务；联系人、短信、通话记录和会话文件可经伴随通道读取。"
            : "Windows 原生层保留 RFCOMM/OBEX 诊断入口；联系人、短信和文件优先由 Android 伴随端通过加密 RFCOMM 会话补齐。",
        companion_available ? "info" : "warning")));
    list.push_back(flutter::EncodableValue(DiagnosticMap(
        "HFP",
        metadata::ApiInformation::IsTypePresent(
            L"Windows.ApplicationModel.Calls.PhoneLineTransportDevice")
            ? "CapabilityRequired"
            : "Unsupported",
        "HFP 需要 phoneLineTransportManagement restricted capability；未授权时会显示权限诊断。",
        "warning")));
    list.push_back(flutter::EncodableValue(DiagnosticMap(
        "PAN", "SystemGuided",
        "Windows 没有稳定公开的一键 PAN 连接 API，使用系统设置入口和 BthPan 适配器状态确认。")));
    list.push_back(flutter::EncodableValue(DiagnosticMap(
        "HID", "AndroidCompanion",
        "HID 需要 Android 伴随端注册 BluetoothHidDevice，Windows 侧按标准 HID 设备接收输入。")));
    return list;
  }

  static flutter::EncodableList CapabilitiesForDevice(bool device_enabled,
                                                      bool companion_available) {
    flutter::EncodableList capabilities;
    capabilities.push_back(flutter::EncodableValue(CapabilityMap(
        "a2dp", "A2DP", device_enabled, "windowsProfile",
        device_enabled ? "Ready" : "Disabled",
        "Windows A2DP 接收用于手机音频传输。")));
    capabilities.push_back(flutter::EncodableValue(CapabilityMap(
        "avrcp", "AVRCP", true, "windowsProfile", "SessionBased",
        "通过 Windows 全局媒体会话读取和控制媒体。")));
    capabilities.push_back(flutter::EncodableValue(CapabilityMap(
        "volume", "音量", true, "windowsProfile", "Ready",
        "通过 Windows Core Audio 控制当前输出端点音量。")));
    capabilities.push_back(flutter::EncodableValue(CapabilityMap(
        "pbap", "PBAP", companion_available, "androidCompanion",
        companion_available ? "CompanionOnline" : "CompanionPreferred",
        "联系人优先由 Android 伴随端补齐，避免依赖手机厂商 PBAP 行为。")));
    capabilities.push_back(flutter::EncodableValue(CapabilityMap(
        "map", "MAP", companion_available, "androidCompanion",
        companion_available ? "CompanionOnline" : "CompanionPreferred",
        "短信优先由 Android 伴随端补齐，避免依赖手机厂商 MAP 行为。")));
    capabilities.push_back(flutter::EncodableValue(CapabilityMap(
        "opp", "OPP", companion_available, "androidCompanion",
        companion_available ? "CompanionOnline" : "CompanionPreferred",
        "文件传输优先由 Android 伴随端和用户选择文件补齐。")));
    capabilities.push_back(flutter::EncodableValue(CapabilityMap(
        "spp", "SPP", companion_available, "androidCompanion",
        companion_available ? "CompanionOnline" : "CompanionRequired",
        "自定义数据通道需要 Android 伴随端 RFCOMM 服务。")));
    capabilities.push_back(flutter::EncodableValue(CapabilityMap(
        "hfp", "HFP", false, "windowsProfile", "CapabilityRequired",
        "通话控制需要 phoneLineTransportManagement restricted capability。")));
    capabilities.push_back(flutter::EncodableValue(CapabilityMap(
        "pan", "PAN", true, "systemGuided", "SystemGuided",
        "PAN 使用 Windows 系统设置入口和 BthPan 适配器状态确认。")));
    capabilities.push_back(flutter::EncodableValue(CapabilityMap(
        "hid", "HID", companion_available, "androidCompanion",
        companion_available ? "CompanionOnline" : "CompanionRequired",
        "远程输入需要 Android 伴随端注册 HID Device。")));
    return capabilities;
  }

  std::wstring DeviceIdFromCall(
      const flutter::MethodCall<flutter::EncodableValue>& call,
      flutter::MethodResult<flutter::EncodableValue>* result) {
    const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
    if (args == nullptr) {
      result->Error("bad_args", "phone_manager_missing_args");
      return L"";
    }
    const auto device_id = GetStringArg(*args, "deviceId");
    if (device_id.empty()) {
      result->Error("bad_args", "phone_manager_missing_device_id");
      return L"";
    }
    return Utf8ToWide(device_id);
  }

  audio::AudioPlaybackConnection GetOrCreateConnection(
      const std::wstring& device_id) {
    {
      std::lock_guard<std::mutex> lock(connections_mutex_);
      const auto it = connections_.find(device_id);
      if (it != connections_.end()) {
        return it->second;
      }
    }

    winrt::init_apartment(winrt::apartment_type::multi_threaded);
    auto connection = audio::AudioPlaybackConnection::TryCreateFromId(
        winrt::hstring(device_id));
    if (!connection) {
      return nullptr;
    }
    {
      std::lock_guard<std::mutex> lock(connections_mutex_);
      connections_.insert_or_assign(device_id, connection);
    }
    return connection;
  }

  audio::AudioPlaybackConnection ConnectionForId(const std::wstring& device_id) {
    std::lock_guard<std::mutex> lock(connections_mutex_);
    const auto it = connections_.find(device_id);
    if (it == connections_.end()) {
      return nullptr;
    }
    return it->second;
  }

  audio::AudioPlaybackConnection TakeConnectionForId(
      const std::wstring& device_id) {
    std::lock_guard<std::mutex> lock(connections_mutex_);
    const auto it = connections_.find(device_id);
    if (it == connections_.end()) {
      return nullptr;
    }
    auto connection = it->second;
    connections_.erase(it);
    return connection;
  }

  std::string StateForDevice(const std::wstring& device_id) {
    auto connection = ConnectionForId(device_id);
    if (!connection) {
      return "Disconnected";
    }
    return StateForConnection(connection);
  }

  std::string StateForConnection(
      const audio::AudioPlaybackConnection& connection) {
    if (!connection) {
      return "Disconnected";
    }
    try {
      const auto state = connection.State();
      if (state == audio::AudioPlaybackConnectionState::Closed) {
        return "AudioEnabled";
      }
      return StateName(state);
    } catch (...) {
      return "Unknown";
    }
  }

  void ReleaseConnectionInternal(const std::wstring& device_id) {
    auto connection = TakeConnectionForId(device_id);
    if (connection) {
      CloseIgnoringErrors(connection);
    }
  }

  void ReleaseAllConnectionsInternal() {
    std::vector<audio::AudioPlaybackConnection> connections;
    {
      std::lock_guard<std::mutex> lock(connections_mutex_);
      for (const auto& item : connections_) {
        connections.push_back(item.second);
      }
      connections_.clear();
    }
    for (const auto& connection : connections) {
      if (connection) {
        CloseIgnoringErrors(connection);
      }
    }
  }

  void CloseIgnoringErrors(
      const audio::AudioPlaybackConnection& connection) noexcept {
    try {
      connection.Close();
    } catch (...) {
    }
  }

  void RunWorker(std::thread worker) {
    std::lock_guard<std::mutex> lock(workers_mutex_);
    workers_.push_back(std::move(worker));
  }

  void JoinWorkers() {
    std::vector<std::thread> workers;
    {
      std::lock_guard<std::mutex> lock(workers_mutex_);
      workers.swap(workers_);
    }
    for (auto& worker : workers) {
      if (worker.joinable() && worker.get_id() != std::this_thread::get_id()) {
        worker.join();
      }
    }
  }

  std::atomic_bool shutting_down_{false};
  std::mutex workers_mutex_;
  std::vector<std::thread> workers_;
  std::mutex connections_mutex_;
  std::map<std::wstring, audio::AudioPlaybackConnection> connections_;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
};

PhoneManagerChannel::PhoneManagerChannel(flutter::BinaryMessenger* messenger)
    : impl_(std::make_unique<Impl>(messenger)) {}

PhoneManagerChannel::~PhoneManagerChannel() = default;
