; C&C Generals Zero Hour - FKK Edition installer (Inno Setup 6)
; Built by .github/workflows/fkk-installer.yml:
;   iscc /DAppVersion=0.1.N /DGameDir=<artifact dir> /DStarterExe=<FKK-Starter.exe> fkk.iss

#ifndef AppVersion
  #define AppVersion "0.0.0"
#endif
#ifndef GameDir
  #define GameDir "..\..\build\artifacts"
#endif
#ifndef StarterExe
  #define StarterExe "FKK-Starter.exe"
#endif

#include "gamedata.iss"

[Setup]
AppId={{6F0B4C1E-6A43-4C1B-9B7A-FKK0EDITION01}
AppName=Generals FKK Edition (Fliesen Kalisch Killer Edition)
AppVersion={#AppVersion}
AppPublisher=Fliesen Kalisch Killer
AppPublisherURL=http://generals.kewekordes.com
DefaultDirName={code:GetDefaultDir}
DirExistsWarning=no
AppendDefaultDirName=no
UsePreviousAppDir=yes
DisableProgramGroupPage=yes
PrivilegesRequired=admin
OutputBaseFilename=FKK-Setup
OutputDir=output
SetupIconFile=fkk.ico
UninstallDisplayIcon={app}\FKK-Starter.exe
UninstallFilesDir={app}\fkk-uninstall
WizardImageFile=wizard.bmp
WizardSmallImageFile=wizard-small.bmp
WizardStyle=modern
Compression=lzma2/ultra
SolidCompression=yes
CloseApplications=yes

[Languages]
Name: "de"; MessagesFile: "compiler:Languages\German.isl"

[Messages]
de.SelectDirLabel3=Bitte den Ordner von Zero Hour wählen (der Ordner mit INIZH.big). Die Original-Dateien werden gesichert.

[Files]
Source: "{#GameDir}\generalszh.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#GameDir}\generalszh.pdb"; DestDir: "{app}"; Flags: ignoreversion skipifsourcedoesntexist
Source: "{#GameDir}\*.dll"; DestDir: "{app}"; Flags: ignoreversion skipifsourcedoesntexist
Source: "{#StarterExe}"; DestDir: "{app}"; DestName: "FKK-Starter.exe"; Flags: ignoreversion
Source: "FKKLogo.tga"; DestDir: "{app}\Art\Textures"; Flags: ignoreversion
Source: "fkk.ico"; DestDir: "{app}"; DestName: "fkk.ico"; Flags: ignoreversion
Source: "output\fkk-version.txt"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{autodesktop}\Generals FKK Edition"; Filename: "{app}\FKK-Starter.exe"; WorkingDir: "{app}"; IconFilename: "{app}\fkk.ico"
Name: "{autoprograms}\Generals FKK Edition"; Filename: "{app}\FKK-Starter.exe"; WorkingDir: "{app}"; IconFilename: "{app}\fkk.ico"

[Registry]
; only for installs from the private game-data download (no EA/Steam install present)
Root: HKLM32; Subkey: "SOFTWARE\Electronic Arts\EA Games\Generals"; ValueType: string; ValueName: "InstallPath"; ValueData: "{app}\GeneralsBase\"; Flags: uninsdeletevalue; Check: IsDataDownload
Root: HKLM32; Subkey: "SOFTWARE\Electronic Arts\EA Games\Command and Conquer Generals Zero Hour"; ValueType: string; ValueName: "InstallPath"; ValueData: "{app}\"; Flags: uninsdeletevalue; Check: IsDataDownload
Root: HKLM32; Subkey: "SOFTWARE\Electronic Arts\EA Games\Command and Conquer Generals Zero Hour"; ValueType: string; ValueName: "Language"; ValueData: "{#DataLanguage}"; Flags: uninsdeletevalue; Check: IsDataDownload
Root: HKLM32; Subkey: "SOFTWARE\Electronic Arts\EA Games\Command and Conquer Generals Zero Hour"; ValueType: dword; ValueName: "Version"; ValueData: "{#DataVersion}"; Flags: uninsdeletevalue; Check: IsDataDownload

[UninstallDelete]
Type: filesandordirs; Name: "{app}\GeneralsBase"; Check: IsDataDownload

[InstallDelete]
; shortcut name of v0.1.1
Type: files; Name: "{autodesktop}\Generals ZH FKK Edition.lnk"
Type: files; Name: "{autoprograms}\Generals ZH FKK Edition.lnk"

[Run]
; after a silent auto-update: start the game again as the normal user
Filename: "{app}\FKK-Starter.exe"; Parameters: "-noupdate"; WorkingDir: "{app}"; Flags: nowait runasoriginaluser; Check: IsAutoUpdate
Filename: "{app}\FKK-Starter.exe"; Parameters: "-noupdate"; WorkingDir: "{app}"; Description: "Spiel jetzt starten"; Flags: nowait postinstall skipifsilent runasoriginaluser

[Code]
var
  DataPage: TInputQueryWizardPage;
  DownloadPage: TDownloadWizardPage;
  DataDownload: Boolean;

function IsDataDownload(): Boolean;
begin
  Result := DataDownload;
end;

function IsAutoUpdate(): Boolean;
begin
  Result := ExpandConstant('{param:FKKUPDATE|0}') = '1';
end;

function IsZHDir(const Dir: String): Boolean;
begin
  Result := (Dir <> '') and FileExists(AddBackslash(Dir) + 'INIZH.big');
end;

function CheckCandidate(const Dir: String; var Found: String): Boolean;
begin
  Result := False;
  if Dir = '' then Exit;
  if IsZHDir(Dir) then begin Found := Dir; Result := True; Exit; end;
  if IsZHDir(AddBackslash(Dir) + 'Command and Conquer Generals Zero Hour') then begin
    Found := AddBackslash(Dir) + 'Command and Conquer Generals Zero Hour'; Result := True; Exit; end;
end;

function RegDir(const Key, Value: String): String;
begin
  Result := '';
  if not RegQueryStringValue(HKLM32, Key, Value, Result) then
    if not RegQueryStringValue(HKLM64, Key, Value, Result) then
      Result := '';
end;

function GetDefaultDir(Param: String): String;
var
  Found, Steam: String;
begin
  Found := '';
  if CheckCandidate(RegDir('SOFTWARE\Electronic Arts\EA Games\Command and Conquer Generals Zero Hour', 'InstallPath'), Found) then begin Result := Found; Exit; end;
  if CheckCandidate(RegDir('SOFTWARE\EA Games\Command and Conquer Generals Zero Hour', 'Install Dir'), Found) then begin Result := Found; Exit; end;
  if CheckCandidate(RegDir('SOFTWARE\Electronic Arts\Command and Conquer Generals Zero Hour', 'Install Dir'), Found) then begin Result := Found; Exit; end;
  Steam := RegDir('SOFTWARE\Valve\Steam', 'InstallPath');
  if CheckCandidate(AddBackslash(Steam) + 'steamapps\common\Command & Conquer Generals - Zero Hour', Found) then begin Result := Found; Exit; end;
  if CheckCandidate(AddBackslash(Steam) + 'steamapps\common\Command and Conquer Generals Zero Hour', Found) then begin Result := Found; Exit; end;
  if CheckCandidate(ExpandConstant('{commonpf32}\EA Games\Command and Conquer Generals Zero Hour'), Found) then begin Result := Found; Exit; end;
  if CheckCandidate(ExpandConstant('{commonpf64}\EA Games\Command and Conquer Generals Zero Hour'), Found) then begin Result := Found; Exit; end;
  if CheckCandidate(ExpandConstant('{commonpf32}\Origin Games\Command and Conquer Generals Zero Hour'), Found) then begin Result := Found; Exit; end;
  Result := ExpandConstant('{commonpf32}\EA Games\Command and Conquer Generals Zero Hour');
end;

function DataDownloadAvailable(): Boolean;
begin
  Result := ('{#ZHDataSHA256}' <> '') and ('{#GenDataSHA256}' <> '');
end;

procedure InitializeWizard();
begin
  DataDownload := False;
  DataPage := CreateInputQueryPage(wpWelcome,
    'Zero Hour nicht gefunden',
    'Spieldaten vom FKK-Server laden',
    'Auf diesem PC wurde kein C&C Generals Zero Hour gefunden. Gib die Zugangsdaten für den FKK-Spieldaten-Download ein (bekommst du von Kewe).' + #13#10 + #13#10 +
    'Lass die Felder leer, wenn du den Zero-Hour-Ordner lieber selbst auswählen willst.');
  DataPage.Add('Benutzername:', False);
  DataPage.Add('Passwort:', True);
  DownloadPage := CreateDownloadPage(SetupMessage(msgWizardPreparing), 'Spieldaten werden geladen (ca. 3 GB) ...', nil);
end;

function ShouldSkipPage(PageID: Integer): Boolean;
begin
  Result := False;
  if PageID = DataPage.ID then
    Result := IsAutoUpdate() or (not DataDownloadAvailable()) or IsZHDir(WizardDirValue);
end;

function NextButtonClick(CurPageID: Integer): Boolean;
begin
  Result := True;
  if CurPageID = DataPage.ID then begin
    DataDownload := (Trim(DataPage.Values[0]) <> '') and (DataPage.Values[1] <> '');
    if DataDownload then
      WizardForm.DirEdit.Text := ExpandConstant('{commonpf32}\Generals FKK Edition\Zero Hour');
    Exit;
  end;
  if (CurPageID = wpReady) and DataDownload then begin
    SetDownloadCredentials(Trim(DataPage.Values[0]), DataPage.Values[1]);
    DownloadPage.Clear;
    DownloadPage.Add('{#DataBaseURL}{#ZHDataFile}', '{#ZHDataFile}', '{#ZHDataSHA256}');
    DownloadPage.Add('{#DataBaseURL}{#GenDataFile}', '{#GenDataFile}', '{#GenDataSHA256}');
    DownloadPage.Show;
    try
      try
        DownloadPage.Download; // verifies the SHA-256 of each file
      except
        if DownloadPage.AbortedByUser then
          Log('Download abgebrochen')
        else
          MsgBox('Spieldaten konnten nicht geladen werden (falsches Passwort oder Server nicht erreichbar):' + #13#10 + GetExceptionMessage, mbError, MB_OK);
        Result := False;
      end;
    finally
      SetDownloadCredentials('', '');
      DownloadPage.Hide;
    end;
    Exit;
  end;
  if (CurPageID = wpSelectDir) and not DataDownload and not IsZHDir(WizardDirValue) then
    Result := MsgBox('In diesem Ordner liegt keine INIZH.big. Ist das wirklich der Zero-Hour-Ordner?', mbConfirmation, MB_YESNO) = IDYES;
end;

// keep the original generalszh.exe once, restore it on uninstall
function TarExe(): String;
begin
  Result := ExpandConstant('{sysnative}\tar.exe');
  if not FileExists(Result) then
    Result := ExpandConstant('{sys}\tar.exe');
end;

procedure ExtractData(const Archive, Dest: String);
var
  Code: Integer;
begin
  ForceDirectories(Dest);
  WizardForm.StatusLabel.Caption := 'Spieldaten werden entpackt ...';
  if not Exec(TarExe(), '-xf "' + ExpandConstant('{tmp}\') + Archive + '" -C "' + Dest + '"', '', SW_HIDE, ewWaitUntilTerminated, Code) or (Code <> 0) then
    RaiseException('Entpacken von ' + Archive + ' fehlgeschlagen (Code ' + IntToStr(Code) + ').');
end;

function RandomSerial(): String;
var
  I: Integer;
  Chars: String;
begin
  Chars := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  Result := '';
  for I := 1 to 20 do
    Result := Result + Chars[Random(Length(Chars)) + 1];
end;

procedure CurStepChanged(CurStep: TSetupStep);
var
  Exe, Serial: String;
begin
  if (CurStep = ssInstall) and DataDownload then begin
    ExtractData('{#ZHDataFile}', ExpandConstant('{app}'));
    ExtractData('{#GenDataFile}', ExpandConstant('{app}\GeneralsBase'));
  end;
  if (CurStep = ssPostInstall) and DataDownload then begin
    // the online lobby needs some CD key entry; our server does not check it
    if not RegQueryStringValue(HKLM32, 'SOFTWARE\Electronic Arts\EA Games\Command and Conquer Generals Zero Hour\ergc', '', Serial) or (Serial = '') then
      RegWriteStringValue(HKLM32, 'SOFTWARE\Electronic Arts\EA Games\Command and Conquer Generals Zero Hour\ergc', '', RandomSerial());
  end;
  if CurStep = ssInstall then begin
    Exe := ExpandConstant('{app}\generalszh.exe');
    if FileExists(Exe) and not FileExists(Exe + '.original') and not FileExists(ExpandConstant('{app}\fkk-version.txt')) then
      FileCopy(Exe, Exe + '.original', True);
  end;
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var
  Exe: String;
begin
  if CurUninstallStep = usPostUninstall then begin
    Exe := ExpandConstant('{app}\generalszh.exe');
    if FileExists(Exe + '.original') then begin
      DeleteFile(Exe);
      RenameFile(Exe + '.original', Exe);
    end;
  end;
end;
