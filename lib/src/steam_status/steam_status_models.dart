enum SteamBackendPhase { starting, ready, stopped, error }

class SteamActionResult {
  const SteamActionResult({required this.success, required this.message});

  final bool success;
  final String message;
}

class SteamRemoteState {
  const SteamRemoteState({
    required this.loggedIn,
    required this.personaState,
    required this.personaStateName,
    required this.personaStateFlags,
    this.username,
    this.currentStatus,
    this.currentAppId,
    this.currentRichText,
  });

  final bool loggedIn;
  final String? username;
  final String? currentStatus;
  final int? currentAppId;
  final String? currentRichText;
  final int personaState;
  final String personaStateName;
  final int personaStateFlags;

  static const empty = SteamRemoteState(
    loggedIn: false,
    personaState: 1,
    personaStateName: 'Online',
    personaStateFlags: 0,
  );

  SteamRemoteState copyWith({
    bool? loggedIn,
    String? username,
    String? currentStatus,
    int? currentAppId,
    String? currentRichText,
    int? personaState,
    String? personaStateName,
    int? personaStateFlags,
    bool clearUsername = false,
    bool clearCurrentStatus = false,
    bool clearCurrentAppId = false,
    bool clearCurrentRichText = false,
  }) {
    return SteamRemoteState(
      loggedIn: loggedIn ?? this.loggedIn,
      username: clearUsername ? null : (username ?? this.username),
      currentStatus: clearCurrentStatus
          ? null
          : (currentStatus ?? this.currentStatus),
      currentAppId: clearCurrentAppId
          ? null
          : (currentAppId ?? this.currentAppId),
      currentRichText: clearCurrentRichText
          ? null
          : (currentRichText ?? this.currentRichText),
      personaState: personaState ?? this.personaState,
      personaStateName: personaStateName ?? this.personaStateName,
      personaStateFlags: personaStateFlags ?? this.personaStateFlags,
    );
  }
}

class SteamRichPresenceToken {
  const SteamRichPresenceToken({
    required this.token,
    required this.display,
    this.placeholders = const <String>[],
  });

  final String token;
  final String display;
  final List<String> placeholders;
}

class SteamAccount {
  const SteamAccount({required this.username});

  final String username;
}

class SteamCMServer {
  const SteamCMServer({
    required this.endpoint,
    required this.host,
    required this.port,
    required this.success,
    this.latencyMs,
    this.error,
  });

  final String endpoint;
  final String host;
  final int port;
  final bool success;
  final double? latencyMs;
  final String? error;
}

class SteamCMPreference {
  const SteamCMPreference({
    required this.enabled,
    required this.servers,
    this.lastCheckedAt,
    this.lastError,
    this.lastApplied = const <String>[],
    this.maxCount = 24,
    this.timeoutSeconds = 1.8,
  });

  final bool enabled;
  final List<SteamCMServer> servers;
  final DateTime? lastCheckedAt;
  final String? lastError;
  final List<String> lastApplied;
  final int maxCount;
  final double timeoutSeconds;

  SteamCMServer? get bestServer {
    for (final server in servers) {
      if (server.success) {
        return server;
      }
    }
    return null;
  }

  static const empty = SteamCMPreference(
    enabled: true,
    servers: <SteamCMServer>[],
  );
}

class SteamDomainIp {
  const SteamDomainIp({
    required this.address,
    required this.success,
    required this.selected,
    this.latencyMs,
    this.location,
    this.error,
  });

  final String address;
  final bool success;
  final bool selected;
  final double? latencyMs;
  final String? location;
  final String? error;
}

class SteamDomainPreference {
  const SteamDomainPreference({
    required this.domain,
    required this.label,
    required this.description,
    required this.enabled,
    required this.ips,
    this.lastResolvedAt,
    this.lastError,
    this.port = 443,
    this.selectedIps = const <String>[],
  });

  final String domain;
  final String label;
  final String description;
  final bool enabled;
  final List<SteamDomainIp> ips;
  final DateTime? lastResolvedAt;
  final String? lastError;
  final int port;
  final List<String> selectedIps;

  bool get hasSelection => selectedIps.isNotEmpty;
}

class SteamAuthPrompt {
  const SteamAuthPrompt({
    required this.title,
    required this.subtitle,
    required this.isTwoFactor,
  });

  final String title;
  final String subtitle;
  final bool isTwoFactor;
}

class SteamToolState {
  const SteamToolState({
    required this.backendPhase,
    required this.remoteState,
    required this.savedAccounts,
    this.cmPreference = SteamCMPreference.empty,
    this.domainPreferences = const <SteamDomainPreference>[],
    this.backendError,
    this.backendMessage,
    this.authPrompt,
    this.waitingForMobileApproval = false,
    this.port,
    this.shouldPromptSaveCredentials = false,
    this.loginInProgress = false,
    this.loginMessage,
  });

  final SteamBackendPhase backendPhase;
  final String? backendError;
  final String? backendMessage;
  final SteamRemoteState remoteState;
  final List<SteamAccount> savedAccounts;
  final SteamCMPreference cmPreference;
  final List<SteamDomainPreference> domainPreferences;
  final SteamAuthPrompt? authPrompt;
  final bool waitingForMobileApproval;
  final int? port;
  final bool shouldPromptSaveCredentials;
  final bool loginInProgress;
  final String? loginMessage;

