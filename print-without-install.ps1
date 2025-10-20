#########################################################################
#                                                                       #
#   Script pour imprimer sans avoir besoin d'installer une imprimante   #
#                                                                       #
#########################################################################


# --- Paramètres à ajuster ---
$PrinterIP = "192.110.58.48"      # Remplacer par l'IP de votre imprimante
$PrinterPort = 9100               # Le port standard pour l'impression Raw (parfois 515 ou autre)
$TextToPrint = "Bonjour, ceci est un test d'impression RAW depuis PowerShell."

# Facultatif : Charger le contenu d'un fichier (ex: un fichier de codes ESC/POS)
# $FileContent = Get-Content -Path "C:\MonFichierAImprimer.txt" -Encoding ASCII
# $TextToPrint = $FileContent

# --- Exécution ---
try {
    # 1. Créer la connexion TCP
    $TCPClient = New-Object System.Net.Sockets.TcpClient
    $TCPClient.Connect($PrinterIP, $PrinterPort)

    if ($TCPClient.Connected) {
        Write-Host "Connexion etablie a $($PrinterIP):$($PrinterPort). Envoi des donnees..."

        # 2. Obtenir le flux de données
        $NetworkStream = $TCPClient.GetStream()

        # 3. Convertir le texte en tableau d'octets (ASCII est souvent necessaire pour Raw)
        $Encoding = [System.Text.Encoding]::ASCII
        $Bytes = $Encoding.GetBytes($TextToPrint + "`r`n") # Ajouter un retour a la ligne

        # 4. Envoyer les octets
        $NetworkStream.Write($Bytes, 0, $Bytes.Length)

        Write-Host "Impression envoyee avec succes."
    }
}
catch {
    Write-Error "Erreur lors de l'impression : $($_.Exception.Message)"
}
finally {
    # 5. Fermer la connexion
    if ($NetworkStream) { $NetworkStream.Dispose() }
    if ($TCPClient) { $TCPClient.Close() }
}
