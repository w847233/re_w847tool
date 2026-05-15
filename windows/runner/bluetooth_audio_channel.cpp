#include "bluetooth_audio_channel.h"

#include <windows.h>

#include <flutter/method_result_functions.h>
#include <flutter/standard_method_codec.h>

#include <Audioclient.h>
#include <endpointvolume.h>
#include <mmdeviceapi.h>
#include <propidl.h>
#include <propkeydef.h>
#include <propsys.h>
#include <Functiondiscoverykeys_devpkey.h>
#include <winrt/Windows.Devices.Enumeration.h>
#include <winrt/Windows.Foundation.h>
#include <winrt/Windows.Foundation.Collections.h>
#include <winrt/Windows.Foundation.Metadata.h>
#include <winrt/Windows.Media.Audio.h>
#include <winrt/base.h>

#include <atomic>
#include <cstdio>
#include <map>
#include <memory>
#include <mutex>
#include <string>
#include <thread>
#include <vector>

namespace {

namespace audio = winrt::Windows::Media::Audio;
namespace devices = winrt::Windows::Devices::Enumeration;
namespace metadata = winrt::Windows::Foundation::Metadata;

class DECLSPEC_UUID("f8679f50-850a-41cf-9c72-430f290290c8") IPolicyConfig
    : public IUnknown {
 public:
  virtual HRESULT STDMETHODCALLTYPE GetMixFormat(PCWSTR, WAVEFORMATEX**) = 0;
  virtual HRESULT STDMETHODCALLTYPE GetDeviceFormat(PCWSTR, INT,
                                                   WAVEFORMATEX**) = 0;
  virtual HRESULT STDMETHODCALLTYPE ResetDeviceFormat(PCWSTR) = 0;
  virtual HRESULT STDMETHODCALLTYPE SetDeviceFormat(PCWSTR, WAVEFORMATEX*,
                                                   WAVEFORMATEX*) = 0;
  virtual HRESULT STDMETHODCALLTYPE GetProcessingPeriod(PCWSTR, INT, PINT64,
                                                       PINT64) = 0;
  virtual HRESULT STDMETHODCALLTYPE SetProcessingPeriod(PCWSTR, PINT64) = 0;
  virtual HRESULT STDMETHODCALLTYPE GetShareMode(PCWSTR, void*) = 0;
  virtual HRESULT STDMETHODCALLTYPE SetShareMode(PCWSTR, void*) = 0;
  virtual HRESULT STDMETHODCALLTYPE GetPropertyValue(PCWSTR, const PROPERTYKEY&,
                                                    PROPVARIANT*) = 0;
  virtual HRESULT STDMETHODCALLTYPE SetPropertyValue(PCWSTR, const PROPERTYKEY&,
                                                    PROPVARIANT*) = 0;
  virtual HRESULT STDMETHODCALLTYPE SetDefaultEndpoint(PCWSTR, ERole) = 0;
  virtual HRESULT STDMETHODCALLTYPE SetEndpointVisibility(PCWSTR, INT) = 0;
};

class DECLSPEC_UUID("870af99c-171d-4f9e-af0d-e63df40c2bc9")
    CPolicyConfigClient;

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

std::string StateName(audio::AudioPlaybackConnectionState state) {
  switch (state) {
    case audio::AudioPlaybackConnectionState::Opened:
      return "Opened";
    case audio::AudioPlaybackConnectionState::Closed:
      return "Closed";
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

flutter::EncodableMap SupportMap(bool supported, const std::string& message) {
  flutter::EncodableMap value;
  value[flutter::EncodableValue("supported")] =
      flutter::EncodableValue(supported);
  value[flutter::EncodableValue("message")] = flutter::EncodableValue(message);
  return value;
}

flutter::EncodableMap ConnectionResultMap(bool success,
                                          const std::string& status,
                                          const std::string& state,
                                          const std::string& message) {
  flutter::EncodableMap value;
  value[flutter::EncodableValue("success")] = flutter::EncodableValue(success);
  value[flutter::EncodableValue("status")] = flutter::EncodableValue(status);
  value[flutter::EncodableValue("state")] = flutter::EncodableValue(state);
  value[flutter::EncodableValue("message")] = flutter::EncodableValue(message);
  return value;
}

std::string HResultMessage(HRESULT hr) {
  char buffer[32];
  snprintf(buffer, sizeof(buffer), "0x%08X", static_cast<unsigned int>(hr));
  return std::string(buffer);
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

std::wstring DeviceId(IMMDevice* device) {
  LPWSTR raw_id = nullptr;
  std::wstring id;
  if (SUCCEEDED(device->GetId(&raw_id)) && raw_id != nullptr) {
    id = raw_id;
    CoTaskMemFree(raw_id);
  }
  return id;
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

std::wstring DefaultRenderDeviceId(IMMDeviceEnumerator* enumerator) {
  IMMDevice* device = nullptr;
  std::wstring id;
  if (SUCCEEDED(enumerator->GetDefaultAudioEndpoint(eRender, eMultimedia,
                                                    &device)) &&
      device != nullptr) {
    id = DeviceId(device);
    device->Release();
  }
  return id;
}

flutter::EncodableList ListPlaybackDevicesInternal() {
  flutter::EncodableList list;
  winrt::init_apartment(winrt::apartment_type::multi_threaded);
  IMMDeviceEnumerator* enumerator = CreateDeviceEnumerator();
  if (enumerator == nullptr) {
    return list;
  }
  const std::wstring default_id = DefaultRenderDeviceId(enumerator);
  IMMDeviceCollection* collection = nullptr;
  if (SUCCEEDED(enumerator->EnumAudioEndpoints(eRender, DEVICE_STATE_ACTIVE,
                                               &collection)) &&
      collection != nullptr) {
    UINT count = 0;
    collection->GetCount(&count);
    for (UINT index = 0; index < count; ++index) {
      IMMDevice* device = nullptr;
      if (FAILED(collection->Item(index, &device)) || device == nullptr) {
        continue;
      }
      const std::wstring id = DeviceId(device);
      const std::wstring name = DeviceFriendlyName(device);
      flutter::EncodableMap item;
      item[flutter::EncodableValue("id")] = flutter::EncodableValue(WideToUtf8(id));
      item[flutter::EncodableValue("name")] =
          flutter::EncodableValue(WideToUtf8(name.empty() ? id : name));
      item[flutter::EncodableValue("isDefault")] =
          flutter::EncodableValue(!id.empty() && id == default_id);
      list.push_back(flutter::EncodableValue(item));
      device->Release();
    }
    collection->Release();
  }
  enumerator->Release();
  return list;
}

HRESULT SetDefaultRenderDeviceInternal(const std::wstring& device_id) {
  winrt::init_apartment(winrt::apartment_type::multi_threaded);
  IPolicyConfig* policy = nullptr;
  const HRESULT create_hr =
      CoCreateInstance(__uuidof(CPolicyConfigClient), nullptr, CLSCTX_ALL,
                       __uuidof(IPolicyConfig),
                       reinterpret_cast<void**>(&policy));
  if (FAILED(create_hr) || policy == nullptr) {
    return FAILED(create_hr) ? create_hr : E_POINTER;
  }
  HRESULT hr = policy->SetDefaultEndpoint(device_id.c_str(), eConsole);
  if (SUCCEEDED(hr)) {
    hr = policy->SetDefaultEndpoint(device_id.c_str(), eMultimedia);
  }
  if (SUCCEEDED(hr)) {
    hr = policy->SetDefaultEndpoint(device_id.c_str(), eCommunications);
  }
  policy->Release();
  return hr;
}

float PlaybackPeakInternal(const std::wstring& device_id) {
  winrt::init_apartment(winrt::apartment_type::multi_threaded);
  IMMDeviceEnumerator* enumerator = CreateDeviceEnumerator();
  if (enumerator == nullptr) {
    return 0.0f;
  }

  IMMDevice* device = nullptr;
  if (device_id.empty()) {
    enumerator->GetDefaultAudioEndpoint(eRender, eMultimedia, &device);
  } else {
    enumerator->GetDevice(device_id.c_str(), &device);
  }
  enumerator->Release();
  if (device == nullptr) {
    return 0.0f;
  }

  IAudioMeterInformation* meter = nullptr;
  float peak = 0.0f;
  if (SUCCEEDED(device->Activate(__uuidof(IAudioMeterInformation), CLSCTX_ALL,
                                 nullptr,
                                 reinterpret_cast<void**>(&meter))) &&
      meter != nullptr) {
    meter->GetPeakValue(&peak);
    meter->Release();
  }
  device->Release();
  if (peak < 0.0f) {
    return 0.0f;
  }
  if (peak > 1.0f) {
    return 1.0f;
  }
  return peak;
}

}  // namespace

class BluetoothAudioChannel::Impl {
 public:
  explicit Impl(flutter::BinaryMessenger* messenger)
      : channel_(std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
            messenger, "personal_toolbox/bluetooth_audio",
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
    if (call.method_name() == "listPlaybackDevices") {
      ListPlaybackDevices(std::move(result));
      return;
    }
    if (call.method_name() == "setPlaybackDevice") {
      SetPlaybackDevice(call, std::move(result));
      return;
    }
    if (call.method_name() == "getPlaybackLevel") {
      GetPlaybackLevel(call, std::move(result));
      return;
    }
    if (call.method_name() == "enableConnection") {
      EnableConnection(call, std::move(result));
      return;
    }
    if (call.method_name() == "openConnection") {
      OpenConnection(call, std::move(result));
      return;
    }
    if (call.method_name() == "closeConnection") {
      CloseConnection(call, std::move(result));
      return;
    }
    if (call.method_name() == "releaseConnection") {
      ReleaseConnection(call, std::move(result));
      return;
    }
    if (call.method_name() == "releaseAllConnections") {
      RunWorker(std::thread([this, result = std::move(result)]() mutable {
        ReleaseAllConnectionsInternal();
        result->Success(flutter::EncodableValue(true));
      }));
      return;
    }
    result->NotImplemented();
  }

  static flutter::EncodableMap CheckSupportInternal() {
    try {
      winrt::init_apartment(winrt::apartment_type::multi_threaded);
      if (!metadata::ApiInformation::IsTypePresent(
              L"Windows.Media.Audio.AudioPlaybackConnection")) {
        return SupportMap(
            false,
            "AudioPlaybackConnection is not present. Windows 10 2004 or later "
            "is required.");
      }
      const auto selector = audio::AudioPlaybackConnection::GetDeviceSelector();
      if (selector.empty()) {
        return SupportMap(false, "Bluetooth audio device selector is empty.");
      }
      return SupportMap(true, "Bluetooth A2DP sink is supported.");
    } catch (const winrt::hresult_error& error) {
      return SupportMap(false,
                        "Bluetooth audio support check failed: " +
                            HStringToUtf8(error.message()));
    } catch (const std::exception& error) {
      return SupportMap(false,
                        std::string("Bluetooth audio support check failed: ") +
                            error.what());
    }
  }

  void ListDevices(
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
    RunWorker(std::thread([this, result = std::move(result)]() mutable {
      try {
        winrt::init_apartment(winrt::apartment_type::multi_threaded);
        const auto support = CheckSupportInternal();
        const auto supported =
            std::get<bool>(support.at(flutter::EncodableValue("supported")));
        if (!supported) {
          result->Success(flutter::EncodableValue(flutter::EncodableList{}));
          return;
        }

        const auto selector = audio::AudioPlaybackConnection::GetDeviceSelector();
        const auto discovered = devices::DeviceInformation::FindAllAsync(
                                    selector)
                                    .get();
        flutter::EncodableList list;
        for (const auto& device : discovered) {
          const auto id = std::wstring(device.Id().c_str(), device.Id().size());
          flutter::EncodableMap item;
          item[flutter::EncodableValue("id")] =
              flutter::EncodableValue(WideToUtf8(id));
          item[flutter::EncodableValue("name")] =
              flutter::EncodableValue(HStringToUtf8(device.Name()));
          item[flutter::EncodableValue("isEnabled")] =
              flutter::EncodableValue(device.IsEnabled());
          item[flutter::EncodableValue("state")] =
              flutter::EncodableValue(StateForDevice(id));
          list.push_back(flutter::EncodableValue(item));
        }
        result->Success(flutter::EncodableValue(list));
      } catch (const winrt::hresult_error& error) {
        result->Error("bluetooth_audio_list_failed",
                      HStringToUtf8(error.message()));
      } catch (const std::exception& error) {
        result->Error("bluetooth_audio_list_failed", error.what());
      }
    }));
  }

  void ListPlaybackDevices(
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
    RunWorker(std::thread([result = std::move(result)]() mutable {
      try {
        result->Success(
            flutter::EncodableValue(ListPlaybackDevicesInternal()));
      } catch (const winrt::hresult_error& error) {
        result->Error("bluetooth_audio_playback_list_failed",
                      HStringToUtf8(error.message()));
      } catch (const std::exception& error) {
        result->Error("bluetooth_audio_playback_list_failed", error.what());
      }
    }));
  }

  void SetPlaybackDevice(
      const flutter::MethodCall<flutter::EncodableValue>& call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
    const auto device_id = PlaybackDeviceIdFromCall(call, result.get());
    if (device_id.empty()) {
      return;
    }
    RunWorker(std::thread([device_id, result = std::move(result)]() mutable {
      try {
        const HRESULT hr = SetDefaultRenderDeviceInternal(device_id);
        flutter::EncodableMap value;
        value[flutter::EncodableValue("success")] =
            flutter::EncodableValue(SUCCEEDED(hr));
        value[flutter::EncodableValue("status")] =
            flutter::EncodableValue(HResultMessage(hr));
        value[flutter::EncodableValue("message")] =
            flutter::EncodableValue(SUCCEEDED(hr)
                                        ? "Default playback device changed."
                                        : "Failed to change playback device.");
        result->Success(flutter::EncodableValue(value));
      } catch (const winrt::hresult_error& error) {
        result->Error("bluetooth_audio_playback_set_failed",
                      HStringToUtf8(error.message()));
      } catch (const std::exception& error) {
        result->Error("bluetooth_audio_playback_set_failed", error.what());
      }
    }));
  }

  void GetPlaybackLevel(
      const flutter::MethodCall<flutter::EncodableValue>& call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
    std::wstring device_id;
    if (const auto* args =
            std::get_if<flutter::EncodableMap>(call.arguments())) {
      device_id = Utf8ToWide(GetStringArg(*args, "playbackDeviceId"));
    }
    RunWorker(std::thread([device_id, result = std::move(result)]() mutable {
      try {
        flutter::EncodableMap value;
        value[flutter::EncodableValue("level")] =
            flutter::EncodableValue(static_cast<double>(
                PlaybackPeakInternal(device_id)));
        result->Success(flutter::EncodableValue(value));
      } catch (const winrt::hresult_error& error) {
        result->Error("bluetooth_audio_playback_level_failed",
                      HStringToUtf8(error.message()));
      } catch (const std::exception& error) {
        result->Error("bluetooth_audio_playback_level_failed", error.what());
      }
    }));
  }

  void EnableConnection(
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
          result->Success(flutter::EncodableValue(ConnectionResultMap(
              false, "Unavailable", "Closed",
              "No audio playback connection is available for this device.")));
          return;
        }
        connection.StartAsync().get();
        result->Success(flutter::EncodableValue(ConnectionResultMap(
            true, "Success", StateForConnection(connection),
            "Bluetooth audio receiver is enabled.")));
      } catch (const winrt::hresult_error& error) {
        result->Error("bluetooth_audio_enable_failed",
                      HStringToUtf8(error.message()));
      } catch (const std::exception& error) {
        result->Error("bluetooth_audio_enable_failed", error.what());
      }
    }));
  }

  void OpenConnection(
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
          result->Success(flutter::EncodableValue(ConnectionResultMap(
              false, "Unavailable", "Closed",
              "No audio playback connection is available for this device.")));
          return;
        }
        connection.StartAsync().get();
        const auto open_result = connection.OpenAsync().get();
        const auto status = open_result.Status();
        const bool success =
            status == audio::AudioPlaybackConnectionOpenResultStatus::Success;
        const auto message =
            success ? "Bluetooth audio connection is open."
                    : "Bluetooth audio connection open failed: " +
                          OpenStatusName(status);
        result->Success(flutter::EncodableValue(ConnectionResultMap(
            success, OpenStatusName(status), StateForConnection(connection),
            message)));
      } catch (const winrt::hresult_error& error) {
        result->Error("bluetooth_audio_open_failed",
                      HStringToUtf8(error.message()));
      } catch (const std::exception& error) {
        result->Error("bluetooth_audio_open_failed", error.what());
      }
    }));
  }

  void CloseConnection(
      const flutter::MethodCall<flutter::EncodableValue>& call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
    const auto device_id = DeviceIdFromCall(call, result.get());
    if (device_id.empty()) {
      return;
    }
    RunWorker(std::thread([this, device_id, result = std::move(result)]() mutable {
      try {
        auto connection = TakeConnectionForId(device_id);
        if (!connection) {
          result->Success(flutter::EncodableValue(ConnectionResultMap(
              true, "Success", "Closed",
              "No active audio playback connection exists for this device.")));
          return;
        }
        connection.Close();
        result->Success(flutter::EncodableValue(ConnectionResultMap(
            true, "Success", "Closed", "Bluetooth audio playback is closed.")));
      } catch (const winrt::hresult_error& error) {
        result->Error("bluetooth_audio_close_failed",
                      HStringToUtf8(error.message()));
      } catch (const std::exception& error) {
        result->Error("bluetooth_audio_close_failed", error.what());
      }
    }));
  }

  void ReleaseConnection(
      const flutter::MethodCall<flutter::EncodableValue>& call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
    const auto device_id = DeviceIdFromCall(call, result.get());
    if (device_id.empty()) {
      return;
    }
    RunWorker(std::thread([this, device_id, result = std::move(result)]() mutable {
      try {
        ReleaseConnectionInternal(device_id);
        result->Success(flutter::EncodableValue(true));
      } catch (const winrt::hresult_error& error) {
        result->Error("bluetooth_audio_release_failed",
                      HStringToUtf8(error.message()));
      } catch (const std::exception& error) {
        result->Error("bluetooth_audio_release_failed", error.what());
      }
    }));
  }

  std::wstring DeviceIdFromCall(
      const flutter::MethodCall<flutter::EncodableValue>& call,
      flutter::MethodResult<flutter::EncodableValue>* result) {
    const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
    if (args == nullptr) {
      result->Error("bad_args", "bluetooth_audio_missing_args");
      return L"";
    }
    const auto device_id = GetStringArg(*args, "deviceId");
    if (device_id.empty()) {
      result->Error("bad_args", "bluetooth_audio_missing_device_id");
      return L"";
    }
    return Utf8ToWide(device_id);
  }

  std::wstring PlaybackDeviceIdFromCall(
      const flutter::MethodCall<flutter::EncodableValue>& call,
      flutter::MethodResult<flutter::EncodableValue>* result) {
    const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
    if (args == nullptr) {
      result->Error("bad_args", "bluetooth_audio_missing_args");
      return L"";
    }
    const auto device_id = GetStringArg(*args, "playbackDeviceId");
    if (device_id.empty()) {
      result->Error("bad_args", "bluetooth_audio_missing_playback_device_id");
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
      return "Closed";
    }
    return StateForConnection(connection);
  }

  std::string StateForConnection(
      const audio::AudioPlaybackConnection& connection) {
    if (!connection) {
      return "Closed";
    }
    try {
      const auto state = connection.State();
      if (state == audio::AudioPlaybackConnectionState::Closed) {
        return "Enabled";
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

BluetoothAudioChannel::BluetoothAudioChannel(flutter::BinaryMessenger* messenger)
    : impl_(std::make_unique<Impl>(messenger)) {}

BluetoothAudioChannel::~BluetoothAudioChannel() = default;
