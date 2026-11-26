# postinstall_windows.ps1 - Script post-installation pour Windows

param(
    [string]$InstallDir = ""
)

# Vérifier si le script s'exécute avec les droits admin
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "[AVERTISSEMENT] Ce script necessite les droits administrateur." -ForegroundColor Yellow
    Write-Host "[ACTION] Relancement du script en tant qu'administrateur..." -ForegroundColor Yellow
    
    # Recréer la commande avec les mêmes paramètres
    $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    if ($InstallDir) {
        $arguments += " -InstallDir `"$InstallDir`""
    }
    
    # Relancer le script avec élévation
    Start-Process -FilePath powershell.exe -ArgumentList $arguments -Verb RunAs -Wait
    exit
}

Write-Host "[postinstall] Installation de CelyaVox reussie" -ForegroundColor Green

try {
    $AppPath = Join-Path $InstallDir "CelyaVox.exe"
    $Protocols = @("tel", "callto")
    $OpenCommand = "`"$AppPath`" `"%1`""

    Write-Host "Enregistrement en cours..."
    Write-Host "App Path: $AppPath"

    # Enregistrement HKLM (Systeme) - Priorite pour Windows
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

    $UrlAssocPathHKLM = "$CapabilitiesPathHKLM\URLAssociations"
    New-Item -Path $UrlAssocPathHKLM -Force -ErrorAction SilentlyContinue | Out-Null

    foreach ($Protocol in $Protocols) {
        $ProgId = "CelyaVox.$Protocol"

        # Declarer le support du protocole dans les Capabilities
        Set-ItemProperty -Path $UrlAssocPathHKLM -Name $Protocol -Value $ProgId -Force -ErrorAction SilentlyContinue

        # 3. Enregistrer le ProgId
        $ProgIdPathHKLM = "HKLM:\Software\Classes\$ProgId"
        New-Item -Path $ProgIdPathHKLM -Force -ErrorAction SilentlyContinue | Out-Null
        Set-ItemProperty -Path $ProgIdPathHKLM -Name "(Default)" -Value "Telephone Link" -Force -ErrorAction SilentlyContinue
        New-Item -Path "$ProgIdPathHKLM\DefaultIcon" -Force -ErrorAction SilentlyContinue | Out-Null
        Set-ItemProperty -Path "$ProgIdPathHKLM\DefaultIcon" -Name "(Default)" -Value "$AppPath,0" -Force -ErrorAction SilentlyContinue
        New-Item -Path "$ProgIdPathHKLM\shell\open\command" -Force -ErrorAction SilentlyContinue | Out-Null
        Set-ItemProperty -Path "$ProgIdPathHKLM\shell\open\command" -Name "(Default)" -Value $OpenCommand -Force -ErrorAction SilentlyContinue
        Write-Host "  ProgId $ProgId enregistre"

        # 4. Enregistrer le protocole lui-meme (HKLM puis HKCU en fallback)
        foreach ($Root in @("HKLM:", "HKCU:")) {
            $ProtocolPath = "$Root\Software\Classes\$Protocol"
            New-Item -Path $ProtocolPath -Force -ErrorAction SilentlyContinue | Out-Null
            Set-ItemProperty -Path $ProtocolPath -Name "(Default)" -Value "URL:$Protocol protocol" -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $ProtocolPath -Name "URL Protocol" -Value "" -Force -ErrorAction SilentlyContinue
            New-Item -Path "$ProtocolPath\shell\open\command" -Force -ErrorAction SilentlyContinue | Out-Null
            Set-ItemProperty -Path "$ProtocolPath\shell\open\command" -Name "(Default)" -Value $OpenCommand -Force -ErrorAction SilentlyContinue
            Write-Host "  Protocole ${Protocol}: enregistre ($Root)"
        }
    }

    Write-Host ""
    Write-Host "Enregistrement termine avec succes"
    Write-Host "L'application apparaitra dans:"
    Write-Host "  - Parametres -> Applications -> Applications par defaut -> Protocoles"
    Write-Host "  - Comme option quand on clique sur un lien tel: ou callto:"
}
catch {
    Write-Host "ERREUR lors de l'enregistrement des protocoles tel:/callto: : $_" -ForegroundColor Yellow
}
