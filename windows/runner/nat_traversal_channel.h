#ifndef RUNNER_NAT_TRAVERSAL_CHANNEL_H_
#define RUNNER_NAT_TRAVERSAL_CHANNEL_H_

#include <flutter/binary_messenger.h>
#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>

#include <memory>

class NatTraversalChannel {
 public:
  explicit NatTraversalChannel(flutter::BinaryMessenger* messenger);
  ~NatTraversalChannel();

  NatTraversalChannel(const NatTraversalChannel&) = delete;
  NatTraversalChannel& operator=(const NatTraversalChannel&) = delete;

 private:
  class Impl;

  std::unique_ptr<Impl> impl_;
};

#endif  // RUNNER_NAT_TRAVERSAL_CHANNEL_H_
