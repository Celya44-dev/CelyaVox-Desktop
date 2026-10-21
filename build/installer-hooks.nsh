; Custom NSIS configuration for CelyaVox installer
; This file is used by electron-builder to add custom post-installation hooks

!ifdef INSTALL
  Section "Install" Install
    ; Standard installation is handled by electron-builder
    ; This section can be used for custom post-install actions
  SectionEnd

  Section -post
    ; Execute post-installation script with administrator privileges
    ; The postinstall_windows.ps1 script will be in $INSTDIR after installation
    SetOutPath "$INSTDIR"
    
    ; Try PowerShell first (requires admin)
    ; Using -RunAs to ensure elevation on Windows Pro
    ExecWait 'powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "& {Start-Process powershell.exe -ArgumentList \"-NoProfile -ExecutionPolicy Bypass -File \'$INSTDIR\postinstall_windows.ps1\' -InstallDir \'$INSTDIR\'\" -Verb RunAs -Wait}"' $0
    
    ; If PowerShell fails, fallback to batch script
    ${If} $0 != 0
      DetailPrint "PowerShell script execution failed or cancelled, attempting fallback with batch script"
      ExecWait 'cmd.exe /c "$INSTDIR\postinstall_windows.bat" "$INSTDIR"'
    ${EndIf}
  SectionEnd
!endif

!ifdef UNINSTALL
  ; Uninstall is straightforward - no custom hooks needed
!endif
