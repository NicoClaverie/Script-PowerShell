# Chemin du raccourci sur le bureau
$shortcutPath = "$env:USERPROFILE\Desktop\toto.lnk"

# Chemin de la nouvelle icône
$newIconPath = "C:\ico\OneDrive.ico"

# Charger le COMObject pour accéder aux propriétés du raccourci
$shortcut = New-Object -ComObject WScript.Shell
$link = $shortcut.CreateShortcut($shortcutPath)

# Changer l'icône
$link.IconLocation = $newIconPath
$link.Save()

Write-Output "Icône du raccourci mise à jour avec succès."
