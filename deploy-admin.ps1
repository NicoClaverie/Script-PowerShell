
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
