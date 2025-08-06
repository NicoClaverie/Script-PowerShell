<# Généré par Gemini
.SYNOPSIS
    Supprime de manière interactive un utilisateur local, son profil et sa clé de registre.
.DESCRIPTION
    Ce script demande à l'utilisateur quel compte supprimer, vérifie les droits admin,
    demande une confirmation, puis nettoie toutes les traces du compte.
#>

# =============================================================================
# Étape 1: Vérification des privilèges administrateur
# =============================================================================
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Ce script necessite des privileges d'administrateur pour fonctionner."
    Write-Warning "Tentative de re-lancement automatique en tant qu'administrateur..."
    
    # Ré-exécute le script actuel avec des droits élevés
    Start-Process powershell.exe -ArgumentList "-File `"$PSCommandPath`"" -Verb RunAs
    # Quitte la session actuelle non-admin
    exit
}

# =============================================================================
# Étape 2: Demande interactive à l'utilisateur
# =============================================================================
Clear-Host
Write-Host "Outil de suppression de compte utilisateur local" -ForegroundColor Yellow
Write-Host "------------------------------------------------"

# Demande le nom de l'utilisateur
$UserName = Read-Host -Prompt "Veuillez saisir le nom du compte local à supprimer"

# Vérifie si l'utilisateur a entré quelque chose
if ([string]::IsNullOrWhiteSpace($UserName)) {
    Write-Error "Le nom d'utilisateur ne peut pas etre vide. Operation annulee."
    Read-Host "Appuyez sur Entree pour quitter."
    exit
}

# Demande une confirmation (sécurité)
Write-Host ""
$Confirmation = Read-Host "Etes-vous certain de vouloir supprimer DEFINITIVEMENT le compte '$UserName' et toutes ses donnees (profil, etc.) ? (O/N)"

if ($Confirmation.ToUpper() -ne 'O') {
    Write-Host "Operation annulee par l'utilisateur." -ForegroundColor Yellow
    Read-Host "Appuyez sur Entree pour quitter."
    exit
}

# =============================================================================
# Étape 3: Processus de suppression
# =============================================================================
Write-Host "------------------------------------------------"
Write-Host "Tentative de suppression du compte '$UserName'..." -ForegroundColor Cyan

# Recherche du SID de l'utilisateur avant suppression
try {
    $UserObject = New-Object System.Security.Principal.NTAccount($UserName)
    $UserSID = $UserObject.Translate([System.Security.Principal.SecurityIdentifier]).Value
    Write-Host "[INFO] Utilisateur '$UserName' trouve avec le SID: $UserSID." -ForegroundColor Gray
}
catch {
    Write-Error "Impossible de trouver l'utilisateur '$UserName' sur cette machine. Verifiez le nom et reessayez."
    Read-Host "Appuyez sur Entree pour quitter."
    exit
}

# Suppression du compte
net user $UserName /delete
if ($LASTEXITCODE -ne 0) {
    Write-Warning "[AVERTISSEMENT] Echec de la commande 'net user'. Le compte est peut-être deja supprime ou protege."
} else {
    Write-Host "[SUCCES] Le compte utilisateur '$UserName' a ete supprime." -ForegroundColor Green
}

# Suppression de la clé de registre du profil
$ProfileRegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\$UserSID"
if (Test-Path $ProfileRegPath) {
    Remove-Item -Path $ProfileRegPath -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "[SUCCES] La cle de registre du profil a ete supprimee." -ForegroundColor Green
}

# Suppression du dossier de profil (C:\Users\...)
$ProfilePath = (Get-ItemProperty -Path $ProfileRegPath -Name ProfileImagePath -ErrorAction SilentlyContinue).ProfileImagePath
if ($ProfilePath -and (Test-Path $ProfilePath)) {
    Remove-Item -Path $ProfilePath -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "[SUCCES] Le dossier de profil '$ProfilePath' a ete supprime." -ForegroundColor Green
}

Write-Host "------------------------------------------------"
Write-Host "Nettoyage termine !" -ForegroundColor Yellow
Read-Host "Appuyez sur Entree pour fermer la fenetre."
