#######################################################################################
#                                                                                     #
#  Script pour mesurer la force d'un signal wifi et le mettre dans un fichier de log  #
#                                                                                     #
#                              Auteur : Nicolas CLAVERIE                              #
#                                                                                     #
#######################################################################################


Write-Host "MONITORING FORCE SIGNAL WIFI"
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

# Debut de la boucle infini pour mesurer la force du signal
while ($true) {
    # Récupération de l'information sur la force du signal
    $signalLine = (netsh wlan show interfaces) -match "^\s+Signal"
    
    # Mise en place de l'horodatage 
    $timestamp = Get-Date -Format "HH:mm:ss"

    # Verification de la présence du signal wifi
    if ($signalLine) {
        $signalStrength = $signalLine -replace "^\s+Signal\s+:\s+", ""
        Write-Host "$timestamp - Force du signal : $signalStrength"
        Add-Content -path $LogFilePath -Value "$timestamp - Force du signal : $signalStrength"
    }
    else {
        Write-Host "$timestamp - WiFi non connecte ou interface introuvable"
        Add-Content -path $LogFilePath -Value "$timestamp - WiFi non connecte ou interface introuvable"
    }
    # Pause de 2 secondes entre chaque relevé
    Start-Sleep -Seconds 2
}
