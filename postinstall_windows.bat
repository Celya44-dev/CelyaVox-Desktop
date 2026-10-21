@echo off
REM postinstall_windows.bat - Enregistrement du gestionnaire de lien tel: avec logs
REM Vérification et élévation des privilèges administrateur

setlocal enabledelayedexpansion

REM Vérifier si l'administrateur est actif
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"

if !errorlevel! neq 0 (
  echo.
  echo [AVERTISSEMENT] Ce script necessite les droits administrateur.
  echo [ACTION] Relancement du script en tant qu'administrateur...
  echo.
  
  REM Relancer le script avec droits admin
  powershell -Command "Start-Process -FilePath 'cmd.exe' -ArgumentList '/c \"%~f0\" \"%~1\"' -Verb RunAs -WindowStyle Hidden" 
  exit /b !errorlevel!
)

REM Le chemin d'installation devrait être passé en paramètre, sinon on utilise le répertoire courant
if not "%1"=="" (
  set "INSTALL_DIR=%1"
) else (
  set "INSTALL_DIR=%~dp0"
)

set "LOG_FILE=!INSTALL_DIR!install.log"
set "APP_PATH=!INSTALL_DIR!CelyaVox.exe"
set "PROG_ID=CelyaVox.tel"

REM Créer le fichier log local
echo [%DATE% %TIME%] [DEBUT] Installation de CelyaVox >> "!LOG_FILE!"
echo [%DATE% %TIME%] [CHEMIN] Installation: !INSTALL_DIR! >> "!LOG_FILE!"
echo [%DATE% %TIME%] [PROTOCOLE] Enregistrement du gestionnaire tel: en cours >> "!LOG_FILE!"
echo [%DATE% %TIME%] [PROTOCOLE] Enregistrement du gestionnaire callto: en cours >> "!LOG_FILE!"

REM Écrire aussi dans Windows Event Log (Application)
eventcreate /T INFORMATION /ID 1000 /L APPLICATION /SO "CelyaVox Installer" /D "CelyaVox postinstall started - Installation path: !INSTALL_DIR!" 2>nul

REM ===== HKCU (User Registry) - Ne nécessite pas admin =====
echo [%DATE% %TIME%] [REGISTRE] Enregistrement HKCU >> "!LOG_FILE!"

reg add "HKCU\Software\Classes\tel" /ve /d "URL:tel protocol" /f >nul 2>&1
if !errorlevel! equ 0 (
  echo [%DATE% %TIME%] [OK] HKCU\Software\Classes\tel cree >> "!LOG_FILE!"
) else (
  echo [%DATE% %TIME%] [ERREUR] Impossible de creer HKCU\Software\Classes\tel >> "!LOG_FILE!"
)

reg add "HKCU\Software\Classes\tel" /v "URL Protocol" /d "" /f >nul 2>&1
reg add "HKCU\Software\Classes\tel\shell\open\command" /ve /d "\"!APP_PATH!\" \"%%1\"" /f >nul 2>&1
if !errorlevel! equ 0 (
  echo [%DATE% %TIME%] [OK] Commande HKCU enregistree: "!APP_PATH!" "%%1" >> "!LOG_FILE!"
) else (
  echo [%DATE% %TIME%] [ERREUR] Impossible d'enregistrer la commande HKCU >> "!LOG_FILE!"
)

REM Enregistrement de callto: en HKCU
reg add "HKCU\Software\Classes\callto" /ve /d "URL:callto protocol" /f >nul 2>&1
if !errorlevel! equ 0 (
  echo [%DATE% %TIME%] [OK] HKCU\Software\Classes\callto cree >> "!LOG_FILE!"
) else (
  echo [%DATE% %TIME%] [ERREUR] Impossible de creer HKCU\Software\Classes\callto >> "!LOG_FILE!"
)

reg add "HKCU\Software\Classes\callto" /v "URL Protocol" /d "" /f >nul 2>&1
reg add "HKCU\Software\Classes\callto\shell\open\command" /ve /d "\"!APP_PATH!\" \"%%1\"" /f >nul 2>&1
if !errorlevel! equ 0 (
  echo [%DATE% %TIME%] [OK] Commande HKCU callto enregistree >> "!LOG_FILE!"
) else (
  echo [%DATE% %TIME%] [ERREUR] Impossible d'enregistrer la commande HKCU callto >> "!LOG_FILE!"
)

REM ===== Tentative HKLM (System Registry) - Nécessite admin =====
echo [%DATE% %TIME%] [REGISTRE] Tentative enregistrement HKLM >> "!LOG_FILE!"