  bool get backendReady => backendPhase == SteamBackendPhase.ready;

  static const initial = SteamToolState(
    backendPhase: SteamBackendPhase.starting,
    remoteState: SteamRemoteState.empty,
    savedAccounts: <SteamAccount>[],
  );

  SteamToolState copyWith({
    SteamBackendPhase? backendPhase,
    String? backendError,
    String? backendMessage,
    SteamRemoteState? remoteState,
    List<SteamAccount>? savedAccounts,
    SteamCMPreference? cmPreference,
    List<SteamDomainPreference>? domainPreferences,
    SteamAuthPrompt? authPrompt,
    bool clearBackendError = false,
    bool clearBackendMessage = false,
    bool clearAuthPrompt = false,
    bool? waitingForMobileApproval,
    int? port,
    bool clearPort = false,
    bool? shouldPromptSaveCredentials,
    bool? loginInProgress,
    String? loginMessage,
    bool clearLoginMessage = false,
  }) {
    return SteamToolState(
      backendPhase: backendPhase ?? this.backendPhase,
      backendError: clearBackendError
          ? null
          : (backendError ?? this.backendError),
      backendMessage: clearBackendMessage
          ? null
          : (backendMessage ?? this.backendMessage),
      remoteState: remoteState ?? this.remoteState,
      savedAccounts: savedAccounts ?? this.savedAccounts,
      cmPreference: cmPreference ?? this.cmPreference,
      domainPreferences: domainPreferences ?? this.domainPreferences,
      authPrompt: clearAuthPrompt ? null : (authPrompt ?? this.authPrompt),
      waitingForMobileApproval:
          waitingForMobileApproval ?? this.waitingForMobileApproval,
      port: clearPort ? null : (port ?? this.port),
      shouldPromptSaveCredentials:
          shouldPromptSaveCredentials ?? this.shouldPromptSaveCredentials,
      loginInProgress: loginInProgress ?? this.loginInProgress,
      loginMessage: clearLoginMessage
          ? null
          : (loginMessage ?? this.loginMessage),
    );
  }
}

class SteamPersonaOption {
  const SteamPersonaOption({required this.value, required this.label});

  final int value;
  final String label;
}

class SteamPersonaFlagOption {
  const SteamPersonaFlagOption({
    required this.value,
    required this.label,
    required this.description,
    required this.group,
  });

  final int value;
  final String label;
  final String description;
  final String group;
}

const steamPersonaOptions = <SteamPersonaOption>[
  SteamPersonaOption(value: 1, label: '在线'),
  SteamPersonaOption(value: 2, label: '忙碌'),
  SteamPersonaOption(value: 3, label: '离开'),
  SteamPersonaOption(value: 4, label: '打盹'),
  SteamPersonaOption(value: 5, label: '找交易'),
  SteamPersonaOption(value: 6, label: '找伙伴'),
  SteamPersonaOption(value: 7, label: '隐身'),
];

const steamPersonaClientTypeFlagOptions = <SteamPersonaFlagOption>[
  SteamPersonaFlagOption(
    value: 256,
    label: 'Web',
    description: '网页端/浏览器聊天',
    group: '客户端类型',
  ),
  SteamPersonaFlagOption(
    value: 512,
    label: 'Mobile',
    description: 'Steam 手机 App',
    group: '客户端类型',
  ),
  SteamPersonaFlagOption(
    value: 1024,
    label: 'Big Picture',
    description: '大屏/手柄模式',
    group: '客户端类型',
  ),
  SteamPersonaFlagOption(
    value: 2048,
    label: 'VR',
    description: 'SteamVR / VR 客户端',
    group: '客户端类型',
  ),
  SteamPersonaFlagOption(
    value: 4096,
    label: 'Gamepad',
    description: '手柄启动倾向',
    group: '客户端类型',
  ),
  SteamPersonaFlagOption(
    value: 8192,
    label: 'Compat Tool',
    description: '兼容工具，例如 Proton',
    group: '客户端类型',
  ),
];

const steamPersonaOtherFlagOptions = <SteamPersonaFlagOption>[
  SteamPersonaFlagOption(
    value: 1,
    label: 'Rich Presence',
    description: '有详细游戏状态',
    group: '其它标记',
  ),
  SteamPersonaFlagOption(
    value: 2,
    label: 'Joinable Game',
    description: '游戏可加入',
    group: '其它标记',
  ),
  SteamPersonaFlagOption(
    value: 4,
    label: 'Golden',
    description: '金色资料状态',
    group: '其它标记',
  ),
  SteamPersonaFlagOption(
    value: 8,
    label: 'Remote Play Together',
    description: '远程同乐',
    group: '其它标记',
  ),
];

const steamPersonaFlagOptions = <SteamPersonaFlagOption>[
  ...steamPersonaClientTypeFlagOptions,
  ...steamPersonaOtherFlagOptions,
];
