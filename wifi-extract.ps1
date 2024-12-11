######################################################
#                                                    #
#       Script pour extract des profiles Wi-Fi       #
#                                                    #
######################################################



$exportPath = "d:\$env:USERNAME\wifi" # Chemin de destination pour les fichiers XML !!! A modifier au besoin !!!
if (!(Test-Path -Path $exportPath)) {
    New-Item -ItemType Directory -Path $exportPath
}

# Exporter tous les profils
$profiles = netsh wlan show profiles | Select-String "Profil Tous les utilisateurs" | ForEach-Object { ($_ -split ":")[1].Trim() }
foreach ($profile in $profiles) {
    netsh wlan export profile name="$profile" folder="$exportPath" key=clear
}

Write-Host "Profils Wi-Fi exportés dans : $exportPath"
