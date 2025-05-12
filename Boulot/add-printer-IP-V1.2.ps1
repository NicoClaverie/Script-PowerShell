#############################################
#                                           #
#      Script pour ajout d'imprimantes      #
#                Version 1.1                #
#                                           #
#############################################


do {

# Permet une elevation de privilege
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Host "Redemarrage du script avec privileges administratifs..." -ForegroundColor Yellow
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

        # Verification si l'entree est un nombre entier entre 1 et 4
        if ($choixPilote -match '^\d+$' -and 1..4 -contains [int]$choixPilote) {
            $choixValide = $true
            # Determination du chemin du pilote en fonction du choix
            switch ($choixPilote) {
                1 {
                    $cheminPilote = "C:\Imprimantes\CANON\GPlus_PCL6_Driver_V230_W64_00\Driver"
                    $versionPilote = "Canon Generic Plus PCL6" 
                }
                2 {
                    $cheminPilote = "C:\Imprimantes\HP\pcl6-x64-6.9.0.24630"
                    $versionPilote = "HP Universal Printing PCL 6" 
                }
                3 {
                    $cheminPilote = "C:\Imprimantes\LEXMARK\Lexmark_Universal_v2_XL_3_0_2\Drivers\Print\GDI" 
                    $versionPilote = "Lexmark Universal v2 XL" 
                }
                4 {
                    $cheminPilote = "C:\Imprimantes\XEROX\UNIV_5.1035.2.0_PCL6_x64_Driver.inf"
                    $versionPilote = "Xerox Global Print Driver PCL6" 
                }
            }
        }
        else {
            Write-Host "Mauvais choix. Veuillez saisir un nombre entre 1 et 4." -ForegroundColor Red
        }
    }

    # Affichage des resultats pour verification
    Write-Host "Chemin du pilote selectionne : $cheminPilote"
    Write-Host "Version du pilote selectionnee : $versionPilote"

    # Verification de la presence du pilote
    $piloteExistant = Get-PrinterDriver | Where-Object { $_.Name -eq $versionPilote }

    if ($piloteExistant) {
        Write-Host "Le pilote '$versionPilote' est dejà installe." -ForegroundColor Green
    }
    else {
        Write-Host "Le pilote '$versionPilote' n'est pas installe. Installation en cours..." -ForegroundColor Yellow
        
        # Passe tout le repertoire en revu pour prendre tout les .inf en compte
        if (Test-Path $cheminPilote) {
        Get-ChildItem -Path $cheminPilote -Filter "*.inf" | ForEach-Object {
            pnputil /add-driver $_.FullName /install
        }
            Write-Host "Pilote '$versionPilote' installe avec succes !" -ForegroundColor Green
        }
        else {
            Write-Host "Le fichier de pilote n'a pas ete trouve. Verifiez le chemin." -ForegroundColor Red
            Pause
            Exit
        }
    }

    # Creation du port et ajout de l'imprimante
    if ($choixPilote -eq 2) {
        Add-PrinterDriver -Name $versionPilote
        Add-PrinterPort -Name $imprimante -PrinterHostAddress $adresseIP
        Add-Printer -Name "$imprimante" -PortName $imprimante -DriverName $versionPilote


        # Verification que les imprimantes ont bien ete ajoutees
    $imprimanteAjoutee = Get-Printer | Where-Object { $_.Name -eq "$imprimante" }
    
    if ($imprimanteAjoutee) {
        Write-Host "L'imprimante '$imprimante a ete ajoutees avec succes !" -ForegroundColor Green
    }
    else {
            Write-Host "Erreur : L'imprimante '$imprimante' n'a pas ete trouvee." -ForegroundColor Red
        }
    }
    
    else {
        Add-PrinterDriver -Name $versionPilote
        Add-PrinterPort -Name $imprimante -PrinterHostAddress $adresseIP
        Add-Printer -Name "$imprimante COULEUR" -PortName $imprimante -DriverName $versionPilote
        Add-Printer -Name "$imprimante NB" -PortName $imprimante -DriverName $versionPilote
    
    # Verification que les imprimantes ont bien ete ajoutees
    $imprimanteCOULEURAjoutee = Get-Printer | Where-Object { $_.Name -eq "$imprimante COULEUR" }
    $imprimanteNBAjoutee = Get-Printer | Where-Object { $_.Name -eq "$imprimante NB" }

    if ($imprimanteCOULEURAjoutee -and $imprimanteNBAjoutee) {
        Write-Host "Les imprimantes '$imprimante COULEUR' et '$imprimante NB' ont ete ajoutees avec succes !" -ForegroundColor Green
    }
    else {
        Write-Host "Une ou plusieurs imprimantes n'ont pas ete ajoutees correctement." -ForegroundColor Red
        if (-not $imprimanteCOULEURAjoutee) {
            Write-Host "Erreur : L'imprimante '$imprimante COULEUR' n'a pas ete trouvee." -ForegroundColor Red
        }
        if (-not $imprimanteNBAjoutee) {
            Write-Host "Erreur : L'imprimante '$imprimante NB' n'a pas ete trouvee." -ForegroundColor Red
        }
    }
}


    # Demande à l'utilisateur s'il souhaite ajouter une autre imprimante
    $reponse = Read-Host "Souhaitez-vous ajouter une autre imprimante ? (O/N)"
} while ($reponse -match '^(O|o|Oui|oui)$')

Write-Host "Script termine. Bonne journee !" -ForegroundColor Green






