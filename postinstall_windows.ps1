# postinstall_windows.ps1 - Script post-installation pour Windows

param(
    [string]$InstallDir = ""
)

Write-Host "[postinstall] Installation de CelyaVox reussie" -ForegroundColor Green

try {
    $AppPath = Join-Path $InstallDir "CelyaVox.exe"
    $ProgId = "CelyaVox.tel"
    
    Write-Host "Enregistrement en cours..."
    Write-Host "App Path: $AppPath"
    Write-Host "ProgId: $ProgId"
    
    # Verifier si on a les droits admin
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if (-not $isAdmin) {
        Write-Host "ATTENTION: Ce script necessite les droits administrateur pour HKLM"
        Write-Host "Continuant avec HKCU seulement..."
    }
    
    # ===== HKLM (Systeme) - Priorite pour Windows =====
    Write-Host "Enregistrement dans HKLM (systeme)..."
    
    # 1. Enregistrer dans RegisteredApplications
    New-Item -Path "HKLM:\Software\RegisteredApplications" -Force -ErrorAction SilentlyContinue | Out-Null
    Set-ItemProperty -Path "HKLM:\Software\RegisteredApplications" -Name "CelyaVox" -Value "Software\Classes\Applications\CelyaVox.exe\Capabilities" -Force -ErrorAction SilentlyContinue
    Write-Host "  Enregistre dans RegisteredApplications"
    
    # 2. Enregistrer les Capabilities
    $CapabilitiesPathHKLM = "HKLM:\Software\Classes\Applications\CelyaVox.exe\Capabilities"
    New-Item -Path $CapabilitiesPathHKLM -Force -ErrorAction SilentlyContinue | Out-Null
    Set-ItemProperty -Path $CapabilitiesPathHKLM -Name "ApplicationDescription" -Value "Telephone and VoIP application" -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $CapabilitiesPathHKLM -Name "ApplicationName" -Value "CelyaVox" -Force -ErrorAction SilentlyContinue
    
    # Enregistrer le support du protocole tel:
    $UrlAssocPathHKLM = "$CapabilitiesPathHKLM\URLAssociations"
    New-Item -Path $UrlAssocPathHKLM -Force -ErrorAction SilentlyContinue | Out-Null
    Set-ItemProperty -Path $UrlAssocPathHKLM -Name "tel" -Value $ProgId -Force -ErrorAction SilentlyContinue
    Write-Host "  Capacites enregistrees"
    
    # 3. Enregistrer le ProgId
    $ProgIdPathHKLM = "HKLM:\Software\Classes\$ProgId"
    New-Item -Path $ProgIdPathHKLM -Force -ErrorAction SilentlyContinue | Out-Null
    Set-ItemProperty -Path $ProgIdPathHKLM -Name "(Default)" -Value "Telephone Link" -Force -ErrorAction SilentlyContinue
    
    # Icone
    New-Item -Path "$ProgIdPathHKLM\DefaultIcon" -Force -ErrorAction SilentlyContinue | Out-Null
    Set-ItemProperty -Path "$ProgIdPathHKLM\DefaultIcon" -Name "(Default)" -Value "$AppPath,0" -Force -ErrorAction SilentlyContinue
    
    # Commande d'ouverture
    New-Item -Path "$ProgIdPathHKLM\shell\open\command" -Force -ErrorAction SilentlyContinue | Out-Null
    Set-ItemProperty -Path "$ProgIdPathHKLM\shell\open\command" -Name "(Default)" -Value "`"$AppPath`" `"%1`"" -Force -ErrorAction SilentlyContinue
    Write-Host "  ProgId $ProgId enregistre"
    
    # 4. Enregistrer le protocole tel: lui-meme
    $TelPathHKLM = "HKLM:\Software\Classes\tel"
    New-Item -Path $TelPathHKLM -Force -ErrorAction SilentlyContinue | Out-Null
    Set-ItemProperty -Path $TelPathHKLM -Name "(Default)" -Value "URL:tel protocol" -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $TelPathHKLM -Name "URL Protocol" -Value "" -Force -ErrorAction SilentlyContinue
    
    # Commande pour le protocole
    New-Item -Path "$TelPathHKLM\shell\open\command" -Force -ErrorAction SilentlyContinue | Out-Null
    Set-ItemProperty -Path "$TelPathHKLM\shell\open\command" -Name "(Default)" -Value "`"$AppPath`" `"%1`"" -Force -ErrorAction SilentlyContinue
    Write-Host "  Protocole tel: enregistre"
    
    # ===== HKCU (Utilisateur) - Fallback =====
    Write-Host "Enregistrement dans HKCU (utilisateur) comme fallback..."
    
    $TelPathHKCU = "HKCU:\Software\Classes\tel"
    New-Item -Path $TelPathHKCU -Force -ErrorAction SilentlyContinue | Out-Null
    Set-ItemProperty -Path $TelPathHKCU -Name "(Default)" -Value "URL:tel protocol" -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $TelPathHKCU -Name "URL Protocol" -Value "" -Force -ErrorAction SilentlyContinue
    
    New-Item -Path "$TelPathHKCU\shell\open\command" -Force -ErrorAction SilentlyContinue | Out-Null
    Set-ItemProperty -Path "$TelPathHKCU\shell\open\command" -Name "(Default)" -Value "`"$AppPath`" `"%1`"" -Force -ErrorAction SilentlyContinue
    
    Write-Host "  Protocole tel: enregistre (HKCU)"
    
    Write-Host ""
    Write-Host "Enregistrement termine avec succes"
    Write-Host "L'application apparaitra dans:"
    Write-Host "  - Parametres -> Applications -> Applications par defaut -> Protocoles"
    Write-Host "  - Comme option quand on clique sur un lien tel:"
}
catch {
    Write-Host "ERREUR lors de l'enregistrement du protocole tel:: $_" -ForegroundColor Yellow
}
