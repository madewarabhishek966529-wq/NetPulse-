; Script generated for NetPulse Download Manager
; Advanced High-Speed Download Manager for Windows 10/11

#define MyAppName "NetPulse"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "NetPulse Technologies"
#define MyAppURL "https://github.com/netpulse/netpulse"
#define MyAppExeName "netpulse.exe"

[Setup]
AppId={{E14D2B57-C67C-4328-97A2-17E5E3579124}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
DisableProgramGroupPage=yes
LicenseFile=license.txt
OutputDir=..\dist
OutputBaseFilename=NetPulse-Setup
SetupIconFile=..\windows\runner\resources\app_icon.ico
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequired=lowest

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
Name: "registerbrowser"; Description: "Register browser integration (Chrome, Edge, Firefox)"; GroupDescription: "Browser Integration"

[Files]
; NetPulse application build output files
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs; Check: DirExists(ExpandConstant('{app}'))
; Bundled aria2 background engine
Source: "..\assets\bin\aria2c.exe"; DestDir: "{app}\bin"; Flags: ignoreversion
; NetPulse Python Backend
Source: "..\backend\*"; DestDir: "{app}\backend"; Flags: ignoreversion recursesubdirs
; Launch Scripts
Source: "..\run_netpulse.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\setup.ps1"; DestDir: "{app}"; Flags: ignoreversion
; Application icon & branding
Source: "..\assets\icons\*"; DestDir: "{app}\assets\icons"; Flags: ignoreversion recursesubdirs
; Native Messaging Host & Browser extensions
Source: "..\browser_extension\*"; DestDir: "{app}\browser_extension"; Flags: ignoreversion recursesubdirs

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Registry]
; Google Chrome Native Messaging Host
Root: HKCU; Subkey: "Software\Google\Chrome\NativeMessagingHosts\com.netpulse.downloader"; ValueType: string; ValueData: "{app}\browser_extension\native_host\com.netpulse.downloader.json"; Flags: uninsdeletekey; Tasks: registerbrowser
; Microsoft Edge Native Messaging Host
Root: HKCU; Subkey: "Software\Microsoft\Edge\NativeMessagingHosts\com.netpulse.downloader"; ValueType: string; ValueData: "{app}\browser_extension\native_host\com.netpulse.downloader.json"; Flags: uninsdeletekey; Tasks: registerbrowser
; Mozilla Firefox Native Messaging Host
Root: HKCU; Subkey: "Software\Mozilla\NativeMessagingHosts\com.netpulse.downloader"; ValueType: string; ValueData: "{app}\browser_extension\native_host\firefox\com.netpulse.downloader.json"; Flags: uninsdeletekey; Tasks: registerbrowser

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[Code]
function DirExists(Dir: String): Boolean;
begin
  Result := True;
end;

