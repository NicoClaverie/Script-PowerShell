#####################################################
#                                                   #
#       Script pour import des profiles Wi-Fi       #
#                                                   #
#####################################################


# Fonction pour afficher une boîte de dialogue de sélection de dossier
function Select-Folder {
    Add-Type -AssemblyName System.Windows.Forms
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderBrowser.Description = "Sélectionnez le dossier contenant les fichiers XML"
    $folderBrowser.ShowNewFolderButton = $false

    if ($folderBrowser.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        return $folderBrowser.SelectedPath
    }
    else {
        return $null
    }
}

# Fonction principale pour gérer les importations
function Import-WiFiProfiles {
    while ($true) {
        # Demander à l'utilisateur de sélectionner un dossier
        $importPath = Select-Folder

        if ([string]::IsNullOrWhiteSpace($importPath)) {
            Write-Host "Aucun dossier sélectionné. Script terminé."
            return
        }

        Write-Host "Dossier sélectionné : $importPath"

        # Vérifier si des fichiers XML sont présents dans le dossier
        $xmlFiles = Get-ChildItem -Path $importPath -Filter "*.xml" -ErrorAction SilentlyContinue

        if ($xmlFiles) {
            # Si des fichiers XML sont présents, importer les profils
            foreach ($file in $xmlFiles) {
                Write-Host "Importation du profil : $($file.Name)"
                netsh wlan add profile filename="$($file.FullName)"
            }
            Write-Host "Tous les profils Wi-Fi ont été importés avec succès."
            Pause
            Exit
        }
        else {
            # Aucun fichier XML trouvé, demander si on continue ou quitte
            $choice = Read-Host "Aucun fichier XML trouvé dans ce dossier. Voulez-vous sélectionner un autre dossier ? (O/N)"
            if ($choice -match "^[Nn]$") {
                Exit
            }
        }
    }
}

# Lancer la fonction principale
Import-WiFiProfiles
