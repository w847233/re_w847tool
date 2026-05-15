import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

const dnsCandidates = <DnsCandidate>[
  DnsCandidate(
    id: 'cloudflare',
    name: 'Cloudflare 1.1.1.1',
    region: '全球 Anycast',
    ipv4Servers: ['1.1.1.1', '1.0.0.1'],
    dohEndpoint: 'https://cloudflare-dns.com/dns-query',
    sourceLabel: 'Cloudflare Docs',
    isDomestic: false,
  ),
  DnsCandidate(
    id: 'google',
    name: 'Google Public DNS',
    region: '全球 Anycast',
    ipv4Servers: ['8.8.8.8', '8.8.4.4'],
    dohEndpoint: 'https://dns.google/resolve',
    sourceLabel: 'Google Public DNS Docs',
    isDomestic: false,
  ),
  DnsCandidate(
    id: 'adguard',
    name: 'AdGuard DNS',
    region: '全球 Anycast',
    ipv4Servers: ['94.140.14.14', '94.140.15.15'],
    dohEndpoint: 'https://dns.adguard-dns.com/resolve',
    sourceLabel: 'AdGuard DNS',
    isDomestic: false,
  ),
  DnsCandidate(
    id: 'alidns',
    name: 'Alibaba DNS',
    region: '中国大陆友好',
    ipv4Servers: ['223.5.5.5', '223.6.6.6'],
    dohEndpoint: 'https://dns.alidns.com/resolve',
    sourceLabel: 'Alibaba Cloud DNS',
    isDomestic: true,
  ),
  DnsCandidate(
    id: 'dnspod',
    name: 'DNSPod Public DNS',
    region: '中国大陆友好',
    ipv4Servers: ['119.29.29.29', '119.28.28.28'],
    dohEndpoint: 'https://doh.pub/dns-query',
    sourceLabel: 'DNSPod Public DNS',
    isDomestic: true,
  ),
  DnsCandidate(
    id: 'opendns',
    name: 'Cisco OpenDNS',
    region: '全球 Anycast',
    ipv4Servers: ['208.67.222.222', '208.67.220.220'],
    sourceLabel: 'OpenDNS Setup Guide',
    isDomestic: false,
  ),
];

const dnsBenchmarkDomains = <DnsBenchmarkDomain>[
  DnsBenchmarkDomain(domain: 'baidu.com', label: '百度', isDomestic: true),
  DnsBenchmarkDomain(domain: 'qq.com', label: '腾讯', isDomestic: true),
  DnsBenchmarkDomain(domain: 'taobao.com', label: '淘宝', isDomestic: true),
  DnsBenchmarkDomain(domain: 'bilibili.com', label: '哔哩哔哩', isDomestic: true),
  DnsBenchmarkDomain(
    domain: 'example.com',
    label: 'Example',
    isDomestic: false,
  ),
  DnsBenchmarkDomain(domain: 'github.com', label: 'GitHub', isDomestic: false),
  DnsBenchmarkDomain(
    domain: 'cloudflare.com',
    label: 'Cloudflare',
    isDomestic: false,
  ),
  DnsBenchmarkDomain(
    domain: 'microsoft.com',
    label: 'Microsoft',
    isDomestic: false,
  ),
];

class DnsToolService {
  DnsToolService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<DnsLeakReport> detectLeak() async {
    final checkedAt = DateTime.now();
    final publicIpFuture = _fetchPublicIp();
    final resolverIpFuture = _lookupResolverIp();

    final publicIp = await publicIpFuture;
    final resolverIp = await resolverIpFuture;
    final publicGeoFuture = publicIp == null ? null : _fetchIpGeo(publicIp);
    final resolverGeoFuture = resolverIp == null
        ? null
        : _fetchIpGeo(resolverIp);

    final publicGeo = await publicGeoFuture;
    final resolverGeo = await resolverGeoFuture;
    final risk = _classifyLeakRisk(publicGeo, resolverGeo, resolverIp);

    return DnsLeakReport(
      checkedAt: checkedAt,
      publicIp: publicIp,
      resolverIp: resolverIp,
      publicGeo: publicGeo,
      resolverGeo: resolverGeo,
      risk: risk,
    );
  }

