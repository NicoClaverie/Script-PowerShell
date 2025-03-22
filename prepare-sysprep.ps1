####################################################################################
#                                                                                  #
#    Script de suppression des applications problematique pour faire un sysprep    #
#                                 Auteur : ChatGPT                                 #
#                                                                                  #
####################################################################################



# Désinstaller les applications Microsoft Store problématiques pour Sysprep
$apps = @(
    "Microsoft.XboxGamingOverlay", "Microsoft.Xbox.TCUI",
    "Microsoft.XboxApp", "Microsoft.XboxGameOverlay",
    "Microsoft.XboxIdentityProvider", "Microsoft.XboxSpeechToTextOverlay",
    "Microsoft.YourPhone", "Microsoft.ZuneMusic",
    "Microsoft.ZuneVideo", "Microsoft.SkypeApp"
)

foreach ($app in $apps) {
    Get-AppxPackage -AllUsers -Name $app | Remove-AppxPackage -AllUsers
    Get-AppxProvisionedPackage -Online | Where-Object { $_.PackageName -match $app } | Remove-AppxProvisionedPackage -Online -AllUsers
}

# Vérifier et supprimer les profils utilisateurs orphelins
$profiles = Get-WMIObject Win32_UserProfile | Where-Object { $_.Special -eq $false -and $_.Loaded -eq $false }
foreach ($profile in $profiles) {
    Write-Output "Suppression du profil : $($profile.LocalPath)"
    Remove-Item -Path $profile.LocalPath -Recurse -Force -ErrorAction SilentlyContinue
    $profile.Delete()
}

# Désactiver les services susceptibles de bloquer Sysprep
$services = @(
    "wlidsvc",   # Service d'identité Microsoft (lié à Microsoft Store)
    "lfsvc"      # Service de géolocalisation
)

foreach ($service in $services) {
    Write-Output "Arrêt et désactivation du service : $service"
    Stop-Service -Name $service -Force -ErrorAction SilentlyContinue
    Set-Service -Name $service -StartupType Disabled
}

# Nettoyage du dossier temporaire de Windows
Write-Output "Nettoyage des fichiers temporaires..."
Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue

Write-Output "Nettoyage terminé ! Redémarre le PC et lance Sysprep."
