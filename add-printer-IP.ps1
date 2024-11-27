#############################################
#                                           #
#      Script pour ajout d'imprimantes      #
#                                           #
#############################################


### A lancer en mode administrateur ###

do {

    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Host "Redémarrage du script avec privilèges administratifs..." -ForegroundColor Yellow
        $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Path)`""
        Start-Process -FilePath "powershell.exe" -ArgumentList $arguments -Verb RunAs
        Exit
    }


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
                    $cheminPilote = "C:\Imprimantes\CANON\GPlus_PCL6_Driver_V230_W64_00\Driver3"#CNP60MA64.INF"
                    $versionPilote = "Canon Generic Plus PCL6" 
                }
                2 {
                    $cheminPilote = "C:\Imprimantes\HP\pcl6-x64-6.9.0.24630"#\hpbuio200l.inf" 
                    $versionPilote = "HP Universal Printing PCL 6" 
                }
                3 {
                    $cheminPilote = "C:\imprimantes\Lexmark.inf" 
                    $versionPilote = "  " 
                }
                4 {
                    $cheminPilote = "C:\Imprimantes\XEROX\UNIV_5.703.12.0_PCL6_x64\UNIV_5.703.12.0_PCL6_x64_Driver.inf"#\x3UNIVX.inf" 
                    $versionPilote = "Xerox Global Print Driver PCL6" 
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
        Get-ChildItem -Path $cheminPilote -Filter "*.inf" | ForEach-Object 
        {
            pnputil /add-driver $_.FullName /install
        }
           # pnputil /add-driver $cheminPilote /subdirs /install
            Write-Host "Pilote '$versionPilote' installé avec succès !" -ForegroundColor Green
        }
        else {
            Write-Host "Le fichier de pilote n'a pas été trouvé. Vérifiez le chemin." -ForegroundColor Red
            Pause
            Exit
        }
    }

    # Création du port et ajout de l'imprimante
    Add-PrinterDriver -Name $versionPilote
    Add-PrinterPort -Name $imprimante -PrinterHostAddress $adresseIP
    Add-Printer -Name "$imprimante COULEUR" -PortName $imprimante -DriverName $versionPilote
    Add-Printer -Name "$imprimante NB" -PortName $imprimante -DriverName $versionPilote

    # Vérification que les imprimantes ont bien été ajoutées
    $imprimanteCOULEURAjoutee = Get-Printer | Where-Object { $_.Name -eq "$imprimante COULEUR" }
    $imprimanteNBAjoutee = Get-Printer | Where-Object { $_.Name -eq "$imprimante NB" }

    if ($imprimanteCOULEURAjoutee -and $imprimanteNBAjoutee) {
        Write-Host "Les imprimantes '$imprimante COULEUR' et '$imprimante NB' ont été ajoutées avec succès !" -ForegroundColor Green
    }
    else {
        Write-Host "Une ou plusieurs imprimantes n'ont pas été ajoutées correctement." -ForegroundColor Red
        if (-not $imprimanteCOULEURAjoutee) {
            Write-Host "Erreur : L'imprimante '$imprimante COULEUR' n'a pas été trouvée." -ForegroundColor Red
        }
        if (-not $imprimanteNBAjoutee) {
            Write-Host "Erreur : L'imprimante '$imprimante NB' n'a pas été trouvée." -ForegroundColor Red
        }
    }


    # Demande à l'utilisateur s'il souhaite ajouter une autre imprimante
    $reponse = Read-Host "Souhaitez-vous ajouter une autre imprimante ? (O/N)"
} while ($reponse -match '^(O|o|Oui|oui)$')

Write-Host "Script terminé. Bonne journée !" -ForegroundColor Green






