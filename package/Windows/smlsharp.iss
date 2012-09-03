; install smlsharp
; $Id: smlsharp.iss,v 1.2.6.1 2007/06/25 05:30:55 katsu Exp $

[Setup]
AppName=SML#
AppId=SML# 0.30
AppVerName=SML# 0.30
AppVersion=0.30
AppPublisher=Tohoku University
AppPublisherURL=http://www.pllab.riec.tohoku.ac.jp/smlsharp/
AppSupportURL=http://www.pllab.riec.tohoku.ac.jp/smlsharp/
AppUpdatesURL=http://www.pllab.riec.tohoku.ac.jp/smlsharp/
VersionInfoCopyright=Copyright (C) 2006-2007 Tohoku University.
MinVersion=4.1,4.0
DefaultDirName={pf}\SMLSharp
DefaultGroupName=SML#
AllowNoIcons=yes
Compression=lzma/max
SolidCompression=yes
TimeStampsInUTC=yes
UninstallDisplayIcon={app}\bin\smlsharprun.exe,0
OutputBaseFilename=smlsharp-0.30-mingw
ChangesEnvironment=yes
ChangesAssociations=yes
LicenseFile=license.txt
WizardImageFile=WizardImage.bmp

[Tasks]
Name: addToPath; Description: "Add SML# to &PATH environment variable"
Name: associateSML; Description: "Associate *.sml files to SML#(&L)"
Name: associateSME; Description: "Associate *.sme files to SML#(&E)"
Name: desktopicon; Description: "&Create a desktop icon"

[Files]
Source: "dist\*"; DestDir: "{app}" ; Flags: recursesubdirs replacesameversion ; Excludes: "*.*~"

[Icons]
Name: "{group}\SML#"; FileName: "{cmd}"; Parameters: "/c ""{app}\bin\smlsharp.exe"""; IconFilename: "{app}\bin\smlsharprun.exe"; IconIndex: 0; Comment: "Start SML#"
Name: "{group}\Uninstall SML#"; Filename: "{uninstallexe}"
Name: "{commondesktop}\SML# Compiler"; FileName: "{cmd}"; Parameters: "/c ""{app}\bin\smlsharp.exe"""; IconFilename: "{app}\bin\smlsharprun.exe"; IconIndex: 0; Tasks: desktopicon

[Registry]
Root: HKLM; SubKey: "SYSTEM\CurrentControlSet\Control\Session Manager\Environment"; ValueType: string; ValueName: "SMLSHARP_LIB_PATH"; ValueData: "{app}\lib\smlsharp"
Root: HKLM; SubKey: "SYSTEM\CurrentControlSet\Control\Session Manager\Environment"; ValueType: string; ValueName: "PATH"; ValueData: "{app}\bin;{olddata}" ; Tasks: addToPath

Root: HKCR; Subkey: ".sml"; ValueType: string; ValueName: ""; ValueData: "SMLSourceFile"; Flags: uninsdeletevalue ; Tasks: associateSML
Root: HKCR; Subkey: "SMLSourceFile"; ValueType: string; ValueName: ""; ValueData: "SML Source File"; Flags: uninsdeletekey ; Tasks: associateSML
Root: HKCR; Subkey: "SMLSourceFile\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: "{app}\bin\smlsharprun.exe,1" ; Tasks: associateSML
Root: HKCR; Subkey: "SMLSourceFile\Shell\open\command"; ValueType: string; ValueName: ""; ValueData: "{sys}\NOTEPAD.EXE %1" ; Flags: createvalueifdoesntexist; Tasks: associateSML
Root: HKCR; Subkey: "SMLSourceFile\Shell\Execute"; ValueType: string; ValueName: ""; ValueData: "&Execute" ; Tasks: associateSML
Root: HKCR; Subkey: "SMLSourceFile\Shell\Execute\command"; ValueType: string; ValueName: ""; ValueData: """{app}\bin\smlsharp.exe"" ""%1""" ; Tasks: associateSML

Root: HKCR; Subkey: ".sme"; ValueType: string; ValueName: ""; ValueData: "CompiledSMLFile"; Flags: uninsdeletevalue ; Tasks: associateSME
Root: HKCR; Subkey: "CompiledSMLFile"; ValueType: string; ValueName: ""; ValueData: "Compiled SML# program"; Flags: uninsdeletekey ; Tasks: associateSME
Root: HKCR; Subkey: "CompiledSMLFile\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: "{app}\bin\smlsharprun.exe,2" ; Tasks: associateSME
Root: HKCR; Subkey: "CompiledSMLFile\Shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\bin\smlsharprun.exe"" ""%1""" ; Tasks: associateSME

[Run]
Filename: "{app}\bin\smlsharp.exe"; Parameters: "-I .\lib\smlsharp .\samples\hello\hello_world.sml"; WorkingDir: "{app}"; Description: "&Execute hello world"; Flags: nowait postinstall skipifsilent runhidden unchecked
