; Custom NSIS configuration for CelyaVox installer
; This file is included by electron-builder (nsis.include).
; electron-builder calls the customInstall macro at the end of its install section.

!macro customInstall
  ; Execute post-installation script with administrator privileges
  ; The postinstall_windows.ps1 script is in $INSTDIR after installation
  SetOutPath "$INSTDIR"

  ; Try PowerShell first (requires admin)
  ExecWait 'powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "& {Start-Process powershell.exe -ArgumentList \"-NoProfile -ExecutionPolicy Bypass -File \'$INSTDIR\postinstall_windows.ps1\' -InstallDir \'$INSTDIR\'\" -Verb RunAs -Wait}"' $0

  ; If PowerShell fails, fallback to batch script
  ${If} $0 != 0
    DetailPrint "PowerShell script execution failed or cancelled, attempting fallback with batch script"
    ExecWait 'cmd.exe /c "$INSTDIR\postinstall_windows.bat" "$INSTDIR"'
  ${EndIf}
!macroend
