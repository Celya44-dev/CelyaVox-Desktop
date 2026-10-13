# postinstall_windows.ps1 - Script post-installation pour Windows (NSIS)
# Note: Ce script s'exécute en tant qu'administrateur système
# Les fichiers de configuration utilisateur seront créés par l'application 
# au premier lancement, pas par le programme d'installation

param(
    [string]$InstallDir = ""
)

Write-Host "[postinstall] Installation de CelyaVox réussie" -ForegroundColor Green

# Enregistrer le protocole tel: dans le registre Windows
# Cela permet aux applications (navigateurs, etc.) de passer les liens tel: à CelyaVox

try {
    $AppPath = Join-Path $InstallDir "CelyaVox.exe"
    $AppId = "fr.celya.celyavox"
    
    # Créer les clés de registre pour le protocole tel:
    $ProtocolPath = "HKCU:\Software\Microsoft\Windows\Shell\Associations\ProgId\tel"
    
    # Créer la structure de registre
    if (!(Test-Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\App Paths")) {
        New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\App Paths" -Force | Out-Null
    }
    
    # Enregistrer l'association de protocole pour l'utilisateur actuel
    New-Item -Path "HKCU:\Software\Classes\tel" -Force | Out-Null
    Set-ItemProperty -Path "HKCU:\Software\Classes\tel" -Name "(Default)" -Value "URL:tel protocol" -Force
    Set-ItemProperty -Path "HKCU:\Software\Classes\tel" -Name "URL Protocol" -Value "" -Force
    
    New-Item -Path "HKCU:\Software\Classes\tel\shell" -Force | Out-Null
    New-Item -Path "HKCU:\Software\Classes\tel\shell\open" -Force | Out-Null
    New-Item -Path "HKCU:\Software\Classes\tel\shell\open\command" -Force | Out-Null
    
    Set-ItemProperty -Path "HKCU:\Software\Classes\tel\shell\open\command" -Name "(Default)" -Value "`"$AppPath`" `"%1`"" -Force
    
    Write-Host "✅ Protocole tel: enregistré pour l'utilisateur courant" -ForegroundColor Green
}
catch {
    Write-Host "⚠️ Erreur lors de l'enregistrement du protocole tel:: $_" -ForegroundColor Yellow
}

# L'application crée les fichiers config au premier lancement
