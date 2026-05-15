param(
    [switch]$SkipBuild,
    [switch]$NoLaunch,
    [switch]$SkipRestrictedCapabilities,
    [switch]$DryRun,
    [switch]$NoElevate
)

$ErrorActionPreference = "Stop"
if ($null -eq (Get-PSDrive -Name Cert -ErrorAction SilentlyContinue)) {
    $securityModule = Join-Path $PSHOME "Modules\Microsoft.PowerShell.Security\Microsoft.PowerShell.Security.psd1"
    Import-Module $securityModule -ErrorAction Stop
}

$ProjectRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$FlutterBin = "C:\tmp\flutter\bin\flutter.bat"
if (-not (Test-Path -LiteralPath $FlutterBin)) {
    $FlutterBin = "flutter"
}

$PackageName = "com.w847.personaltoolbox.debug"
$Publisher = "CN=w847"
$ApplicationId = "PersonalToolbox"
$DisplayName = "Personal Toolbox Debug"
$DebugOutput = Join-Path $ProjectRoot "build\windows\x64\runner\Debug"
$PackageRoot = Join-Path $ProjectRoot "build\windows_debug_msix"
$ManifestRoot = Join-Path $PackageRoot "identity"
$ManifestPath = Join-Path $ManifestRoot "AppxManifest.xml"
$ExeManifestPath = Join-Path $PackageRoot "personal_toolbox_debug.exe.manifest"
$PackagePath = Join-Path $PackageRoot "personal_toolbox_debug.msix"

function Test-IsAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]$identity
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Find-WindowsSdkTool {
    param([Parameter(Mandatory = $true)][string]$Name)

    $kitRoot = Join-Path ${env:ProgramFiles(x86)} "Windows Kits\10"
    $matches = @()
    if (Test-Path -LiteralPath $kitRoot) {
        $escapedName = [regex]::Escape($Name)
        $x64ToolPattern = "\\x64\\" + $escapedName + '$'
        $matches += Get-ChildItem -LiteralPath (Join-Path $kitRoot "bin") -Recurse -Filter $Name -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -match $x64ToolPattern } |
            Sort-Object FullName -Descending
        $matches += Get-ChildItem -LiteralPath (Join-Path $kitRoot "App Certification Kit") -Filter $Name -ErrorAction SilentlyContinue
    }

    $tool = $matches | Select-Object -First 1
    if ($null -eq $tool) {
        throw "Could not find $Name. Install the Windows 10/11 SDK and retry."
    }
    return $tool.FullName
}

function Ensure-DebugCertificate {
    $cert = Get-ChildItem Cert:\CurrentUser\My |
        Where-Object { $_.Subject -eq $Publisher -and $_.HasPrivateKey -and $_.NotAfter -gt (Get-Date) } |
        Sort-Object NotAfter -Descending |
        Select-Object -First 1

    if ($null -eq $cert) {
        $certArgs = @{
            Type = "Custom"
            Subject = $Publisher
            FriendlyName = "Personal Toolbox Debug MSIX"
            CertStoreLocation = "Cert:\CurrentUser\My"
            KeyAlgorithm = "RSA"
            KeyLength = 2048
            KeyUsage = "DigitalSignature"
            TextExtension = @("2.5.29.37={text}1.3.6.1.5.5.7.3.3")
        }
        $cert = New-SelfSignedCertificate @certArgs
    }

    $cerPath = Join-Path $PackageRoot "personal_toolbox_debug.cer"
    foreach ($storePath in @("Cert:\CurrentUser\TrustedPeople", "Cert:\CurrentUser\Root")) {
        $trusted = Get-ChildItem $storePath |
            Where-Object { $_.Thumbprint -eq $cert.Thumbprint } |
            Select-Object -First 1
        if ($null -eq $trusted) {
            if (-not (Test-Path -LiteralPath $cerPath)) {
                Export-Certificate -Cert $cert -FilePath $cerPath | Out-Null
            }
            Import-Certificate -FilePath $cerPath -CertStoreLocation $storePath | Out-Null
        }
    }

    if (-not (Test-Path -LiteralPath $cerPath)) {
        Export-Certificate -Cert $cert -FilePath $cerPath | Out-Null
    }

    return $cert
}

function Test-CertificateInStore {
    param(
        [Parameter(Mandatory = $true)][string]$StorePath,
        [Parameter(Mandatory = $true)][string]$Thumbprint
    )

    $found = Get-ChildItem $StorePath -ErrorAction SilentlyContinue |
        Where-Object { $_.Thumbprint -eq $Thumbprint } |
        Select-Object -First 1
    return $null -ne $found
}

