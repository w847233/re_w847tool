#include "system_control_channel.h"

#include <flutter/method_result_functions.h>
#include <flutter/standard_method_codec.h>
#include <windows.h>

#include <memory>

namespace {

bool TurnOffDisplay() {
  const LRESULT result =
      SendMessageTimeout(HWND_BROADCAST, WM_SYSCOMMAND, SC_MONITORPOWER, 2,
                         SMTO_ABORTIFHUNG, 1000, nullptr);
  return result != 0;
}

}  // namespace

class SystemControlChannel::Impl {
 public:
  explicit Impl(flutter::BinaryMessenger* messenger)
      : channel_(std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
            messenger, "personal_toolbox/system_control",
            &flutter::StandardMethodCodec::GetInstance())) {
    channel_->SetMethodCallHandler(
        [this](const flutter::MethodCall<flutter::EncodableValue>& call,
               std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
                   result) { HandleMethodCall(call, std::move(result)); });
  }

  ~Impl() { channel_->SetMethodCallHandler(nullptr); }

 private:
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
    if (call.method_name() == "turnOffDisplay") {
      if (TurnOffDisplay()) {
        result->Success();
      } else {
        result->Error("turn_off_display_failed",
                      "Windows did not accept the monitor power command.");
      }
      return;
    }
    result->NotImplemented();
  }

  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
};

SystemControlChannel::SystemControlChannel(flutter::BinaryMessenger* messenger)
    : impl_(std::make_unique<Impl>(messenger)) {}

SystemControlChannel::~SystemControlChannel() = default;
