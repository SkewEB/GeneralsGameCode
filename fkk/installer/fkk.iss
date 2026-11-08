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

[Setup]
AppId={{6F0B4C1E-6A43-4C1B-9B7A-FKK0EDITION01}
AppName=C&C Generals Zero Hour - FKK Edition
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
Name: "{autodesktop}\Generals ZH FKK Edition"; Filename: "{app}\FKK-Starter.exe"; WorkingDir: "{app}"; IconFilename: "{app}\fkk.ico"
Name: "{autoprograms}\Generals ZH FKK Edition"; Filename: "{app}\FKK-Starter.exe"; WorkingDir: "{app}"; IconFilename: "{app}\fkk.ico"

[Run]
; after a silent auto-update: start the game again as the normal user
Filename: "{app}\FKK-Starter.exe"; Parameters: "-noupdate"; WorkingDir: "{app}"; Flags: nowait runasoriginaluser; Check: IsAutoUpdate
Filename: "{app}\FKK-Starter.exe"; Parameters: "-noupdate"; WorkingDir: "{app}"; Description: "Spiel jetzt starten"; Flags: nowait postinstall skipifsilent runasoriginaluser

[Code]
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

function NextButtonClick(CurPageID: Integer): Boolean;
begin
  Result := True;
  if (CurPageID = wpSelectDir) and not IsZHDir(WizardDirValue) then
    Result := MsgBox('In diesem Ordner liegt keine INIZH.big. Ist das wirklich der Zero-Hour-Ordner?', mbConfirmation, MB_YESNO) = IDYES;
end;

// keep the original generalszh.exe once, restore it on uninstall
procedure CurStepChanged(CurStep: TSetupStep);
var
  Exe: String;
begin
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
