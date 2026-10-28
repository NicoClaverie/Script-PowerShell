# Vérifie si la session actuelle a les droits d'administrateur
$currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    # Relance le script avec élévation
    $arguments = "& '" + $myinvocation.mycommand.definition + "'"
    Start-Process powershell.exe -Verb RunAs -ArgumentList $arguments
    exit
}

# Autorise l'exécution de scripts pour le processus en cours
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force

# --- 1. Mises à jour des applications (Winget) ---
Write-Host "--- Mise à jour des applications (Winget) ---" -ForegroundColor Cyan
winget source update
# Les flags évitent les invites de confirmation bloquantes en mode silencieux
winget upgrade --all --silent --accept-source-agreements --accept-package-agreements

# --- 2. Mises à jour Windows Update ---
Write-Host "`n--- Mises à jour Windows Update ---" -ForegroundColor Cyan

# Installation et import de PSWindowsUpdate si absent
if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
    Write-Host "Installation du module PSWindowsUpdate..." -ForegroundColor Yellow
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force | Out-Null
    Install-Module -Name PSWindowsUpdate -Force -Confirm:$false
}

Import-Module PSWindowsUpdate

# Recherche, téléchargement et installation des mises à jour
Install-WindowsUpdate -AcceptAll -IgnoreReboot -Verbose

# --- 3. Statut final ---
if (Get-WURebootStatus -Silent) {
    Write-Host "`n[Attention] Un redémarrage est requis pour finaliser les mises a jour." -ForegroundColor Yellow
} else {
    Write-Host "`nToutes les mises a jour sont appliquees. Aucun redémarrage requis." -ForegroundColor Green
}

Write-Host "`nOpération terminée. Appuie sur une touche pour fermer..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")