  Future<List<DnsBenchmarkResult>> benchmark({
    bool domesticOnly = false,
  }) async {
    final rawResults = <DnsBenchmarkResult>[];
    final answersByDomain = <String, List<Set<String>>>{};
    final candidates = domesticOnly
        ? dnsCandidates.where((candidate) => candidate.isDomestic)
        : dnsCandidates;
    final domains = domesticOnly
        ? dnsBenchmarkDomains.where((domain) => domain.isDomestic).toList()
        : dnsBenchmarkDomains;

    for (final candidate in candidates) {
      if (!candidate.canBenchmark) {
        rawResults.add(
          DnsBenchmarkResult._(
            candidate: candidate,
            sampleCount: domains.length,
            successCount: 0,
            averageLatencyMs: null,
            accuracyScore: 0,
            matchedDomains: 0,
            error: '该服务未提供当前工具可直接调用的 JSON DoH 测试端点',
          ),
        );
        continue;
      }

      final samples = <_DnsQuerySample>[];
      for (final domain in domains) {
        final sample = await _queryDoh(candidate, domain.domain);
        samples.add(sample);
        if (sample.answers.isNotEmpty) {
          answersByDomain
              .putIfAbsent(domain.domain, () => [])
              .add(sample.answers);
        }
      }

      rawResults.add(
        DnsBenchmarkResult._fromSamples(candidate: candidate, samples: samples),
      );
    }

    final consensusByDomain = {
      for (final entry in answersByDomain.entries)
        entry.key: _consensusAnswers(entry.value),
    };

    return [
      for (final result in rawResults)
        result.withAccuracy(
          matchedDomains: result._samples.where((sample) {
            final consensus = consensusByDomain[sample.domain];
            return consensus != null &&
                consensus.isNotEmpty &&
                _setEquals(sample.answers, consensus);
          }).length,
          sampleCount: domains.length,
        ),
    ];
  }

  Future<List<DnsAdapter>> listAdapters() async {
    if (!Platform.isWindows) {
      return const [];
    }

    const script = '''
\$adapters = Get-NetAdapter |
  Where-Object { \$_.Status -eq 'Up' -and \$_.HardwareInterface } |
  Sort-Object -Property ifIndex |
  Select-Object -Property Name, InterfaceDescription, ifIndex
\$adapters | ConvertTo-Json -Compress
''';
    final result = await _runPowerShell(script);
    if (result.exitCode != 0 || result.stdout.toString().trim().isEmpty) {
      return const [];
    }
    final decoded = jsonDecode(result.stdout.toString());
    final list = decoded is List ? decoded : [decoded];
    return [
      for (final item in list)
        if (item is Map<String, dynamic>)
          DnsAdapter(
            name: item['Name']?.toString() ?? '',
            description: item['InterfaceDescription']?.toString() ?? '',
            interfaceIndex:
                int.tryParse(item['ifIndex']?.toString() ?? '') ?? 0,
          ),
    ].where((adapter) => adapter.name.isNotEmpty).toList();
  }

  Future<void> setDnsServers({
    required String adapterName,
    required List<String> servers,
  }) async {
    if (!Platform.isWindows) {
      throw const DnsToolException('当前版本只支持在 Windows 上直接设置 DNS。');
    }
    if (servers.isEmpty) {
      throw const DnsToolException('没有可写入的 DNS 服务器地址。');
    }

    final quotedServers = servers.map((server) => "'${_escapePs(server)}'");
    final script =
        "Set-DnsClientServerAddress -InterfaceAlias '${_escapePs(adapterName)}' "
        "-ServerAddresses @(${quotedServers.join(',')}) -ErrorAction Stop";
    final result = await _runPowerShell(script);
    if (result.exitCode != 0) {
      throw DnsToolException(_formatPowerShellError(result));
    }
  }

  Future<void> resetDnsServers({required String adapterName}) async {
    if (!Platform.isWindows) {
      throw const DnsToolException('当前版本只支持在 Windows 上恢复自动 DNS。');
    }

    final script =
        "Set-DnsClientServerAddress -InterfaceAlias '${_escapePs(adapterName)}' "
        '-ResetServerAddresses -ErrorAction Stop';
    final result = await _runPowerShell(script);
    if (result.exitCode != 0) {
      throw DnsToolException(_formatPowerShellError(result));
    }
  }

  void dispose() {
    _client.close();
  }

