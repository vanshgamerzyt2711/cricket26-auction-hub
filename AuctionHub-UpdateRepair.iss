; Cricket 26 Auction Hub - one-click fix for the original Inno Setup app.
; Does not install another copy, edit auction data, disable security, or create shortcuts.
[Setup]
AppId=Cricket26AuctionHub.Standard
AppName=Cricket 26 Auction Hub - Update Repair
AppVersion=5.0.3
AppPublisher=vanshgamerzyt2711
AppVerName=Cricket 26 Auction Hub | One-Click Update Repair
DefaultDirName={localappdata}\Programs\Cricket26AuctionHub
UsePreviousAppDir=yes
DefaultGroupName=Cricket 26 Auction Hub
PrivilegesRequired=lowest
OutputDir=RepairOutput
OutputBaseFilename=Cricket26AuctionHub-UpdateRepair
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
DisableDirPage=yes
DisableProgramGroupPage=yes
DisableReadyPage=yes
Uninstallable=no
CreateUninstallRegKey=no
SetupLogging=yes
CloseApplications=yes
RestartApplications=no
AllowRootDirectory=no
AllowUNCPath=no
ChangesAssociations=no

[Files]
; The single binary is downloaded from V5.0.3 and SHA-256 verified by GitHub Actions before compiler invocation.
Source: "RepairPayload\AuctionUpdateHelper.exe"; DestDir: "{app}"; Flags: ignoreversion

[Run]
Filename: "{app}\Cricket26AuctionManager.exe"; Description: "Open Auction Hub to finish updating"; Flags: nowait postinstall skipifsilent

[Code]
const
  REPAIR_REPARSE_ATTRIBUTE = $400;
  REPAIR_INVALID_ATTRIBUTES = $FFFFFFFF;

function GetFileAttributesW(lpFileName: string): Cardinal;
  external 'GetFileAttributesW@kernel32.dll stdcall';

function IsLinkedPath(Path: string): Boolean;
var
  Cur: string;
  Parent: string;
  Attrs: Cardinal;
begin
  Result := False;
  Cur := RemoveBackslashUnlessRoot(Path);
  while Cur <> '' do
  begin
    if DirExists(Cur) then
    begin
      Attrs := GetFileAttributesW(Cur);
      if (Attrs <> REPAIR_INVALID_ATTRIBUTES) and ((Attrs and REPAIR_REPARSE_ATTRIBUTE) <> 0) then
      begin
        Result := True;
        Exit;
      end;
    end;

    Parent := ExtractFileDir(Cur);
    if (Parent = '') or (CompareText(Parent, Cur) = 0) then
      Break;
    Cur := Parent;
  end;
end;

function ValidateTarget(): string;
var
  Target: string;
  Official: string;
  Existing: string;
  Key: string;
  RegMatches: Boolean;
begin
  Result := '';
  Target := RemoveBackslashUnlessRoot(ExpandConstant('{app}'));
  Official := RemoveBackslashUnlessRoot(ExpandConstant('{localappdata}\Programs\Cricket26AuctionHub'));
  Key := 'Software\Microsoft\Windows\CurrentVersion\Uninstall\Cricket26AuctionHub.Standard_is1';
  RegMatches := False;

  if RegQueryStringValue(HKCU, Key, 'InstallLocation', Existing) then
  begin
    RegMatches := CompareText(RemoveBackslashUnlessRoot(Existing), Target) = 0;
  end;

  { Restrict repair to the official Inno default location or a location explicitly
    registered for the correct AppId by the original Inno Setup installer. }
  if not (CompareText(Target, Official) = 0) and not RegMatches then
  begin
    Result := 'The Auction Hub installation is not registered at this path. ' +
      'Please install the official full Auction Hub Setup once.';
    Exit;
  end;

  if not FileExists(AddBackslash(Target) + 'Cricket26AuctionManager.exe') or
     not FileExists(AddBackslash(Target) + 'AuctionUpdateHelper.exe') or
     not FileExists(AddBackslash(Target) + 'release-manifest.json') then
  begin
    Result := 'No complete Auction Hub installation was found at: ' + Target +
      '. This repair does not install a second app. Use the official full Setup instead.';
    Exit;
  end;

  if IsLinkedPath(Target) then
  begin
    Result := 'Linked or redirected installation folders are not supported.';
    Exit;
  end;

  Log('Validated updater repair destination: ' + Target);
end;

function PrepareToInstall(var NeedsRestart: Boolean): string;
begin
  Result := ValidateTarget();
end;
