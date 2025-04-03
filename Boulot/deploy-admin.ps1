
#######################################################################
#                                                                     #
#    SCRIPT POUR DEPLOIMENT POSTE DE TRAVAIL, A APPLIQUER EN ADMIN    #
#                          !!! WORK IN PROGRESS !!!                   #
#                                                                     #
#######################################################################


#-----------------------------
#
#  Formate la barre de recherche
#
#-----------------------------


# Déplacer la barre des tâches à gauche
$path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3"
$values = Get-ItemProperty -Path $path
$values.Settings[12] = 0  # 0 = Gauche, 1 = Haut, 2 = Droite, 3 = Bas
Set-ItemProperty -Path $path -Name Settings -Value $values.Settings
Stop-Process -Name explorer -Force  # Redémarrer l'explorateur

# Masquer la recherche dans la barre des tâches
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "SearchboxTaskbarMode" -Value 0

# Désactiver la Vue des tâches
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowTaskViewButton" -Value 0

# Désactiver les Widgets
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarDa" -Value 0

# Redémarrer l'explorateur Windows pour appliquer les changements
Stop-Process -Name explorer -Force

#--------------------------------------
#
# Modifie la gestion alimentation de l'USB 
#
#--------------------------------------


$powerMgmt = Get-CimInstance -ClassName MSPower_DeviceEnable -Namespace root/WMI |
    where-Object InstanceName -like USB*

foreach ($p in $powerMgmt) {
    $p.Enable = $false
    Set-CimInstance -InputObject $p
}


#---------------------------------
#
# Lancement de l'installation Sentinel One
# En attente 
#
#---------------------------------


# Copier le token dans le presse-papier
# Get-Content -Path "D:\SentinelOne\token.txt" | Set-Clipboard 

# Lancement de l'installation
# Start-Process -FilePath "D:\SentinelOne\SentinelInstaller_windows_64bit_v24_1_5_277.msi" 


#---------------------------------
#
# Activation de la protection système pour le disque C:
#
#---------------------------------


Write-Host "Activation de la protection système sur le disque C:..."

# Reglage limite max de l'utilisation espace disque
vssadmin resize shadowstorage /For=C: /On=C: /MaxSize=5%

# Activer la protection 
Enable-ComputerRestore -Drive "C:\"

# Ouverture de la fenetre protection systeme pour verification
# SystemPropertiesProtection

Write-Host "Protection système configurée avec succès pour le disque C:."


#---------------------------------
#
# Changement nom, description et domaine du pc
#
#  !!! EN ATTENTE !!!
#---------------------------------


# Demander le nouveau nom de l'ordinateur
#Write-host "Pensez a ajouter X au nom de l'ordinateur" -ForegroundColor Red
#$newComputerName = Read-Host "Entrez le nouveau nom de l'ordinateur"

# Demander la nouvelle description de l'ordinateur
#$newDescription = Read-Host "Entrez la description de l'ordinateur"

# Changer le nom de l'ordinateur
#Write-Output "Changement du nom de l'ordinateur en '$newComputerName' "
#Rename-Computer -NewName $newComputerName -Force

# Changer la description de l'ordinateur dans le registre
#Write-Output "Modification de la description en '$newDescription' "
#Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -Name "srvcomment" -Value $newDescription

# Joindre l'ordinateur au domaine
#Write-Output "Ajout de l'ordinateur au domaine 'TER_SUD' "
#Add-Computer -DomainName TER_SUD -Credential (Get-Credential) -Force -Restart

#Write-Output "Les modifications ont été appliquées. L'ordinateur va redémarrer."


#--------------------------
#
#  Installation des programmes via Winget
#
#---------------------------

winget install  google.chrome VideoLAN.VLC TheDocumentFoundation.LibreOffice 9NBLGGH4QGHW 9NR5B8GVVM13

#-----------------------------
#
#   Désactiver les Pare-feu 
#
#-----------------------------

Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False

#-----------------------------
#
#  Ajout du NAS
#
#-----------------------------

net use P: \\nasqnap\share /user:ADMIN@dom_maine /p:yes

#------------------------------
#
#  Copie des dossiers Logos, Imprimantes et Maintenances sur le disque C:\
#
#------------------------------

Robocopy "\\nasqnap\share\Informatique\MASTER\WIN11\Sur C" C:\boot
