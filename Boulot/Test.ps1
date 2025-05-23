### TRAVAIL EN COURS ### 

function menu {
    while ($true) {
        Write-Host "Script de mise en forme et d'extraction d'information"
        Write-Host "1. Mise en forme fichier XLSX"
        Write-Host "2. Extraction des mails pour la prise de contact"
        Write-Host "3. Faire les deux"
        Write-Host "Q. Sortir du script"
        Write-Host " "
        
        $ChoixMenu = Read-Host "Choix ? "

        switch ($ChoixMenu) {
            '1' {
                XlsSelect
                OutXls
                XlsToCSV
                CSVToFormatXLSX
            }
            '2' {
                XlsSelect
                OutMail
                XlsToCSV
                TriMail
            }
            '3' {
                XlsSelect
                OutXls
                OutMail
                XlsToCSV
                CSVToFormatXLSX
                TriMail
            }
            'q' {
                Exit
            }
        }

    }
}


function XlsSelect {
    Add-Type -AssemblyName "System.Windows.Forms"

# Créer une boîte de dialogue pour sélectionner le fichier
$dialog = New-Object System.Windows.Forms.OpenFileDialog
$dialog.Filter = "Fichiers Excel (*.xlsx)|*.xlsx|Tous les fichiers (*.*)|*.*"  # Filtre pour les fichiers .xlsx
$dialog.Title = "Sélectionnez un fichier Excel"

# Afficher la boîte de dialogue et obtenir le chemin du fichier
if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
    $cheminFichierXls = $dialog.FileName
    Write-Host "Fichier sélectionné : $cheminFichierXls"
} else {
    Write-Host "Aucun fichier sélectionné."
}
}


function OutXls {

    Add-Type -AssemblyName "System.Windows.Forms"

# Boîte de dialogue pour sélectionner un dossier
$folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
$folderDialog.Description = "Sélectionnez le dossier de destination pour le fichier XLS"

if ($folderDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
    $cheminDossierXls = $folderDialog.SelectedPath
    Write-Host "Dossier sélectionné : $cheminDossierXls"
} else {
    Write-Host "Aucun dossier sélectionné."
}

}

function OutMail {

    Add-Type -AssemblyName "System.Windows.Forms"

# Boîte de dialogue pour sélectionner un dossier
$folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
$folderDialog.Description = "Sélectionnez le dossier de destination pour les CSV de Mail"

if ($folderDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
    $cheminDossierMail = $folderDialog.SelectedPath
    Write-Host "Dossier sélectionné : $cheminDossierMail"
} else {
    Write-Host "Aucun dossier sélectionné."
}

}






function XlsToCSV {
################################################################################################
#                                                                                              #
#  Script pour modifier un fichier XLSX en CSV sans accent, ni caractere speciaux, ni espace   #
#                                                                                              #
################################################################################################


# Prérequis : Installer le module ImportExcel si ce n'est pas déjà fait
Install-Module -Name ImportExcel -Scope CurrentUser


# Chemin d'accès du fichier XLSX d'entrée et du fichier CSV de sortie
$fichierXLSX = $cheminFichierXls
$fichierCSV = "$env:TEMP\lot2.csv"

# Charger le contenu du fichier XLSX
$data = Import-Excel -Path $fichierXLSX


# Filtrer les lignes où la colonne "numéro" n'est pas vide
$filteredData = $data | Where-Object { $_.NUMERO -ne $null -and $_.NUMERO -ne "" }


# Exporter les données dans un fichier CSV avec encodage UTF-8 avec BOM
$filteredData | Export-Csv -Path $fichierCSV -Encoding UTF8 -NoTypeInformation


# Définition de la fonction Remove-StringSpecialCharacters
function Remove-StringSpecialCharacters {
    param ([string]$String)

    Begin {}

    Process {

        $String = [Text.Encoding]::ASCII.GetString([Text.Encoding]::GetEncoding("Cyrillic").GetBytes($String))

        $String = $String  `
            -replace '/', '' `
            -replace '\*', '' `
            -replace "'", "" `
            -replace "°", " " `
            -replace "\)", "" `
            -replace "\(", ""    
        #-replace '-', ''
        #-replace ' ', '' `
    }

    End {
        return $String
    }
}


# Lire le contenu du fichier d'entrée
$contenu = Get-Content $fichierCSV

# Appliquer la fonction Remove-StringSpecialCharacters à chaque ligne
$contenuTraite = foreach ($ligne in $contenu) {
    Remove-StringSpecialCharacters -String $ligne
}

# Écrire les lignes traitées dans un nouveau fichier
$contenuTraite | Out-File -FilePath $fichierCSV -Encoding utf8


###############################################################################
#                                                                             #
#    Ajoute les colonnes Mot de passe, Imprimante, Logiciel et commentaire    #
#                                                                             #
###############################################################################


# Rappel le fichier CSV pour modification
$FileSource = Import-Csv $fichierCSV

# Ajouter les colonnes mot de passe, imprimante, logiciel

foreach ($ligne in $FileSource) {
    $ligne | Add-Member -MemberType NoteProperty -Name "Mot de passe" -Value ""
    $ligne | Add-Member -MemberType NoteProperty -Name "Imprimante" -Value ""
    $ligne | Add-Member -MemberType NoteProperty -Name "Logiciel" -Value ""
    $ligne | Add-Member -MemberType NoteProperty -Name "Commentaire" -Value ""
}


# Écrire les lignes traitées dans un nouveau fichier
$FileSource | Export-Csv -Path $fichierCSV -Delimiter "," -NoTypeInformation
}


