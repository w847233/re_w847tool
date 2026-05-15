#ifndef RUNNER_PHONE_MANAGER_CHANNEL_H_
#define RUNNER_PHONE_MANAGER_CHANNEL_H_

#include <flutter/binary_messenger.h>
#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>

#include <memory>

class PhoneManagerChannel {
 public:
  explicit PhoneManagerChannel(flutter::BinaryMessenger* messenger);
  ~PhoneManagerChannel();

  PhoneManagerChannel(const PhoneManagerChannel&) = delete;
  PhoneManagerChannel& operator=(const PhoneManagerChannel&) = delete;

 private:
  class Impl;

  std::unique_ptr<Impl> impl_;
};

#endif  // RUNNER_PHONE_MANAGER_CHANNEL_H_
