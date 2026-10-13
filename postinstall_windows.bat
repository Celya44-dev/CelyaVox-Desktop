@echo off
REM postinstall_windows.bat - Script post-installation pour Windows
REM Ce script appelle le PowerShell qui enregistre le gestionnaire de lien tel:

setlocal enabledelayedexpansion
echo [postinstall] Debut de l'enregistrement du gestionnaire de lien tel:

REM Récupérer le chemin du dossier courant (devrait être le dossier d'installation)
set INSTALL_DIR=%~dp0

REM Appeler le script PowerShell avec le paramètre InstallDir
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%INSTALL_DIR%postinstall_windows.ps1" -InstallDir "%INSTALL_DIR%"

echo [postinstall] Enregistrement termine
endlocal