############################
function CSVToFormatXLSX {

####################################################################################
#                                                                                  #
#     Script PowerShell pour formater le fichier xlsx du materiel a renouveler     #
#                                   Version 0.0                                    #
#                                                                                  #
####################################################################################

# Chemin du fichier CSV source
$csvFile = "$env:TEMP\lot2.csv"

# Chemin du fichier Excel de sortie
$xlsxFile = "$env:USERPROFILE\Documents\test\lot2.xlsx"

# Charger les données CSV existantes
$data = Import-Csv -Path $csvFile -Delimiter ","


# Charger les données CSV et sélectionner uniquement les colonnes Entreprise et Site
$Extract = Import-Csv -Path $csvFile -Delimiter "," | Select-Object Entreprise, Site

# Obtenir les combinaisons uniques d'Entreprise et de Site, puis trier par ordre alphabétique
$uniqueCombinations = $Extract | Select-Object Entreprise, Site -Unique |
Sort-Object { "$($_.Site) - $($_.Entreprise)" }

# Charger les termes uniques de la colonne Libelle
$uniqueLibelles = $data | Select-Object Libelle -Unique |
Sort-Object Libelle

# Supprimer l'ancien fichier Excel s'il existe
if (Test-Path $xlsxFile) {
    Remove-Item $xlsxFile
}

# Ajouter les feuilles par terme unique dans la colonne Libelle
foreach ($libelle in $uniqueLibelles) {
    # Nom de la feuille : Libelle
    $sheetName = $libelle.Libelle
    
    # Filtrer les lignes correspondant à ce Libelle
    $filteredData = $data | Where-Object {
        $_.Libelle -eq $libelle.Libelle
    } | Select-Object Site, Entreprise, Type, Libelle, Numero, Utilisateur, "Mot de passe", Imprimante, Logiciel, Commentaire
    
    # Exporter les données dans une feuille dédiée
    $filteredData | Export-Excel -Path $xlsxFile -WorksheetName $sheetName -Append
}

# Créer une feuille pour chaque combinaison unique, dans l'ordre alphabétique
foreach ($combination in $uniqueCombinations) {
    # Nom de la feuille : Entreprise + Site
    $sheetName = "$($combination.Site) - $($combination.Entreprise)"
    
    # Limiter la longueur des noms de feuille (Excel limite à 31 caractères)
    $sheetName = $sheetName.Substring(0, [Math]::Min(31, $sheetName.Length))
    
    # Filtrer les lignes correspondant à cette combinaison et ne garder que les colonnes pertinentes
    $filteredData = Import-Csv -Path $csvFile -Delimiter "," |
    Select-Object Site, Entreprise, Type, Libelle, Numero, Utilisateur, "Mot de passe", Imprimante, Logiciel, Commentaire | Where-Object {
        $_.Entreprise -eq $combination.Entreprise -and $_.Site -eq $combination.Site
    }
    
    # Exporter les données dans une feuille dédiée
    $filteredData | Export-Excel -Path $xlsxFile -WorksheetName $sheetName -Append
}

Write-Host "Fichier Excel généré avec succès, feuilles classées par ordre alphabétique : $xlsxFile"
}



