# Vérifie si un mot de passe BIOS est configuré
$bios = Get-WmiObject -Namespace root\wmi -Class Lenovo_BiosPasswordSettings

if ($bios.PasswordState -ne 0) {
    Write-Host "[OK] Mot de passe BIOS configuré." -ForegroundColor Green
} else {
    Write-Host "[ERREUR] Aucun mot de passe BIOS configuré." -ForegroundColor Red
}