  Future<String?> _fetchPublicIp() async {
    final uri = Uri.parse('https://api64.ipify.org?format=json');
    final response = await _client.get(uri).timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) {
      return null;
    }
    final decoded = jsonDecode(response.body);
    return decoded is Map ? decoded['ip']?.toString() : null;
  }

  Future<String?> _lookupResolverIp() async {
    final addresses = await InternetAddress.lookup(
      'whoami.akamai.net',
      type: InternetAddressType.IPv4,
    ).timeout(const Duration(seconds: 8));
    return addresses.isEmpty ? null : addresses.first.address;
  }

  Future<IpGeo?> _fetchIpGeo(String ip) async {
    final uri = Uri.parse('https://ipwho.is/$ip');
    try {
      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        return null;
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic> || decoded['success'] == false) {
        return null;
      }
      final connection = decoded['connection'];
      return IpGeo(
        ip: ip,
        country: decoded['country']?.toString(),
        region: decoded['region']?.toString(),
        city: decoded['city']?.toString(),
        isp: connection is Map ? connection['isp']?.toString() : null,
        org: connection is Map ? connection['org']?.toString() : null,
        asn: connection is Map ? connection['asn']?.toString() : null,
      );
    } catch (_) {
      return null;
    }
  }

  Future<_DnsQuerySample> _queryDoh(
    DnsCandidate candidate,
    String domain,
  ) async {
    final stopwatch = Stopwatch()..start();
    try {
      final uri = Uri.parse(
        candidate.dohEndpoint!,
      ).replace(queryParameters: {'name': domain, 'type': 'A'});
      final response = await _client
          .get(uri, headers: const {'accept': 'application/dns-json'})
          .timeout(const Duration(seconds: 8));
      stopwatch.stop();
      if (response.statusCode != 200) {
        return _DnsQuerySample(
          domain: domain,
          latencyMs: stopwatch.elapsedMilliseconds,
          answers: const {},
          error: 'HTTP ${response.statusCode}',
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return _DnsQuerySample(
          domain: domain,
          latencyMs: stopwatch.elapsedMilliseconds,
          answers: const {},
          error: '响应格式不是 JSON 对象',
        );
      }
      if (decoded['Status'] != 0) {
        return _DnsQuerySample(
          domain: domain,
          latencyMs: stopwatch.elapsedMilliseconds,
          answers: const {},
          error: 'DNS 状态码 ${decoded['Status']}',
        );
      }

      return _DnsQuerySample(
        domain: domain,
        latencyMs: stopwatch.elapsedMilliseconds,
        answers: _extractARecords(decoded['Answer']),
      );
    } catch (error) {
      stopwatch.stop();
      return _DnsQuerySample(
        domain: domain,
        latencyMs: stopwatch.elapsedMilliseconds,
        answers: const {},
        error: error.toString(),
      );
    }
  }

  Set<String> _extractARecords(Object? answer) {
    if (answer is! List) {
      return const {};
    }
    return {
      for (final item in answer)
        if (item is Map &&
            item['type'] == 1 &&
            item['data'] is String &&
            InternetAddress.tryParse(item['data'] as String)?.type ==
                InternetAddressType.IPv4)
          item['data'] as String,
    };
  }

  DnsLeakRisk _classifyLeakRisk(
    IpGeo? publicGeo,
    IpGeo? resolverGeo,
    String? resolverIp,
  ) {
    if (resolverIp == null) {
      return DnsLeakRisk.unknown;
    }
    if (_isReservedIp(resolverIp)) {
      return DnsLeakRisk.unknown;
    }
    final publicCountry = publicGeo?.country;
    final resolverCountry = resolverGeo?.country;
    if (publicCountry == null || resolverCountry == null) {
      return DnsLeakRisk.unknown;
    }
    return publicCountry == resolverCountry
        ? DnsLeakRisk.low
        : DnsLeakRisk.medium;
  }

  bool _isReservedIp(String ip) {
    final parts = ip.split('.').map(int.tryParse).toList();
    if (parts.length != 4 || parts.any((part) => part == null)) {
      return false;
    }
    final a = parts[0]!;
    final b = parts[1]!;
    return a == 10 ||
        a == 127 ||
        (a == 172 && b >= 16 && b <= 31) ||
        (a == 192 && b == 168) ||
        (a == 198 && (b == 18 || b == 19));
  }

  Set<String> _consensusAnswers(List<Set<String>> answers) {
    final counts = <String, int>{};
    for (final answerSet in answers) {
      final key = (answerSet.toList()..sort()).join(',');
      counts[key] = (counts[key] ?? 0) + 1;
    }
    if (counts.isEmpty) {
      return const {};
    }
    final winner = counts.entries.reduce(
      (best, entry) => entry.value > best.value ? entry : best,
    );
    return winner.key.isEmpty ? const {} : winner.key.split(',').toSet();
  }

  bool _setEquals(Set<String> left, Set<String> right) {
    return left.length == right.length && left.containsAll(right);
  }

  Future<ProcessResult> _runPowerShell(String script) {
    return Process.run('powershell.exe', [
      '-NoProfile',
      '-ExecutionPolicy',
      'Bypass',
      '-Command',
      script,
    ], runInShell: false);
  }

  String _escapePs(String value) {
    return value.replaceAll("'", "''");
  }

  String _formatPowerShellError(ProcessResult result) {
    final stderr = result.stderr.toString().trim();
    if (stderr.isEmpty) {
      return 'DNS 设置命令失败，退出码 ${result.exitCode}。';
    }
    if (stderr.contains('Access is denied') || stderr.contains('拒绝访问')) {
      return '权限不足：请以管理员身份运行应用后再设置 DNS。';
    }
    return stderr;
  }
}

