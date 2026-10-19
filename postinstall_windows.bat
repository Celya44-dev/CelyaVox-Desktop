@echo off
REM postinstall_windows.bat - Enregistrement du gestionnaire de lien tel: via reg.exe
REM Ce script peut être exécuté manuellement après l'installation si nécessaire

setlocal enabledelayedexpansion

REM Le chemin d'installation devrait être passé en paramètre, sinon on utilise le répertoire courant
if not "%1"=="" (
  set "INSTALL_DIR=%1"
) else (
  set "INSTALL_DIR=%~dp0"
)

echo [postinstall] Enregistrement du gestionnaire tel: pour CelyaVox
echo [postinstall] Chemin: !INSTALL_DIR!

set "APP_PATH=!INSTALL_DIR!CelyaVox.exe"
set "PROG_ID=CelyaVox.tel"

REM ===== HKCU (User Registry) - Ne nécessite pas admin =====
echo [postinstall] Enregistrement dans HKCU (utilisateur)...

reg add "HKCU\Software\Classes\tel" /ve /d "URL:tel protocol" /f >nul 2>&1
reg add "HKCU\Software\Classes\tel" /v "URL Protocol" /d "" /f >nul 2>&1
reg add "HKCU\Software\Classes\tel\shell\open\command" /ve /d "\"!APP_PATH!\" \"%%1\"" /f >nul 2>&1

echo [postinstall] Enregistrement HKCU termine

REM ===== Tentative HKLM (System Registry) - Nécessite admin =====
echo [postinstall] Tentative enregistrement dans HKLM (systeme)...

reg add "HKLM\Software\Classes\tel" /ve /d "URL:tel protocol" /f >nul 2>&1
if !errorlevel! equ 0 (
  echo [postinstall] HKLM disponible (admin detecte)
  
  reg add "HKLM\Software\Classes\tel" /v "URL Protocol" /d "" /f >nul 2>&1
  reg add "HKLM\Software\Classes\tel\shell\open\command" /ve /d "\"!APP_PATH!\" \"%%1\"" /f >nul 2>&1
  
  REM Enregistrement du ProgId
  reg add "HKLM\Software\Classes\!PROG_ID!" /ve /d "Telephone Link" /f >nul 2>&1
  reg add "HKLM\Software\Classes\!PROG_ID!\DefaultIcon" /ve /d "\"!APP_PATH!\",0" /f >nul 2>&1
  reg add "HKLM\Software\Classes\!PROG_ID!\shell\open\command" /ve /d "\"!APP_PATH!\" \"%%1\"" /f >nul 2>&1
  
  REM Enregistrement dans RegisteredApplications
  reg add "HKLM\Software\RegisteredApplications" /v "CelyaVox" /d "Software\Classes\Applications\CelyaVox.exe\Capabilities" /f >nul 2>&1
  
  REM Enregistrement des Capabilities
  reg add "HKLM\Software\Classes\Applications\CelyaVox.exe\Capabilities" /v "ApplicationName" /d "CelyaVox" /f >nul 2>&1
  reg add "HKLM\Software\Classes\Applications\CelyaVox.exe\Capabilities" /v "ApplicationDescription" /d "Telephone and VoIP application" /f >nul 2>&1
  reg add "HKLM\Software\Classes\Applications\CelyaVox.exe\Capabilities\URLAssociations" /v "tel" /d "!PROG_ID!" /f >nul 2>&1
  
  echo [postinstall] HKLM enregistrement termine
) else (
  echo [postinstall] Pas d'acces admin pour HKLM - seul HKCU est configure
)

echo [postinstall] Enregistrement complet
echo.

endlocal
