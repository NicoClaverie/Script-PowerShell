####################################################################################
#                                                                                  #
#     Script PowerShell pour formater le fichier xlsx du materiel a renouveler     #
#                                   Version 0.0                                    #
#                                                                                  #
####################################################################################

#
# Dans un premier temps, il faut installer le module "ImportExcel"
# "Install-Module -Name ImportExcel"

# pour plus tard utiliser powershell form
# Utiliser "ScriptXlsxToCsv.ps1" pour générer un fichier CSV exploitable

# $Extract = Import-Csv -Path $env:USERPROFILE\Documents\test\lot2.csv -Delimiter "," | Select-Object Societe, site 

# Prérequis : Installer le module ImportExcel si ce n'est pas déjà fait
# Install-Module -Name ImportExcel -Scope CurrentUser

# Prérequis : Installer le module ImportExcel si ce n'est pas déjà fait
# Install-Module -Name ImportExcel -Scope CurrentUser

# Chemin du fichier CSV source
$csvFile = "$env:USERPROFILE\Documents\test\lot2.csv"

# Chemin du fichier Excel de sortie
$xlsxFile = "$env:USERPROFILE\Documents\test\lot2.xlsx"

# Charger les données CSV existantes
$data = Import-Csv -Path $csvFile -Delimiter ","


# Charger les données CSV et sélectionner uniquement les colonnes Societe et Site
$Extract = Import-Csv -Path $csvFile -Delimiter "," | Select-Object Societe, Site

# Obtenir les combinaisons uniques d'Societe et de Site, puis trier par ordre alphabétique
$uniqueCombinations = $Extract | Select-Object Societe, Site -Unique |
Sort-Object { "$($_.Site) - $($_.Societe)" }

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
    
    # Limiter la longueur des noms de feuille
    # $sheetName = $sheetName.Substring(0, [Math]::Min(31, $sheetName.Length))
    
    # Filtrer les lignes correspondant à ce Libelle
    $filteredData = $data | Where-Object {
        $_.Libelle -eq $libelle.Libelle
    } | Select-Object Site, Societe, "Nom Micro", Libelle, Numero, Utilisateur, "Mot de passe", Imprimante, Logiciel, Commentaire
    
    # Exporter les données dans une feuille dédiée
    $filteredData | Export-Excel -Path $xlsxFile -WorksheetName $sheetName -Append
}



# Créer une feuille pour chaque combinaison unique, dans l'ordre alphabétique
foreach ($combination in $uniqueCombinations) {
    # Nom de la feuille : Societe + Site
    $sheetName = "$($combination.Site) - $($combination.Societe)"
    
    # Limiter la longueur des noms de feuille (Excel limite à 31 caractères)
    $sheetName = $sheetName.Substring(0, [Math]::Min(31, $sheetName.Length))
    
    "`"$sheetName`"," | Add-Content -Path $env:USERPROFILE\Documents\test\sheetname.txt 

    # Filtrer les lignes correspondant à cette combinaison et ne garder que les colonnes pertinentes
    $filteredData = Import-Csv -Path $csvFile -Delimiter "," |
    Select-Object Site, Societe, "Nom Micro", Libelle, Numero, Utilisateur, "Mot de passe", Imprimante, Logiciel, Commentaire | Where-Object {
        $_.Societe -eq $combination.Societe -and $_.Site -eq $combination.Site
    }
    
    # Exporter les données dans une feuille dédiée
    $filteredData | Export-Excel -Path $xlsxFile -WorksheetName $sheetName -Append
}



Write-Host "Fichier Excel généré avec succès, feuilles classées par ordre alphabétique : $xlsxFile"