reg add "HKLM\Software\Classes\tel" /ve /d "URL:tel protocol" /f >nul 2>&1
if !errorlevel! equ 0 (
  echo [%DATE% %TIME%] [OK] HKLM\Software\Classes\tel cree >> "!LOG_FILE!"
  
  reg add "HKLM\Software\Classes\tel" /v "URL Protocol" /d "" /f >nul 2>&1
  reg add "HKLM\Software\Classes\tel\shell\open\command" /ve /d "\"!APP_PATH!\" \"%%1\"" /f >nul 2>&1
  echo [%DATE% %TIME%] [OK] Commande HKLM enregistree >> "!LOG_FILE!"
  
  REM Enregistrement du ProgId
  reg add "HKLM\Software\Classes\!PROG_ID!" /ve /d "Telephone Link" /f >nul 2>&1
  reg add "HKLM\Software\Classes\!PROG_ID!\DefaultIcon" /ve /d "\"!APP_PATH!\",0" /f >nul 2>&1
  reg add "HKLM\Software\Classes\!PROG_ID!\shell\open\command" /ve /d "\"!APP_PATH!\" \"%%1\"" /f >nul 2>&1
  echo [%DATE% %TIME%] [OK] ProgId HKLM enregistre >> "!LOG_FILE!"
  
  REM Enregistrement de callto: en HKLM
  reg add "HKLM\Software\Classes\callto" /ve /d "URL:callto protocol" /f >nul 2>&1
  reg add "HKLM\Software\Classes\callto" /v "URL Protocol" /d "" /f >nul 2>&1
  reg add "HKLM\Software\Classes\callto\shell\open\command" /ve /d "\"!APP_PATH!\" \"%%1\"" /f >nul 2>&1
  echo [%DATE% %TIME%] [OK] Commande HKLM callto enregistree >> "!LOG_FILE!"
  
  REM Enregistrement du ProgId pour callto
  set "PROG_ID_CALLTO=CelyaVox.callto"
  reg add "HKLM\Software\Classes\!PROG_ID_CALLTO!" /ve /d "Telephone Link" /f >nul 2>&1
  reg add "HKLM\Software\Classes\!PROG_ID_CALLTO!\DefaultIcon" /ve /d "\"!APP_PATH!\",0" /f >nul 2>&1
  reg add "HKLM\Software\Classes\!PROG_ID_CALLTO!\shell\open\command" /ve /d "\"!APP_PATH!\" \"%%1\"" /f >nul 2>&1
  echo [%DATE% %TIME%] [OK] ProgId callto HKLM enregistre >> "!LOG_FILE!"
  
  REM Enregistrement dans RegisteredApplications
  reg add "HKLM\Software\RegisteredApplications" /v "CelyaVox" /d "Software\Classes\Applications\CelyaVox.exe\Capabilities" /f >nul 2>&1
  echo [%DATE% %TIME%] [OK] RegisteredApplications enregistre >> "!LOG_FILE!"
  
  REM Enregistrement des Capabilities
  reg add "HKLM\Software\Classes\Applications\CelyaVox.exe\Capabilities" /v "ApplicationName" /d "CelyaVox" /f >nul 2>&1
  reg add "HKLM\Software\Classes\Applications\CelyaVox.exe\Capabilities" /v "ApplicationDescription" /d "Telephone and VoIP application" /f >nul 2>&1
  reg add "HKLM\Software\Classes\Applications\CelyaVox.exe\Capabilities\URLAssociations" /v "tel" /d "!PROG_ID!" /f >nul 2>&1
  reg add "HKLM\Software\Classes\Applications\CelyaVox.exe\Capabilities\URLAssociations" /v "callto" /d "!PROG_ID_CALLTO!" /f >nul 2>&1
  echo [%DATE% %TIME%] [OK] Capabilities HKLM enregistrees >> "!LOG_FILE!"
  
  eventcreate /T INFORMATION /ID 1001 /L APPLICATION /SO "CelyaVox Installer" /D "CelyaVox protocol handler registered successfully in HKLM" 2>nul
) else (
  echo [%DATE% %TIME%] [INFO] Pas d'acces admin pour HKLM - seul HKCU est configure >> "!LOG_FILE!"
  eventcreate /T WARNING /ID 1002 /L APPLICATION /SO "CelyaVox Installer" /D "CelyaVox postinstall: No admin access for HKLM, only HKCU configured" 2>nul
)

REM Vérification finale
echo [%DATE% %TIME%] [VERIFICATION] Verification des clés registre >> "!LOG_FILE!"

reg query "HKCU\Software\Classes\tel" >nul 2>&1
if !errorlevel! equ 0 (
  echo [%DATE% %TIME%] [OK] Verification HKCU reussie >> "!LOG_FILE!"
) else (
  echo [%DATE% %TIME%] [ERREUR] HKCU tel: non trouve >> "!LOG_FILE!"
)

reg query "HKCU\Software\Classes\callto" >nul 2>&1
if !errorlevel! equ 0 (
  echo [%DATE% %TIME%] [OK] Verification HKCU callto reussie >> "!LOG_FILE!"
) else (
  echo [%DATE% %TIME%] [ERREUR] HKCU callto: non trouve >> "!LOG_FILE!"
)

reg query "HKLM\Software\Classes\tel" >nul 2>&1
if !errorlevel! equ 0 (
  echo [%DATE% %TIME%] [OK] Verification HKLM reussie >> "!LOG_FILE!"
) else (
  echo [%DATE% %TIME%] [INFO] HKLM tel: non disponible (admin requis) >> "!LOG_FILE!"
)

reg query "HKLM\Software\Classes\callto" >nul 2>&1
if !errorlevel! equ 0 (
  echo [%DATE% %TIME%] [OK] Verification HKLM callto reussie >> "!LOG_FILE!"
) else (
  echo [%DATE% %TIME%] [INFO] HKLM callto: non disponible (admin requis) >> "!LOG_FILE!"
)

echo [%DATE% %TIME%] [SUCCES] Enregistrement complet >> "!LOG_FILE!"
echo [%DATE% %TIME%] [INFO] Fichier log: !LOG_FILE! >> "!LOG_FILE!"

REM Écrire l'événement final dans Windows Event Log
eventcreate /T INFORMATION /ID 1003 /L APPLICATION /SO "CelyaVox Installer" /D "CelyaVox postinstall completed - Log file: !LOG_FILE!" 2>nul

endlocal
