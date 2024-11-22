# Demande des informations à l'utilisateur
$imprimante = Read-Host "Entrez le nom de l'imprimante"
$adresseIP = Read-Host "Entrez l'adresse IP de l'imprimante"

# Menu interactif pour le choix du pilote
Write-Host "Sélectionnez le fabricant du pilote :"
$choixValide = $false

while (-not $choixValide) {
    Write-Host "1. Canon"
    Write-Host "2. HP"
    Write-Host "3. Lexmark"
    Write-Host "4. Xerox"
    $choixPilote = Read-Host "Votre choix ?"

    # Vérification si l'entrée est un nombre entier entre 1 et 4
    if ($choixPilote -match '^\d+$' -and 1..4 -contains [int]$choixPilote) {
        $choixValide = $true
        # Détermination du chemin du pilote en fonction du choix
        switch ($choixPilote) {
            1 { $cheminPilote = "C:\Imprimantes\CANON\GPlus_PCL6_Driver_V230_W64_00\Driver\CNP60MA64.INF" }
            2 { $cheminPilote = "C:\imprimantes\HP.inf" }
            3 { $cheminPilote = "C:\imprimantes\Lexmark.inf" }
            4 { $cheminPilote = "C:\imprimantes\Xerox.inf" }
        }
    } else {
        Write-Host "Mauvais choix. Veuillez saisir un nombre entre 1 et 4." -ForegroundColor Red
    }
}

# À ce stade, $choixPilote contient une valeur valide et $cheminPilote est défini
Write-Host "Vous avez choisi le pilote : $($cheminPilote)"
# Vérification de l'existence du fichier de pilote et ajout de l'imprimante
if (Test-Path $cheminPilote) {
    Add-PrinterDriver -Name "Canon Generic Plus PCL6" -InfPath $cheminPilote
    Add-PrinterPort -Name $imprimante -PrinterHostAddress $adresseIP
    Add-Printer -Name $imprimante -PortName "$imprimante" -DriverName $cheminPilote
    Write-Host "Imprimante ajoutée avec succès !" 
} else {
    Write-Host "Le fichier de pilote n'a pas été trouvé. Vérifiez le chemin."
}

# Création du port avec le nom de base de l'imprimante
# Add-PrinterPort -Name $imprimante -PrinterHostAddress $adresseIP

# Ajout des deux imprimantes sur le même port
# Add-Printer -Name "$imprimante Couleur" -PortName $imprimante -DriverInfPath $cheminPilote
# Add-Printer -Name "$imprimante NB" -PortName $imprimante -DriverInfPath $cheminPilote

Write-Host "Les imprimantes ont été ajoutées avec succès !"