function Ensure-MachineCertificateTrust {
    param([Parameter(Mandatory = $true)]$Certificate)

    $cerPath = Join-Path $PackageRoot "personal_toolbox_debug.cer"
    if (-not (Test-Path -LiteralPath $cerPath)) {
        Export-Certificate -Cert $Certificate -FilePath $cerPath | Out-Null
    }

    $machineStores = @("Cert:\LocalMachine\TrustedPeople", "Cert:\LocalMachine\Root")
    $missing = @(
        foreach ($storePath in $machineStores) {
            if (-not (Test-CertificateInStore -StorePath $storePath -Thumbprint $Certificate.Thumbprint)) {
                $storePath
            }
        }
    )
    if ($missing.Count -eq 0) {
        return
    }

    if (Test-IsAdministrator) {
        foreach ($storePath in $missing) {
            Import-Certificate -FilePath $cerPath -CertStoreLocation $storePath | Out-Null
        }
        return
    }

    if ($NoElevate) {
        throw "The debug signing certificate is not trusted by LocalMachine. Run this script without -NoElevate and approve the UAC prompt, or run it once from an elevated PowerShell window."
    }

    $helperPath = Join-Path $PackageRoot "trust_debug_certificate.ps1"
    $helperScript = @'
param(
    [Parameter(Mandatory = $true)][string]$CertPath,
    [Parameter(Mandatory = $true)][string]$Thumbprint
)

$ErrorActionPreference = "Stop"

foreach ($storePath in @("Cert:\LocalMachine\TrustedPeople", "Cert:\LocalMachine\Root")) {
    $found = Get-ChildItem $storePath -ErrorAction SilentlyContinue |
        Where-Object { $_.Thumbprint -eq $Thumbprint } |
        Select-Object -First 1
    if ($null -eq $found) {
        Import-Certificate -FilePath $CertPath -CertStoreLocation $storePath | Out-Null
    }
}
'@
    Set-Content -LiteralPath $helperPath -Value $helperScript -Encoding ascii

    Write-Host "[personal_toolbox] Requesting admin approval to trust the debug signing certificate..."
    $arguments = @(
        "-NoProfile",
        "-ExecutionPolicy", "Bypass",
        "-File", "`"$helperPath`"",
        "-CertPath", "`"$cerPath`"",
        "-Thumbprint", $Certificate.Thumbprint
    )
    $process = Start-Process -FilePath "powershell.exe" -ArgumentList $arguments -Verb RunAs -Wait -PassThru
    if ($process.ExitCode -ne 0) {
        throw "Elevated certificate trust helper failed with exit code $($process.ExitCode)."
    }

    $stillMissing = @(
        foreach ($storePath in $machineStores) {
            if (-not (Test-CertificateInStore -StorePath $storePath -Thumbprint $Certificate.Thumbprint)) {
                $storePath
            }
        }
    )
    if ($stillMissing.Count -gt 0) {
        throw "The debug signing certificate is still not trusted by LocalMachine: $($stillMissing -join ', ')."
    }
}

function New-DebugManifest {
    New-Item -ItemType Directory -Force -Path $ManifestRoot | Out-Null

    $datePart = [int](Get-Date -Format "MMdd")
    $timePart = [int](Get-Date -Format "HHmm")
    $version = "1.0.$datePart.$timePart"

    $capabilities = @(
        '    <rescap:Capability Name="runFullTrust" />',
        '    <uap7:Capability Name="globalMediaControl" />'
    )
    if (-not $SkipRestrictedCapabilities) {
        $capabilities += '    <rescap:Capability Name="phoneLineTransportManagement" />'
    }
    $capabilities += '    <DeviceCapability Name="bluetooth" />'

    $capabilityXml = $capabilities -join "`r`n"
    $manifest = @"
<?xml version="1.0" encoding="utf-8"?>
<Package
  xmlns="http://schemas.microsoft.com/appx/manifest/foundation/windows10"
  xmlns:uap="http://schemas.microsoft.com/appx/manifest/uap/windows10"
  xmlns:uap7="http://schemas.microsoft.com/appx/manifest/uap/windows10/7"
  xmlns:uap10="http://schemas.microsoft.com/appx/manifest/uap/windows10/10"
  xmlns:rescap="http://schemas.microsoft.com/appx/manifest/foundation/windows10/restrictedcapabilities"
  IgnorableNamespaces="uap uap7 uap10 rescap">
  <Identity Name="$PackageName" Publisher="$Publisher" Version="$version" ProcessorArchitecture="neutral" />
  <Properties>
    <DisplayName>$DisplayName</DisplayName>
    <PublisherDisplayName>w847</PublisherDisplayName>
    <Logo>Assets\StoreLogo.png</Logo>
    <uap10:AllowExternalContent>true</uap10:AllowExternalContent>
  </Properties>
  <Dependencies>
    <TargetDeviceFamily Name="Windows.Desktop" MinVersion="10.0.19041.0" MaxVersionTested="10.0.26100.0" />
  </Dependencies>
  <Applications>
    <Application Id="$ApplicationId" Executable="personal_toolbox.exe" uap10:TrustLevel="mediumIL" uap10:RuntimeBehavior="win32App">
      <uap:VisualElements
        DisplayName="$DisplayName"
        Description="Personal Toolbox debug package identity"
        BackgroundColor="transparent"
        Square150x150Logo="Assets\Square150x150Logo.png"
        Square44x44Logo="Assets\Square44x44Logo.png"
        AppListEntry="default" />
    </Application>
  </Applications>
  <Capabilities>
$capabilityXml
  </Capabilities>
</Package>
"@
    Set-Content -LiteralPath $ManifestPath -Value $manifest -Encoding utf8
}

