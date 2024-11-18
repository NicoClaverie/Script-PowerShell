##################################################
#                                                #
#      Script pour le changement des icones      #
#                                                #
##################################################


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

