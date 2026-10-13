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
# ET de montrer l'application dans Paramètres Windows

try {
    $AppPath = Join-Path $InstallDir "CelyaVox.exe"
    $AppId = "fr.celya.celyavox"
    $ProgId = "CelyaVox.tel"
    
    Write-Host "📝 Enregistrement en cours..."
    Write-Host "   App Path: $AppPath"
    Write-Host "   App ID: $AppId"
    Write-Host "   ProgId: $ProgId"
    
    # ===== 1. Enregistrer l'application dans App Paths =====
    $AppPathsKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\App Paths\CelyaVox.exe"
    New-Item -Path $AppPathsKey -Force | Out-Null
    Set-ItemProperty -Path $AppPathsKey -Name "(Default)" -Value "$AppPath" -Force
    Write-Host "✅ Enregistré dans App Paths"
    
    # ===== 2. Enregistrer le ProgId pour CelyaVox.tel =====
    $ProgIdPath = "HKCU:\Software\Classes\$ProgId"
    New-Item -Path $ProgIdPath -Force | Out-Null
    Set-ItemProperty -Path $ProgIdPath -Name "(Default)" -Value "Telephone Link" -Force
    
    # Icône (optionnel mais amélioré l'apparence dans Paramètres)
    New-Item -Path "$ProgIdPath\DefaultIcon" -Force | Out-Null
    Set-ItemProperty -Path "$ProgIdPath\DefaultIcon" -Name "(Default)" -Value "$AppPath,0" -Force
    
    # Commande d'ouverture
    New-Item -Path "$ProgIdPath\shell\open\command" -Force | Out-Null
    Set-ItemProperty -Path "$ProgIdPath\shell\open\command" -Name "(Default)" -Value "`"$AppPath`" `"%1`"" -Force
    
    Write-Host "✅ ProgId enregistré"
    
    # ===== 3. Enregistrer le protocole tel: lui-même =====
    $TelPath = "HKCU:\Software\Classes\tel"
    New-Item -Path $TelPath -Force | Out-Null
    Set-ItemProperty -Path $TelPath -Name "(Default)" -Value "URL:tel protocol" -Force
    Set-ItemProperty -Path $TelPath -Name "URL Protocol" -Value "" -Force
    
    # Shell\open\command avec le ProgId
    New-Item -Path "$TelPath\shell\open\command" -Force | Out-Null
    Set-ItemProperty -Path "$TelPath\shell\open\command" -Name "(Default)" -Value "`"$AppPath`" `"%1`"" -Force
    
    Write-Host "✅ Protocole tel: enregistré"
    
    # ===== 4. Enregistrer les capacités pour l'UI Paramètres Windows =====
    # Ceci permet à Windows de montrer l'application comme option dans Paramètres
    $CapabilitiesPath = "HKCU:\Software\Classes\Applications\CelyaVox.exe\Capabilities"
    New-Item -Path $CapabilitiesPath -Force | Out-Null
    Set-ItemProperty -Path $CapabilitiesPath -Name "ApplicationDescription" -Value "Telephone and VoIP application" -Force
    Set-ItemProperty -Path $CapabilitiesPath -Name "ApplicationName" -Value "CelyaVox" -Force
    
    # Déclarer que CelyaVox gère le protocole tel:
    $UrlAssocPath = "$CapabilitiesPath\URLAssociations"
    New-Item -Path $UrlAssocPath -Force | Out-Null
    Set-ItemProperty -Path $UrlAssocPath -Name "tel" -Value $ProgId -Force
    
    Write-Host "✅ Capacités enregistrées pour Paramètres Windows"
    
    # ===== 5. Optionnel: Associer l'utilisateur au gestionnaire par défaut =====
    # Cette clé dit à Windows quel ProgId utiliser par défaut pour tel:
    $UserChoicePath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.tel\UserChoice"
    # Note: UserChoice est protégée et ne peut généralement pas être écrite directement
    # Le shell Windows Params le fera lors du clic utilisateur
    
    Write-Host "✅ Protocole tel: complètement enregistré pour l'utilisateur courant"
    Write-Host ""
    Write-Host "L'application apparaîtra dans :"
    Write-Host "  • Paramètres → Applications → Applications par défaut → Protocoles"
    Write-Host "  • Clic droit sur lien tel: → Ouvrir avec"
    
}
catch {
    Write-Host "⚠️ Erreur lors de l'enregistrement du protocole tel:: $_" -ForegroundColor Yellow
}

# L'application crée les fichiers config au premier lancement
