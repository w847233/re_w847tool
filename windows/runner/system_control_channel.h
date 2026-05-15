#ifndef RUNNER_SYSTEM_CONTROL_CHANNEL_H_
#define RUNNER_SYSTEM_CONTROL_CHANNEL_H_

#include <flutter/binary_messenger.h>
#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>

#include <memory>

class SystemControlChannel {
 public:
  explicit SystemControlChannel(flutter::BinaryMessenger* messenger);
  ~SystemControlChannel();

  SystemControlChannel(const SystemControlChannel&) = delete;
  SystemControlChannel& operator=(const SystemControlChannel&) = delete;

 private:
  class Impl;

  std::unique_ptr<Impl> impl_;
};

#endif  // RUNNER_SYSTEM_CONTROL_CHANNEL_H_