function New-DebugExeManifest {
    $manifest = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<assembly xmlns="urn:schemas-microsoft-com:asm.v1" manifestVersion="1.0">
  <assemblyIdentity version="1.0.0.0" name="com.w847.personal_toolbox.app"/>
  <msix xmlns="urn:schemas-microsoft-com:msix.v1"
        publisher="$Publisher"
        packageName="$PackageName"
        applicationId="$ApplicationId"/>
  <application xmlns="urn:schemas-microsoft-com:asm.v3">
    <windowsSettings>
      <dpiAwareness xmlns="http://schemas.microsoft.com/SMI/2016/WindowsSettings">PerMonitorV2</dpiAwareness>
    </windowsSettings>
  </application>
  <compatibility xmlns="urn:schemas-microsoft-com:compatibility.v1">
    <application>
      <supportedOS Id="{8e0f7a12-bfb3-4fe8-b9a5-48fd50a15a9a}"/>
    </application>
  </compatibility>
</assembly>
"@
    Set-Content -LiteralPath $ExeManifestPath -Value $manifest -Encoding utf8
}

function Apply-DebugExeManifest {
    param([Parameter(Mandatory = $true)][string]$MtTool)

    $exePath = Join-Path $DebugOutput "personal_toolbox.exe"
    Write-Host "[personal_toolbox] Applying debug package identity to Debug exe..."
    & $MtTool -nologo -manifest $ExeManifestPath "-outputresource:$exePath;#1"
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
}

Set-Location $ProjectRoot

if (-not $SkipBuild) {
    Write-Host "[personal_toolbox] Building Windows debug output..."
    & $FlutterBin build windows --debug
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
}

if (-not (Test-Path -LiteralPath (Join-Path $DebugOutput "personal_toolbox.exe"))) {
    throw "Debug output was not found: $DebugOutput. Build Windows debug first."
}

New-Item -ItemType Directory -Force -Path $PackageRoot | Out-Null
New-DebugManifest
New-DebugExeManifest

$makeAppx = Find-WindowsSdkTool -Name "MakeAppx.exe"
$signTool = Find-WindowsSdkTool -Name "SignTool.exe"
$mtTool = Find-WindowsSdkTool -Name "mt.exe"

Write-Host "[personal_toolbox] MakeAppx: $makeAppx"
Write-Host "[personal_toolbox] SignTool: $signTool"
Write-Host "[personal_toolbox] Mt: $mtTool"
Write-Host "[personal_toolbox] Manifest: $ManifestPath"
Write-Host "[personal_toolbox] ExeManifest: $ExeManifestPath"
Write-Host "[personal_toolbox] ExternalLocation: $DebugOutput"

if ($DryRun) {
    Write-Host "[personal_toolbox] DryRun completed; no MSIX was created, signed, registered, or launched."
    exit 0
}

if (Test-Path -LiteralPath $PackagePath) {
    Remove-Item -LiteralPath $PackagePath -Force
}

Apply-DebugExeManifest -MtTool $mtTool

Write-Host "[personal_toolbox] Creating debug identity MSIX..."
& $makeAppx pack /o /d $ManifestRoot /nv /p $PackagePath
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

$cert = Ensure-DebugCertificate
Ensure-MachineCertificateTrust -Certificate $cert
Write-Host "[personal_toolbox] Signing debug identity MSIX..."
& $signTool sign /fd SHA256 /sha1 $cert.Thumbprint $PackagePath
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

$existing = Get-AppxPackage -Name $PackageName -ErrorAction SilentlyContinue
if ($null -ne $existing) {
    Write-Host "[personal_toolbox] Removing previous debug identity package..."
    $existing | Remove-AppxPackage
}

Write-Host "[personal_toolbox] Registering debug identity package..."
Add-AppxPackage -Path $PackagePath -ExternalLocation $DebugOutput -ForceApplicationShutdown

if (-not $NoLaunch) {
    Write-Host "[personal_toolbox] Launching Debug app with package identity..."
    Start-Process -FilePath (Join-Path $DebugOutput "personal_toolbox.exe")
}

Write-Host "[personal_toolbox] Done."
