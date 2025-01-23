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
# Utiliser "ScriptXlsxToCsv.ps1" pour generer un fichier CSV exploitable

$Extract Import-Csv -Path C:\Users\CLAVERIE\Documents\test\lot2.csv -Delimiter "," | Select-Object ,Entreprise, site 