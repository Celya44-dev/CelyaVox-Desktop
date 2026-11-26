; Custom NSIS configuration for CelyaVox installer
; This file is included by electron-builder (nsis.include).
; electron-builder calls the customInstall macro at the end of its install section.
;
; NSIS quoting: the outer string is delimited by backquotes (`) so that the
; double quotes needed by Windows command lines can be used freely inside.

!macro customInstall
  ; Execute post-installation script (registers tel:/callto: protocol handlers).
  ; The installer already runs elevated (per-machine install); the script also
  ; re-launches itself with elevation if needed.
  DetailPrint "Registering tel:/callto: protocol handlers..."
  ExecWait `powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$INSTDIR\postinstall_windows.ps1" -InstallDir "$INSTDIR"` $0

  ; If PowerShell fails, fallback to batch script
  ${If} $0 != 0
    DetailPrint "PowerShell script failed (code $0), falling back to batch script"
    ; cmd /c strips the outermost quotes, hence the extra pair around the whole command
    ExecWait `cmd.exe /c ""$INSTDIR\postinstall_windows.bat" "$INSTDIR""` $0
  ${EndIf}
!macroend
