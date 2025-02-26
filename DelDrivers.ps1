########################################################
#                                                      #
#   Supprime tous les pilotes tiers (hors Microsoft)   #
#                   Auteur : ChatGPT                   #
#                                                      #
########################################################


# Exécuter en mode administrateur


$drivers = Get-WmiObject Win32_PnPSignedDriver | Where-Object {
    $_.Manufacturer -ne "Microsoft"
}

foreach ($driver in $drivers) {
    Write-Host "Suppression du pilote: $($driver.DeviceName) - $($driver.DriverVersion)"
    pnputil /delete-driver $driver.InfName /uninstall /force
}

Write-Host "Tous les pilotes tiers ont été supprimés. Redémarrez l'ordinateur."

