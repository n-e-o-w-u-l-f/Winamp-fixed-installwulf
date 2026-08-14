Unicode True
Name "Install-Wulf"
OutFile "Winamp_InstallWulf-fixed.exe"
InstallDir "$PROGRAMFILES32\Winamp"
RequestExecutionLevel admin
SetCompressor /SOLID lzma
ShowInstDetails show

VIProductVersion "1.33.7.0"
VIAddVersionKey /LANG=1033 "ProductName" "Install-Wulf"
VIAddVersionKey /LANG=1033 "ProductVersion" "1,33,7a"
VIAddVersionKey /LANG=1033 "FileDescription" "Winamp Install-Wulf Installer"

Section "Winamp" SEC01
  SectionIn RO
  SetOutPath "$INSTDIR"
  File /r "build\payload\*"

  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Install-Wulf" "DisplayName" "Install-Wulf (Winamp)"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Install-Wulf" "DisplayVersion" "1,33,7a"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Install-Wulf" "InstallLocation" "$INSTDIR"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Install-Wulf" "UninstallString" '"$INSTDIR\Uninstall.exe"'
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Install-Wulf" "NoModify" 1
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Install-Wulf" "NoRepair" 1
  WriteUninstaller "$INSTDIR\Uninstall.exe"
SectionEnd

Section "Uninstall"
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Install-Wulf"
  Delete "$INSTDIR\Uninstall.exe"
  RMDir /r "$INSTDIR"
SectionEnd
