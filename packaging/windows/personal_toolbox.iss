#define AppName "personal_toolbox"

#ifndef AppArch
  #define AppArch "x64"
#endif

#ifndef AppVersion
  #define AppVersion "0.0.0"
#endif

#ifndef AppBuild
  #define AppBuild "0"
#endif

#ifndef SourceDir
  #error "SourceDir is required"
#endif

#ifndef OutputDir
  #error "OutputDir is required"
#endif

[Setup]
AppId=personal_toolbox-{#AppArch}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion} ({#AppArch})
AppPublisher=w847
DefaultDirName={autopf}\{#AppName}\{#AppArch}
DefaultGroupName={#AppName} ({#AppArch})
OutputDir={#OutputDir}
OutputBaseFilename={#AppName}-windows-{#AppArch}-setup
Compression=lzma2
SolidCompression=yes
ArchitecturesAllowed={#AppArch}
ArchitecturesInstallIn64BitMode={#AppArch}
DisableProgramGroupPage=yes
PrivilegesRequired=admin
WizardStyle=modern
CloseApplications=no
UsePreviousAppDir=no

[Tasks]
Name: "desktopicon"; Description: "创建桌面图标"; GroupDescription: "附加任务"

[Files]
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#AppName} ({#AppArch})"; Filename: "{app}\personal_toolbox.exe"
Name: "{autodesktop}\{#AppName} ({#AppArch})"; Filename: "{app}\personal_toolbox.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\personal_toolbox.exe"; Description: "启动 {#AppName}"; Flags: nowait postinstall skipifsilent
