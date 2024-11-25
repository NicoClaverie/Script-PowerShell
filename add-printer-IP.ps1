# Demande des informations à l'utilisateur
$imprimante = Read-Host "Nom de l'imprimante"
$adresseIP = Read-Host "Adresse IP de l'imprimante"

# Menu interactif pour le choix du pilote
Write-Host "Pilote :"
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
            1 {
                $cheminPilote = "C:\Imprimantes\CANON\GPlus_PCL6_Driver_V230_W64_00\Driver\CNP60MA64.INF"
                $versionPilote = "Canon Generic Plus PCL6" 
            }
            2 {
                $cheminPilote = "C:\imprimantes\HP.inf" 
                $versionPilote = "  " 
            }
            3 {
                $cheminPilote = "C:\imprimantes\Lexmark.inf" 
                $versionPilote = "  " 
            }
            4 {
                $cheminPilote = "C:\Imprimantes\XEROX\UNIV_5.703.12.0_PCL6_x64\UNIV_5.703.12.0_PCL6_x64_Driver.inf\x3UNIVX.inf" 
                $versionPilote = "  " 
            }
        }
    }
    else {
        Write-Host "Mauvais choix. Veuillez saisir un nombre entre 1 et 4." -ForegroundColor Red
    }
}

# Affichage des résultats pour vérification
Write-Host "Chemin du pilote sélectionné : $cheminPilote"
Write-Host "Version du pilote sélectionnée : $versionPilote"

# Vérification de la présence du pilote
$piloteExistant = Get-PrinterDriver | Where-Object { $_.Name -eq $versionPilote }

if ($piloteExistant) {
    Write-Host "Le pilote '$versionPilote' est déjà installé." -ForegroundColor Green
}
else {
    Write-Host "Le pilote '$versionPilote' n'est pas installé. Installation en cours..." -ForegroundColor Yellow
    if (Test-Path $cheminPilote) {
        pnputil /add-driver $cheminPilote /install
        Write-Host "Pilote '$versionPilote' installé avec succès !" -ForegroundColor Green
    }
    else {
        Write-Host "Le fichier de pilote n'a pas été trouvé. Vérifiez le chemin." -ForegroundColor Red
        Exit
    }
}

# Création du port et ajout de l'imprimante
Add-PrinterPort -Name $imprimante -PrinterHostAddress $adresseIP
Add-Printer -Name "$imprimante Couleur" -PortName $imprimante -DriverName $versionPilote
Add-Printer -Name "$imprimante NB" -PortName $imprimante -DriverName $versionPilote

Write-Host "Les imprimantes '$imprimante Couleur' et '$imprimante NB' ont été ajoutées avec succès !" -ForegroundColor Green
