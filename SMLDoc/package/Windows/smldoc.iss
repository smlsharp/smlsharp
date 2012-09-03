; install smldoc
; $Id: smldoc.iss,v 1.2 2007/04/14 03:20:10 kiyoshiy Exp $

[Setup]
AppName=SMLDoc
AppId=SMLDoc 0.20
AppVerName=SMLDoc 0.20
AppVersion=0.20
AppPublisher=Tohoku University
AppPublisherURL=http://www.pllab.riec.tohoku.ac.jp/smlsharp/
AppSupportURL=http://www.pllab.riec.tohoku.ac.jp/smlsharp/?SMLDoc
AppUpdatesURL=http://www.pllab.riec.tohoku.ac.jp/smlsharp/?SMLDoc
VersionInfoCopyright=Copyright (C) 2006-2007 Tohoku University.
MinVersion=4.1,4.0
DefaultDirName={pf}\SMLDoc
DefaultGroupName=SMLDoc
AllowNoIcons=yes
Compression=lzma/max
SolidCompression=yes
TimeStampsInUTC=yes
OutputBaseFilename=SMLDoc-0.20-mingw
ChangesEnvironment=yes
ChangesAssociations=yes
LicenseFile=license.txt

[Tasks]
Name: addToPath; Description: "Add SMLDoc to &PATH environment variable"

[Files]
Source: "dist\*"; DestDir: "{app}" ; Flags: recursesubdirs replacesameversion ; Excludes: "*.*~"

[Registry]
Root: HKLM; SubKey: "SYSTEM\CurrentControlSet\Control\Session Manager\Environment"; ValueType: string; ValueName: "PATH"; ValueData: "{app}\bin;{olddata}" ; Tasks: addToPath
