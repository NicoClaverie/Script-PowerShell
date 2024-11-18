
#######################################################################
#                                                                     #
#    SCRIPT POUR DEPLOIMENT POSTE DE TRAVAIL, A APPLIQUER EN ADMIN    #
#                                                                     #
#######################################################################


#---------------------------------
#
# Lancement de l'installation Sentinel One
#
#---------------------------------


# Copier le token dans le presse-papier
Get-Content -Path "D:\SentinelOne\token.txt" | Set-Clipboard # A changer

# Lancement de l'installation
Start-Process -FilePath "D:\SentinelOne\SentinelInstaller_windows_64bit_v24_1_4_257.msi" # A changer


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
SystemPropertiesProtection

Write-Host "Protection système configurée avec succès pour le disque C:."


#---------------------------------
#
# Changement nom, description et domaine du pc
#
#---------------------------------


# Demander le nouveau nom de l'ordinateur
Write-host "Pensez a ajouter X au nom de l'ordinateur" -ForegroundColor Red
$newComputerName = Read-Host "Entrez le nouveau nom de l'ordinateur"

# Demander la nouvelle description de l'ordinateur
$newDescription = Read-Host "Entrez la description de l'ordinateur"

# Changer le nom de l'ordinateur
Write-Output "Changement du nom de l'ordinateur en '$newComputerName' "
Rename-Computer -NewName $newComputerName -Force

# Changer la description de l'ordinateur dans le registre
Write-Output "Modification de la description en '$newDescription' "
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -Name "srvcomment" -Value $newDescription

# Joindre l'ordinateur au domaine
Write-Output "Ajout de l'ordinateur au domaine 'TER_SUD' "
Add-Computer -DomainName TER_SUD -Credential (Get-Credential) -Force -Restart

Write-Output "Les modifications ont été appliquées. L'ordinateur va redémarrer."
