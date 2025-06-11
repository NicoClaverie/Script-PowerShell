Write-Host "Lancement de la surveillance du signal Wi-Fi..."
Write-Host "Appuyez sur Ctrl+C pour arrêter le script."
Write-Host "--------------------------------------------------"

while ($true) {
    # Récupère la ligne contenant la force du signal
    $signalLine = (netsh wlan show interfaces) -match "^\s+Signal"
    
    # Vérifie si une connexion Wi-Fi est active
    if ($signalLine) {
        $signalStrength = $signalLine -replace "^\s+Signal\s+:\s+", ""
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Write-Host "$timestamp --- Force du signal : $($signalStrength.Trim())"
    } else {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Write-Host "$timestamp --- Wi-Fi non connecté ou interface introuvable."
    }
    
    # Pause de 2 secondes avant la prochaine mesure
    Start-Sleep -Seconds 1
}