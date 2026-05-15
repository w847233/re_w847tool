#include "nat_traversal_channel.h"

#include <flutter/method_result_functions.h>
#include <flutter/standard_method_codec.h>
#include <winsock2.h>
#include <ws2tcpip.h>
#include <windows.h>

#include <atomic>
#include <cstdint>
#include <cstring>
#include <map>
#include <memory>
#include <mutex>
#include <optional>
#include <random>
#include <sstream>
#include <string>
#include <thread>
#include <vector>

namespace {

constexpr uint32_t kStunMagicCookie = 0x2112A442;
constexpr int kConnectTimeoutMs = 10000;
constexpr int kKeepAliveSeconds = 30;

struct MappingStartResult {
  bool ok = false;
  std::string error;
  std::string public_ip;
  int public_port = 0;
  int local_bind_port = 0;
};

struct TcpProbeResult {
  bool ok = false;
  std::string error;
  std::string public_ip;
  int public_port = 0;
};

std::once_flag g_wsa_once;

void EnsureWinsock() {
  std::call_once(g_wsa_once, [] {
    WSADATA data;
    WSAStartup(MAKEWORD(2, 2), &data);
  });
}

std::string LastSocketError(const std::string& prefix) {
  std::ostringstream stream;
  stream << prefix << ", WSA error " << WSAGetLastError();
  return stream.str();
}

void CloseSocket(SOCKET& socket) {
  if (socket != INVALID_SOCKET) {
    closesocket(socket);
    socket = INVALID_SOCKET;
  }
}

SOCKET CreateReusableTcpSocket() {
  SOCKET socket = ::socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
  if (socket == INVALID_SOCKET) {
    return INVALID_SOCKET;
  }

  BOOL reuse = TRUE;
  setsockopt(socket, SOL_SOCKET, SO_REUSEADDR,
             reinterpret_cast<const char*>(&reuse), sizeof(reuse));
  return socket;
}

bool SetBlocking(SOCKET socket, bool blocking) {
  u_long mode = blocking ? 0 : 1;
  return ioctlsocket(socket, FIONBIO, &mode) == 0;
}

bool SendAll(SOCKET socket, const char* data, int length) {
  int sent = 0;
  while (sent < length) {
    int res = send(socket, data + sent, length - sent, 0);
    if (res <= 0) {
      return false;
    }
    sent += res;
  }
  return true;
}

void SetSocketTimeouts(SOCKET socket, int timeout_ms) {
  setsockopt(socket, SOL_SOCKET, SO_RCVTIMEO,
             reinterpret_cast<const char*>(&timeout_ms), sizeof(timeout_ms));
  setsockopt(socket, SOL_SOCKET, SO_SNDTIMEO,
             reinterpret_cast<const char*>(&timeout_ms), sizeof(timeout_ms));
}

bool RecvExact(SOCKET socket, char* data, int length) {
  int received = 0;
  while (received < length) {
    int res = recv(socket, data + received, length - received, 0);
    if (res <= 0) {
      return false;
    }
    received += res;
  }
  return true;
}

std::optional<sockaddr_in> ResolveIpv4(const std::string& host, int port) {
  addrinfo hints{};
  hints.ai_family = AF_INET;
  hints.ai_socktype = SOCK_STREAM;
  hints.ai_protocol = IPPROTO_TCP;

  addrinfo* result = nullptr;
  const std::string port_text = std::to_string(port);
  if (getaddrinfo(host.c_str(), port_text.c_str(), &hints, &result) != 0) {
    return std::nullopt;
  }

  sockaddr_in address{};
  if (result != nullptr && result->ai_addrlen >= sizeof(sockaddr_in)) {
    std::memcpy(&address, result->ai_addr, sizeof(sockaddr_in));
  }
  freeaddrinfo(result);

  if (address.sin_family != AF_INET) {
    return std::nullopt;
  }
  return address;
}

bool ConnectWithTimeout(SOCKET socket, const sockaddr_in& address,
                        int timeout_ms, int* last_error = nullptr) {
  if (last_error != nullptr) {
    *last_error = 0;
  }
  if (!SetBlocking(socket, false)) {
    if (last_error != nullptr) {
      *last_error = WSAGetLastError();
    }
    return false;
  }

  int res = connect(socket, reinterpret_cast<const sockaddr*>(&address),
                    sizeof(address));
  if (res == 0) {
    SetBlocking(socket, true);
    return true;
  }

  const int error = WSAGetLastError();
  if (error != WSAEWOULDBLOCK && error != WSAEINPROGRESS &&
      error != WSAEINVAL) {
    SetBlocking(socket, true);
    if (last_error != nullptr) {
      *last_error = error;
    }
    return false;
  }

  fd_set write_set;
  FD_ZERO(&write_set);
  FD_SET(socket, &write_set);
  timeval timeout{};
  timeout.tv_sec = timeout_ms / 1000;
  timeout.tv_usec = (timeout_ms % 1000) * 1000;
  res = select(0, nullptr, &write_set, nullptr, &timeout);
  if (res <= 0) {
    SetBlocking(socket, true);
    if (last_error != nullptr) {
      *last_error = res == 0 ? WSAETIMEDOUT : WSAGetLastError();
    }
    return false;
  }

  int socket_error = 0;
  int socket_error_size = sizeof(socket_error);
  getsockopt(socket, SOL_SOCKET, SO_ERROR,
             reinterpret_cast<char*>(&socket_error), &socket_error_size);
  SetBlocking(socket, true);
  if (socket_error != 0 && last_error != nullptr) {
    *last_error = socket_error;
  }
  return socket_error == 0;
}

uint16_t ReadUint16(const std::vector<uint8_t>& data, size_t offset) {
  return static_cast<uint16_t>((data[offset] << 8) | data[offset + 1]);
}

void WriteUint16(std::vector<uint8_t>& data, size_t offset, uint16_t value) {
  data[offset] = static_cast<uint8_t>((value >> 8) & 0xff);
  data[offset + 1] = static_cast<uint8_t>(value & 0xff);
}

void WriteUint32(std::vector<uint8_t>& data, size_t offset, uint32_t value) {
  data[offset] = static_cast<uint8_t>((value >> 24) & 0xff);
  data[offset + 1] = static_cast<uint8_t>((value >> 16) & 0xff);
  data[offset + 2] = static_cast<uint8_t>((value >> 8) & 0xff);
  data[offset + 3] = static_cast<uint8_t>(value & 0xff);
}

std::vector<uint8_t> BuildStunBindingRequest() {
  std::vector<uint8_t> request(20);
  WriteUint16(request, 0, 0x0001);
  WriteUint16(request, 2, 0x0000);
  WriteUint32(request, 4, kStunMagicCookie);

  std::random_device random;
  for (size_t i = 8; i < request.size(); i++) {
    request[i] = static_cast<uint8_t>(random() & 0xff);
  }
  return request;
}

std::optional<std::pair<std::string, int>> ParseStunMappedAddress(
    const std::vector<uint8_t>& header, const std::vector<uint8_t>& body) {
  size_t offset = 0;
  while (offset + 4 <= body.size()) {
    const uint16_t type = ReadUint16(body, offset);
    const uint16_t length = ReadUint16(body, offset + 2);
    const size_t value_offset = offset + 4;
    if (value_offset + length > body.size()) {
      return std::nullopt;
    }

    if ((type == 0x0001 || type == 0x0020) && length >= 8 &&
        body[value_offset + 1] == 0x01) {
      int port = ReadUint16(body, value_offset + 2);
      uint8_t address_bytes[4] = {
          body[value_offset + 4],
          body[value_offset + 5],
          body[value_offset + 6],
          body[value_offset + 7],
      };

      if (type == 0x0020) {
        port ^= static_cast<int>(kStunMagicCookie >> 16);
        for (int i = 0; i < 4; i++) {
          address_bytes[i] ^= header[4 + i];
        }
      }

      in_addr address{};
      std::memcpy(&address, address_bytes, sizeof(address_bytes));
      char buffer[INET_ADDRSTRLEN]{};
      inet_ntop(AF_INET, &address, buffer, sizeof(buffer));
      return std::make_pair(std::string(buffer), port);
    }

    offset += 4 + ((length + 3) & ~static_cast<size_t>(3));
  }
  return std::nullopt;
}

std::optional<std::pair<std::string, int>> PerformTcpStun(SOCKET socket) {
  const std::vector<uint8_t> request = BuildStunBindingRequest();
  if (!SendAll(socket, reinterpret_cast<const char*>(request.data()),
               static_cast<int>(request.size()))) {
    return std::nullopt;
  }

  std::vector<uint8_t> header(20);
  if (!RecvExact(socket, reinterpret_cast<char*>(header.data()),
                 static_cast<int>(header.size()))) {
    return std::nullopt;
  }

  const int body_size = ReadUint16(header, 2);
  if (body_size <= 0 || body_size > 4096) {
    return std::nullopt;
  }
  std::vector<uint8_t> body(body_size);
  if (!RecvExact(socket, reinterpret_cast<char*>(body.data()), body_size)) {
    return std::nullopt;
  }
  return ParseStunMappedAddress(header, body);
}

TcpProbeResult ProbeTcpStun(const std::string& stun_host, int stun_port) {
  EnsureWinsock();

  const auto stun_address = ResolveIpv4(stun_host, stun_port);
  if (!stun_address.has_value()) {
    TcpProbeResult result;
    result.ok = false;
    result.error = "resolve_stun_failed: " + stun_host;
    return result;
  }

  SOCKET stun_socket = CreateReusableTcpSocket();
  if (stun_socket == INVALID_SOCKET) {
    TcpProbeResult result;
    result.ok = false;
    result.error = LastSocketError("create_tcp_stun_socket_failed");
    return result;
  }

  int socket_error = 0;
  if (!ConnectWithTimeout(stun_socket, *stun_address, kConnectTimeoutMs,
                          &socket_error)) {
    CloseSocket(stun_socket);
    std::ostringstream stream;
    stream << "connect_tcp_stun_failed, WSA error " << socket_error;
    TcpProbeResult result;
    result.ok = false;
    result.error = stream.str();
    return result;
  }

  SetSocketTimeouts(stun_socket, kConnectTimeoutMs);
  const auto public_endpoint = PerformTcpStun(stun_socket);
  CloseSocket(stun_socket);
  if (!public_endpoint.has_value()) {
    TcpProbeResult result;
    result.ok = false;
    result.error = "tcp_stun_response_has_no_mapped_address";
    return result;
  }

  TcpProbeResult result;
  result.ok = true;
  result.public_ip = public_endpoint->first;
  result.public_port = public_endpoint->second;
  return result;
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

int GetIntArg(const flutter::EncodableMap& args, const char* name,
              int fallback = 0) {
  const auto it = args.find(flutter::EncodableValue(name));
  if (it == args.end()) {
    return fallback;
  }
  if (const auto* value = std::get_if<int>(&it->second)) {
    return *value;
  }
  if (const auto* value = std::get_if<int64_t>(&it->second)) {
    return static_cast<int>(*value);
  }
  return fallback;
}

class TcpForwardMapping {
 public:
  TcpForwardMapping(std::string rule_id, std::string stun_host, int stun_port,
                    std::string http_host, int http_port,
                    std::string target_host, int target_port,
                    int keep_alive_seconds)
      : rule_id_(std::move(rule_id)),
        stun_host_(std::move(stun_host)),
        stun_port_(stun_port),
        http_host_(std::move(http_host)),
        http_port_(http_port),
        target_host_(std::move(target_host)),
        target_port_(target_port),
        keep_alive_seconds_(keep_alive_seconds <= 0 ? kKeepAliveSeconds
                                                    : keep_alive_seconds),
        stop_flag_(std::make_shared<std::atomic_bool>(false)) {}

  ~TcpForwardMapping() { Stop(); }

  MappingStartResult Start() {
    EnsureWinsock();

    const auto http_address = ResolveIpv4(http_host_, http_port_);
    if (!http_address.has_value()) {
      return Error("resolve_http_failed: " + http_host_);
    }
    const auto stun_address = ResolveIpv4(stun_host_, stun_port_);
    if (!stun_address.has_value()) {
      return Error("resolve_stun_failed: " + stun_host_);
    }

    keep_socket_ = CreateReusableTcpSocket();
    if (keep_socket_ == INVALID_SOCKET) {
      return Error(LastSocketError("create_keepalive_socket_failed"));
    }

    sockaddr_in bind_address{};
    bind_address.sin_family = AF_INET;
    bind_address.sin_addr.s_addr = htonl(INADDR_ANY);
    bind_address.sin_port = htons(0);
    if (bind(keep_socket_, reinterpret_cast<sockaddr*>(&bind_address),
             sizeof(bind_address)) != 0) {
      return Error(LastSocketError("bind_keepalive_socket_failed"));
    }

    int socket_error = 0;
    if (!ConnectWithTimeout(keep_socket_, *http_address, kConnectTimeoutMs,
                            &socket_error)) {
      return ErrorWithCode("connect_http_keepalive_failed", socket_error);
    }

    int address_size = sizeof(local_address_);
    if (getsockname(keep_socket_, reinterpret_cast<sockaddr*>(&local_address_),
                    &address_size) != 0) {
      return Error(LastSocketError("read_local_tcp_bind_port_failed"));
    }
    local_bind_port_ = ntohs(local_address_.sin_port);

    SOCKET stun_socket = CreateReusableTcpSocket();
    if (stun_socket == INVALID_SOCKET) {
      return Error(LastSocketError("create_tcp_stun_socket_failed"));
    }
    if (bind(stun_socket, reinterpret_cast<sockaddr*>(&local_address_),
             sizeof(local_address_)) != 0) {
      CloseSocket(stun_socket);
      return Error(LastSocketError("reuse_local_tcp_port_for_stun_failed"));
    }
    if (!ConnectWithTimeout(stun_socket, *stun_address, kConnectTimeoutMs,
                            &socket_error)) {
      CloseSocket(stun_socket);
      return ErrorWithCode("connect_tcp_stun_failed", socket_error);
    }
    SetSocketTimeouts(stun_socket, kConnectTimeoutMs);

    const auto public_endpoint = PerformTcpStun(stun_socket);
    CloseSocket(stun_socket);
    if (!public_endpoint.has_value()) {
      return Error("tcp_stun_response_has_no_mapped_address");
    }

    listen_socket_ = CreateReusableTcpSocket();
    if (listen_socket_ == INVALID_SOCKET) {
      return Error(LastSocketError("create_tcp_forward_listener_failed"));
    }
    if (bind(listen_socket_, reinterpret_cast<sockaddr*>(&local_address_),
             sizeof(local_address_)) != 0) {
      return Error(LastSocketError("bind_tcp_forward_listener_failed"));
    }
    if (listen(listen_socket_, SOMAXCONN) != 0) {
      return Error(LastSocketError("listen_tcp_forward_port_failed"));
    }

    keep_thread_ = std::thread(&TcpForwardMapping::KeepAliveLoop, this);
    accept_thread_ = std::thread(&TcpForwardMapping::AcceptLoop, this);

    MappingStartResult result;
    result.ok = true;
    result.public_ip = public_endpoint->first;
    result.public_port = public_endpoint->second;
    result.local_bind_port = local_bind_port_;
    return result;
  }

  void Stop() {
    bool expected = false;
    if (!stop_flag_->compare_exchange_strong(expected, true)) {
      return;
    }

    CloseSocket(listen_socket_);
    CloseSocket(keep_socket_);
    if (accept_thread_.joinable()) {
      accept_thread_.join();
    }
    if (keep_thread_.joinable()) {
      keep_thread_.join();
    }
  }

 private:
  MappingStartResult Error(const std::string& message) {
    Stop();
    MappingStartResult result;
    result.ok = false;
    result.error = message;
    return result;
  }

  MappingStartResult ErrorWithCode(const std::string& message, int error_code) {
    std::ostringstream stream;
    stream << message << ", WSA error " << error_code;
    return Error(stream.str());
  }

  void KeepAliveLoop() {
    std::string request = "HEAD / HTTP/1.1\r\nHost: " + http_host_ +
                          "\r\nConnection: keep-alive\r\n\r\n";
    timeval timeout{};
    timeout.tv_sec = 2;
    timeout.tv_usec = 0;
    setsockopt(keep_socket_, SOL_SOCKET, SO_RCVTIMEO,
               reinterpret_cast<const char*>(&timeout), sizeof(timeout));

    while (!stop_flag_->load()) {
      if (!SendAll(keep_socket_, request.c_str(),
                   static_cast<int>(request.size()))) {
        break;
      }

      char buffer[4096];
      recv(keep_socket_, buffer, sizeof(buffer), 0);

      for (int i = 0; i < keep_alive_seconds_ * 10 && !stop_flag_->load();
           i++) {
        Sleep(100);
      }
    }
    stop_flag_->store(true);
    CloseSocket(keep_socket_);
    CloseSocket(listen_socket_);
  }

  void AcceptLoop() {
    while (!stop_flag_->load()) {
      SOCKET client = accept(listen_socket_, nullptr, nullptr);
      if (client == INVALID_SOCKET) {
        if (!stop_flag_->load()) {
          stop_flag_->store(true);
        }
        break;
      }
      auto stop_flag = stop_flag_;
      const std::string target_host = target_host_;
      const int target_port = target_port_;
      std::thread([client, stop_flag, target_host, target_port] {
        HandleClient(client, stop_flag, target_host, target_port);
      }).detach();
    }
  }

  static void HandleClient(SOCKET client,
                           std::shared_ptr<std::atomic_bool> stop_flag,
                           const std::string& target_host, int target_port) {
    SOCKET target = CreateReusableTcpSocket();
    if (target == INVALID_SOCKET) {
      CloseSocket(client);
      return;
    }
    const auto target_address = ResolveIpv4(target_host, target_port);
    if (!target_address.has_value() ||
        !ConnectWithTimeout(target, *target_address, kConnectTimeoutMs)) {
      CloseSocket(client);
      CloseSocket(target);
      return;
    }

    char buffer[8192];
    while (!stop_flag->load()) {
      fd_set read_set;
      FD_ZERO(&read_set);
      FD_SET(client, &read_set);
      FD_SET(target, &read_set);
      timeval timeout{};
      timeout.tv_sec = 1;
      timeout.tv_usec = 0;
      int res = select(0, &read_set, nullptr, nullptr, &timeout);
      if (res <= 0) {
        continue;
      }
      if (FD_ISSET(client, &read_set)) {
        int received = recv(client, buffer, sizeof(buffer), 0);
        if (received <= 0 || !SendAll(target, buffer, received)) {
          break;
        }
      }
      if (FD_ISSET(target, &read_set)) {
        int received = recv(target, buffer, sizeof(buffer), 0);
        if (received <= 0 || !SendAll(client, buffer, received)) {
          break;
        }
      }
    }
    CloseSocket(client);
    CloseSocket(target);
  }

  std::string rule_id_;
  std::string stun_host_;
  int stun_port_;
  std::string http_host_;
  int http_port_;
  std::string target_host_;
  int target_port_;
  int keep_alive_seconds_;
  int local_bind_port_ = 0;
  sockaddr_in local_address_{};
  SOCKET keep_socket_ = INVALID_SOCKET;
  SOCKET listen_socket_ = INVALID_SOCKET;
  std::thread keep_thread_;
  std::thread accept_thread_;
  std::shared_ptr<std::atomic_bool> stop_flag_;
};

}  // namespace

class NatTraversalChannel::Impl {
 public:
  explicit Impl(flutter::BinaryMessenger* messenger)
      : channel_(std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
            messenger, "personal_toolbox/nat_traversal",
            &flutter::StandardMethodCodec::GetInstance())) {
    channel_->SetMethodCallHandler(
        [this](const flutter::MethodCall<flutter::EncodableValue>& call,
               std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
                   result) { HandleMethodCall(call, std::move(result)); });
  }

