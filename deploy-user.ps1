# Définir les chemins des raccourcis sur le bureau
$shortcutPath1 = "$env:USERPROFILE\Desktop\toto.lnk"
$shortcutPath2 = "$env:USERPROFILE\Desktop\tutu.lnk"

# Définir les chemins des nouvelles icônes
$newIconPath1 = "C:\Users\Testeur\Documents\EdgeProfile.ico"
$newIconPath2 = "C:\Users\Testeur\Documents\OneDrive.ico"

# Charger le COMObject pour le premier raccourci
$shortcut1 = New-Object -ComObject WScript.Shell
$link1 = $shortcut1.CreateShortcut($shortcutPath1)

# Modifier l'icône du premier raccourci
$link1.IconLocation = $newIconPath1
$link1.Save()
Write-Output "Icône du raccourci $shortcutPath1 mise à jour avec succès."

# Charger le COMObject pour le second raccourci
$shortcut2 = New-Object -ComObject WScript.Shell
$link2 = $shortcut2.CreateShortcut($shortcutPath2)

# Modifier l'icône du second raccourci
$link2.IconLocation = $newIconPath2
$link2.Save()
Write-Output "Icône du raccourci $shortcutPath2 mise à jour avec succès."



#######################################################################


# Chemin de la photo unique
$imagePath = "C:\logos\default.jpg"

# Chemin local pour la photo de l'utilisateur
$userPhotoPath = "$env:USERPROFILE\AppData\Roaming\Microsoft\Windows\AccountPictures"

# Créer le dossier de destination s'il n'existe pas
if (-not (Test-Path $userPhotoPath)) {
    New-Item -ItemType Directory -Path $userPhotoPath -Force
}

# Copier l'image dans le dossier local
Copy-Item -Path $imagePath -Destination $userPhotoPath -Force

Write-Host "La photo utilisateur a été mise à jour localement avec succès !"
