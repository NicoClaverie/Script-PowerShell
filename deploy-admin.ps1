# Activer la protection système pour le disque C:
Write-Output "Activation de la protection système sur le disque C:..."
vssadmin resize shadowstorage /For=C: /On=C: /MaxSize=5%

# Vérifier si la protection est déjà activée
$protectionStatus = Get-ComputerRestorePoint -Drive C: -ErrorAction SilentlyContinue

if (-not $protectionStatus) {
    Write-Output "Activation de la protection système..."
    Enable-ComputerRestorePoint -Drive C:
} else {
    Write-Output "La protection système est déjà activée pour le disque C:."
}

# Définir l'utilisation maximale de l'espace disque pour les points de restauration
Write-Output "Définition de l'utilisation maximale à 5%..."
vssadmin resize shadowstorage /For=C: /On=C: /MaxSize=5%

Write-Output "Protection système configurée avec succès pour le disque C:."






# Demander le nouveau nom de l'ordinateur
$newComputerName = Read-Host "Entrez le nouveau nom de l'ordinateur"

# Demander la nouvelle description de l'ordinateur
$newDescription = Read-Host "Entrez la description de l'ordinateur"

# Définir le domaine
$domainName = "TER_SUD"

# Changer le nom de l'ordinateur
Write-Output "Changement du nom de l'ordinateur en '$newComputerName'..."
Rename-Computer -NewName $newComputerName -Force

# Changer la description de l'ordinateur dans le registre
Write-Output "Modification de la description en '$newDescription'..."
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -Name "srvcomment" -Value $newDescription

# Joindre l'ordinateur au domaine (si ce n'est pas déjà fait)
Write-Output "Ajout de l'ordinateur au domaine '$domainName'..."
Add-Computer -DomainName $domainName -Credential (Get-Credential) -Force -Restart

Write-Output "Les modifications ont été appliquées. L'ordinateur va redémarrer."
