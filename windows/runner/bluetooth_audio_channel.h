#ifndef RUNNER_BLUETOOTH_AUDIO_CHANNEL_H_
#define RUNNER_BLUETOOTH_AUDIO_CHANNEL_H_

#include <flutter/binary_messenger.h>
#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>

#include <memory>

class BluetoothAudioChannel {
 public:
  explicit BluetoothAudioChannel(flutter::BinaryMessenger* messenger);
  ~BluetoothAudioChannel();

  BluetoothAudioChannel(const BluetoothAudioChannel&) = delete;
  BluetoothAudioChannel& operator=(const BluetoothAudioChannel&) = delete;

 private:
  class Impl;

  std::unique_ptr<Impl> impl_;
};

#endif  // RUNNER_BLUETOOTH_AUDIO_CHANNEL_H_