  ~Impl() {
    shutting_down_.store(true);
    channel_->SetMethodCallHandler(nullptr);
    {
      std::lock_guard<std::mutex> lock(mutex_);
      stop_all_generation_++;
    }
    StopAllMappings();
    JoinWorkers();
    StopAllMappings();
  }

 private:
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
    if (call.method_name() == "startTcpForward") {
      StartTcpForward(call, std::move(result));
      return;
    }
    if (call.method_name() == "probeTcpStun") {
      ProbeTcpStun(call, std::move(result));
      return;
    }
    if (call.method_name() == "stopTcpForward") {
      StopTcpForward(call, std::move(result));
      return;
    }
    if (call.method_name() == "stopAllTcpForward") {
      StopAllTcpForward(std::move(result));
      return;
    }
    result->NotImplemented();
  }

  void StartTcpForward(
      const flutter::MethodCall<flutter::EncodableValue>& call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
    const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
    if (args == nullptr) {
      result->Error("bad_args", "start_tcp_forward_missing_args");
      return;
    }

    const std::string rule_id = GetStringArg(*args, "ruleId");
    if (rule_id.empty()) {
      result->Error("bad_args", "start_tcp_forward_missing_rule_id");
      return;
    }

    if (shutting_down_.load()) {
      result->Error("stopped", "nat_traversal_channel_stopped");
      return;
    }

    const std::string stun_host = GetStringArg(*args, "stunHost");
    const int stun_port = GetIntArg(*args, "stunPort", 3478);
    const std::string http_host = GetStringArg(*args, "httpHost");
    const int http_port = GetIntArg(*args, "httpPort", 80);
    const std::string target_host = GetStringArg(*args, "targetHost");
    const int target_port = GetIntArg(*args, "targetPort", 0);
    const int keep_alive_seconds =
        GetIntArg(*args, "keepAliveSeconds", kKeepAliveSeconds);

    uint64_t rule_version = 0;
    uint64_t stop_all_generation = 0;
    {
      std::lock_guard<std::mutex> lock(mutex_);
      rule_version = ++rule_versions_[rule_id];
      stop_all_generation = stop_all_generation_;
    }

    RunWorker(std::thread(
        [this, rule_id, stun_host, stun_port, http_host, http_port, target_host,
         target_port, keep_alive_seconds, rule_version, stop_all_generation,
         result = std::move(result)]() mutable {
          StopRuleInternal(rule_id);

          auto mapping = std::make_unique<TcpForwardMapping>(
              rule_id, stun_host, stun_port, http_host, http_port, target_host,
              target_port, keep_alive_seconds);

          MappingStartResult start = mapping->Start();
          if (!start.ok) {
            result->Error("start_failed", start.error);
            return;
          }

          bool cancelled = false;
          {
            std::lock_guard<std::mutex> lock(mutex_);
            cancelled = shutting_down_.load() ||
                        stop_all_generation_ != stop_all_generation ||
                        rule_versions_[rule_id] != rule_version;
            if (!cancelled) {
              mappings_[rule_id] = std::move(mapping);
            }
          }

          if (cancelled) {
            if (mapping) {
              mapping->Stop();
            }
            result->Error("start_cancelled", "tcp_forward_start_cancelled");
            return;
          }

          flutter::EncodableMap value;
          value[flutter::EncodableValue("publicIp")] =
              flutter::EncodableValue(start.public_ip);
          value[flutter::EncodableValue("publicPort")] =
              flutter::EncodableValue(start.public_port);
          value[flutter::EncodableValue("localBindPort")] =
              flutter::EncodableValue(start.local_bind_port);
          result->Success(flutter::EncodableValue(value));
        }));
  }

  void ProbeTcpStun(
      const flutter::MethodCall<flutter::EncodableValue>& call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
    const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
    if (args == nullptr) {
      result->Error("bad_args", "probe_tcp_stun_missing_args");
      return;
    }

    const std::string stun_host = GetStringArg(*args, "stunHost");
    const int stun_port = GetIntArg(*args, "stunPort", 3478);
    RunWorker(std::thread(
        [stun_host, stun_port, result = std::move(result)]() mutable {
          TcpProbeResult probe = ::ProbeTcpStun(stun_host, stun_port);
          if (!probe.ok) {
            result->Error("probe_failed", probe.error);
            return;
          }

          flutter::EncodableMap value;
          value[flutter::EncodableValue("publicIp")] =
              flutter::EncodableValue(probe.public_ip);
          value[flutter::EncodableValue("publicPort")] =
              flutter::EncodableValue(probe.public_port);
          result->Success(flutter::EncodableValue(value));
        }));
  }

  void StopTcpForward(
      const flutter::MethodCall<flutter::EncodableValue>& call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
    const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
    if (args == nullptr) {
      result->Error("bad_args", "stop_tcp_forward_missing_args");
      return;
    }
    const std::string rule_id = GetStringArg(*args, "ruleId");
    {
      std::lock_guard<std::mutex> lock(mutex_);
      rule_versions_[rule_id]++;
    }
    RunWorker(std::thread([this, rule_id, result = std::move(result)]() mutable {
      StopRuleInternal(rule_id);
      result->Success(flutter::EncodableValue(true));
    }));
  }

  void StopAllTcpForward(
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
    {
      std::lock_guard<std::mutex> lock(mutex_);
      stop_all_generation_++;
    }
    RunWorker(std::thread([this, result = std::move(result)]() mutable {
      StopAllMappings();
      result->Success(flutter::EncodableValue(true));
    }));
  }

  void StopRuleInternal(const std::string& rule_id) {
    std::unique_ptr<TcpForwardMapping> mapping;
    {
      std::lock_guard<std::mutex> lock(mutex_);
      auto it = mappings_.find(rule_id);
      if (it == mappings_.end()) {
        return;
      }
      mapping = std::move(it->second);
      mappings_.erase(it);
    }
    mapping->Stop();
  }

  void StopAllMappings() {
    std::map<std::string, std::unique_ptr<TcpForwardMapping>> mappings;
    {
      std::lock_guard<std::mutex> lock(mutex_);
      mappings.swap(mappings_);
    }
    for (auto& entry : mappings) {
      entry.second->Stop();
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
      if (worker.joinable()) {
        worker.join();
      }
    }
  }

  std::mutex mutex_;
  std::map<std::string, std::unique_ptr<TcpForwardMapping>> mappings_;
  std::map<std::string, uint64_t> rule_versions_;
  uint64_t stop_all_generation_ = 0;
  std::atomic_bool shutting_down_{false};
  std::mutex workers_mutex_;
  std::vector<std::thread> workers_;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
};

NatTraversalChannel::NatTraversalChannel(flutter::BinaryMessenger* messenger)
    : impl_(std::make_unique<Impl>(messenger)) {}

NatTraversalChannel::~NatTraversalChannel() = default;