class DnsCandidate {
  const DnsCandidate({
    required this.id,
    required this.name,
    required this.region,
    required this.ipv4Servers,
    required this.sourceLabel,
    required this.isDomestic,
    this.dohEndpoint,
  });

  final String id;
  final String name;
  final String region;
  final List<String> ipv4Servers;
  final String sourceLabel;
  final bool isDomestic;
  final String? dohEndpoint;

  bool get canBenchmark => dohEndpoint != null;
}

class DnsBenchmarkDomain {
  const DnsBenchmarkDomain({
    required this.domain,
    required this.label,
    required this.isDomestic,
  });

  final String domain;
  final String label;
  final bool isDomestic;
}

class DnsBenchmarkResult {
  const DnsBenchmarkResult._({
    required this.candidate,
    required this.sampleCount,
    required this.successCount,
    required this.averageLatencyMs,
    required this.accuracyScore,
    required this.matchedDomains,
    this.error,
    List<_DnsQuerySample> samples = const [],
  }) : _samples = samples;

  factory DnsBenchmarkResult._fromSamples({
    required DnsCandidate candidate,
    required List<_DnsQuerySample> samples,
  }) {
    final successful = samples.where((sample) => sample.answers.isNotEmpty);
    final averageLatency = successful.isEmpty
        ? null
        : successful
                  .map((sample) => sample.latencyMs)
                  .reduce((sum, value) => sum + value) /
              successful.length;
    final firstError = samples
        .where((sample) => sample.error != null)
        .map((sample) => sample.error!)
        .firstOrNull;
    return DnsBenchmarkResult._(
      candidate: candidate,
      sampleCount: samples.length,
      successCount: successful.length,
      averageLatencyMs: averageLatency,
      accuracyScore: 0,
      matchedDomains: 0,
      error: successful.isEmpty ? firstError : null,
      samples: samples,
    );
  }

  final DnsCandidate candidate;
  final int sampleCount;
  final int successCount;
  final double? averageLatencyMs;
  final double accuracyScore;
  final int matchedDomains;
  final String? error;
  final List<_DnsQuerySample> _samples;

  DnsBenchmarkResult withAccuracy({
    required int matchedDomains,
    required int sampleCount,
  }) {
    return DnsBenchmarkResult._(
      candidate: candidate,
      sampleCount: this.sampleCount,
      successCount: successCount,
      averageLatencyMs: averageLatencyMs,
      accuracyScore: sampleCount == 0 ? 0 : matchedDomains / sampleCount,
      matchedDomains: matchedDomains,
      error: error,
      samples: _samples,
    );
  }
}

class DnsLeakReport {
  const DnsLeakReport({
    required this.checkedAt,
    required this.publicIp,
    required this.resolverIp,
    required this.publicGeo,
    required this.resolverGeo,
    required this.risk,
  });

  final DateTime checkedAt;
  final String? publicIp;
  final String? resolverIp;
  final IpGeo? publicGeo;
  final IpGeo? resolverGeo;
  final DnsLeakRisk risk;
}

class IpGeo {
  const IpGeo({
    required this.ip,
    this.country,
    this.region,
    this.city,
    this.isp,
    this.org,
    this.asn,
  });

  final String ip;
  final String? country;
  final String? region;
  final String? city;
  final String? isp;
  final String? org;
  final String? asn;

  String get location {
    final parts = [
      country,
      region,
      city,
    ].whereType<String>().where((part) => part.isNotEmpty);
    return parts.isEmpty ? '未知地区' : parts.join(' ');
  }

  String get network {
    final parts = [
      isp,
      org,
      asn,
    ].whereType<String>().where((part) => part.isNotEmpty);
    return parts.isEmpty ? '未知网络' : parts.join(' · ');
  }
}

class DnsAdapter {
  const DnsAdapter({
    required this.name,
    required this.description,
    required this.interfaceIndex,
  });

  final String name;
  final String description;
  final int interfaceIndex;
}

enum DnsLeakRisk { low, medium, unknown }

enum DnsOptimizeMode { latency, accuracy }

class DnsToolException implements Exception {
  const DnsToolException(this.message);

  final String message;

  @override
  String toString() => message;
}

class _DnsQuerySample {
  const _DnsQuerySample({
    required this.domain,
    required this.latencyMs,
    required this.answers,
    this.error,
  });

  final String domain;
  final int latencyMs;
  final Set<String> answers;
  final String? error;
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
