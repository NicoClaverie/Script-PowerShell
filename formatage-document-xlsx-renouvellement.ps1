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

# $Extract = Import-Csv -Path $env:USERPROFILE\Documents\test\lot2.csv -Delimiter "," | Select-Object Entreprise, site 

# Prérequis : Installer le module ImportExcel si ce n'est pas déjà fait
# Install-Module -Name ImportExcel -Scope CurrentUser

# Chemin du fichier CSV source
$csvFile = "$env:USERPROFILE\Documents\test\lot2.csv"

# Chemin du fichier Excel de sortie
$xlsxFile = "$env:USERPROFILE\Documents\test\lot2.xlsx"

# Charger les données CSV et sélectionner uniquement Entreprise et Site
$Extract = Import-Csv -Path $csvFile -Delimiter "," | Select-Object Entreprise, Site

# Charger les données réduite
$ExtractReduit = Import-Csv -Path $csvFile -Delimiter "," | Select-Object site, Entreprise, type, libelle, numero, utilisateur


# Obtenir les combinaisons uniques d'Entreprise et de Site
$uniqueCombinations = $Extract | Select-Object Entreprise, Site -Unique

# Créer une feuille pour chaque combinaison unique
foreach ($combination in $uniqueCombinations) {
    # Nom de la feuille : Entreprise + Site
    $sheetName = "$($combination.Site) - $($combination.Entreprise)"
    
    # Limiter la longueur des noms de feuille (Excel limite à 31 caractères)
    $sheetName = $sheetName.Substring(0, [Math]::Min(31, $sheetName.Length))
    
    # Filtrer les lignes correspondant à cette combinaison
    $filteredData = Import-Csv -Path $csvFile -Delimiter "," | Select-Object site, Entreprise, type, libelle, numero, utilisateur | Where-Object {
        $_.Entreprise -eq $combination.Entreprise -and $_.Site -eq $combination.Site
    }
    
    # Exporter les données dans une feuille dédiée
    $filteredData | Export-Excel -Path $xlsxFile -WorksheetName $sheetName -Append
}

Write-Host "Fichier Excel généré avec succès : $xlsxFile"