function TriMail {
########################################################################################################
#                                                                                                      #
#     Script pour comparer les utilisateurs du lot en cours et les adresses mail présent dans GLPI     #
#                                                                                                      #
########################################################################################################

# Chemins des fichiers CSV
$ExtractLot = Import-Csv "$env:TEMP\lot2.csv" -Delimiter "," | Select-Object UTILISATEUR, LIBELLE, NUMERO
$ExtractMail = Import-Csv "$env:userprofile\documents\test\glpi.csv" -Delimiter ";" | Select-Object "Adresses de messagerie"
$CSVSortieMail = "$env:USERPROFILE\documents\test\mail-a-envoye.csv"
$CSVSortieRestant = "$env:USERPROFILE\documents\test\utilisateur-restant.csv"

# Fonction pour extraire le prénom + nom (derniers mots de la colonne Utilisateur)
function Extraire-Nom {
    param ([string]$texte)
    $mots = $texte -split " "
    if ($mots.Count -ge 2) {
        return "$($mots[-2]) $($mots[-1])"  # Derniers mots = Prénom + Nom
    }
    return $texte
}

# Filtrer les ordinateurs uniquement
$ExtractLotFiltre = $ExtractLot | Where-Object {
    ($_ -notmatch "ECRAN IIYAMA prolite 22") -and ($_ -notmatch "DOCK Hybrid USB-C")
}

# Mise en forme pour n'avoir que les prenom.nom des adresses mail
$ListeMail = $ExtractMail | ForEach-Object {
    ($_."Adresses de messagerie" -split "@")[0].ToLower()  # Partie avant @ en minuscules
}

# Listes pour stocker les résultats
$mailAEnvoye = @()
$utilisateurRestant = @()

# Comparaison des utilisateurs avec la liste des e-mails
foreach ($ligne1 in $ExtractLotFiltre) {
    $nomFormatEmail = Extraire-Nom $ligne1.UTILISATEUR

    # Remplacer l'espace par un point pour correspondre au format prénom.nom
    $nomFormatEmail = $nomFormatEmail -replace " ", "."  # Remplacement de l'espace par un point

    Write-Host "Vérification pour l'utilisateur : $nomFormatEmail"  # Affiche pour chaque utilisateur
    Write-Host "Correspondance avec les emails : $($nomFormatEmail.ToLower())"  # Affiche ce qui est comparé

    # Vérifie si l'utilisateur existe dans la liste des emails
    if ($nomFormatEmail.ToLower() -in $ListeMail) {
        # Ajouter l'adresse email à la liste des mails à envoyer
        $email = ($ExtractMail | Where-Object { ($_."Adresses de messagerie" -split "@")[0].ToLower() -eq $nomFormatEmail.ToLower() })."Adresses de messagerie"
        $mailAEnvoye += [PSCustomObject]@{
            AdresseEmail = $email
        }
    }
    else {
        # Ajouter l'utilisateur et ses informations (nom, libelle, numero) à la liste des utilisateurs restants
        $utilisateurRestant += [PSCustomObject]@{
            Utilisateur = $ligne1.UTILISATEUR
            Libelle     = $ligne1.LIBELLE
            Numero      = $ligne1.NUMERO
        }
    }
}

# Exporter les utilisateurs trouvés dans mail-a-envoye.csv
$mailAEnvoye | Export-Csv $CSVSortieMail -NoTypeInformation -Encoding UTF8

# Exporter les utilisateurs non trouvés dans utilisateur-restant.csv avec les colonnes Libelle et Numero
$utilisateurRestant | Export-Csv $CSVSortieRestant -NoTypeInformation -Encoding UTF8

Write-Output " Résultats enregistrés dans mail-a-envoye.csv et utilisateur-restant.csv"
}


menu