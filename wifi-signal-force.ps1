#######################################################################################
#                                                                                     #
#  Script pour mesurer la force d'un signal wifi et le mettre dans un fichier de log  #
#                                                                                     #
#                              Auteur : Nicolas CLAVERIE                              #
#                                Aide : Gemini                                        #
#                                                                                     #
#######################################################################################

# Configuration de l'encodage pour bien gérer les accents de netsh
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "MONITORING FORCE SIGNAL & BORNE WIFI"
Write-Host " "

# Formatage de la date pour le nom du fichier de log
$today = (Get-Date).ToString("yyMMdd")

# Dossier pour les logs
$LogDirectory = Join-Path $Env:USERPROFILE "Desktop\Log-wifi-force"

# Demande d'ajout de description si besoin
$AddOther = Read-Host "Nom ou description pour le fichier de log (Faire entree si aucun)"

# Variable de localisation du fichier de log
$LogFilePath = Join-Path -Path $LogDirectory -ChildPath "log-$today-$AddOther.txt"

Write-Host " " 
Write-Host "-------------------------------------"
Write-Host "Debut monitoring force du signal WiFi"
Write-host "Faire ctrl+C pour stopper le script"
Write-host "Le fichier de log est sur $LogFilePath"
Write-Host "-------------------------------------"
Write-Host " "

# Verification ou creation du dossier pour les logs
if (-not (Test-Path -path $LogDirectory -PathType Container)) {
    New-Item -Path $LogDirectory -ItemType Directory -Force | Out-Null
}

# Debut de la boucle infinie
while ($true) {
    # Récupération de netsh
    $wlanInfo = netsh wlan show interfaces

    # Extraction du signal
    $signalLine = $wlanInfo -match "^\s+Signal"
    
    # Extraction de la borne : on cherche "Service Set Identifier" ou "BSSID" 
    # pour éviter tout conflit avec les caractères 'accès' ou 'd’'
    $bssidLine  = $wlanInfo -match "Service Set Identifier|BSSID"

    # Horodatage
    $timestamp = Get-Date -Format "HH:mm:ss"

    # Vérification
    if ($signalLine -and $bssidLine) {
        # Split sur le dernier caractère ':' pour récupérer l'adresse MAC/la valeur propre
        $signalStrength = ($signalLine -split ":")[-1].Trim()
        
        # On découpe sur le ':' pour isoler l'adresse MAC (24:1f:bd...)
        $bssidRaw = ($bssidLine -split ":")[1..6] -join ":"
        $bssid    = $bssidRaw.Trim()

        $logMessage = "$timestamp - Borne (BSSID) : $bssid | Signal : $signalStrength"

        Write-Host $logMessage
        Add-Content -path $LogFilePath -Value $logMessage
    }
    else {
        $logMessage = "$timestamp - WiFi non connecte ou interface introuvable"
        Write-Host $logMessage
        Add-Content -path $LogFilePath -Value $logMessage
    }

    # Pause de 2 secondes
    Start-Sleep -Seconds 2
}
