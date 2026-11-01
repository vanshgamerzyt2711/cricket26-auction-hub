; Cricket 26 Auction Hub - standard offline installer (packaging revision 5)
; Copy this file beside an AppPayload folder containing the reviewed application files.
; IMPORTANT: AppVersion is packaging version; this script does not upgrade the app's binary features.
[Setup]
AppId=Cricket26AuctionHub.Standard
AppName=Cricket 26 Auction Hub
AppVersion=5.0.0
AppPublisher=vanshgamerzyt2711
DefaultDirName={localappdata}\Programs\Cricket26AuctionHub
DefaultGroupName=Cricket 26 Auction Hub
PrivilegesRequired=lowest
OutputDir=Output
OutputBaseFilename=Cricket26AuctionHub-Setup
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
SetupLogging=yes
UninstallDisplayIcon={app}\Cricket26AuctionManager.exe
CloseApplications=yes
RestartApplications=no

[Files]
Source: "AppPayload\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\Cricket 26 Auction Hub"; Filename: "{app}\Cricket26AuctionManager.exe"; WorkingDir: "{app}"
Name: "{autodesktop}\Cricket 26 Auction Hub"; Filename: "{app}\Cricket26AuctionManager.exe"; WorkingDir: "{app}"
