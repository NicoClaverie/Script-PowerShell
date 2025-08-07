<#  Généré par GEMINI
.SYNOPSIS
    Supprime de manière interactive un utilisateur local, son profil et sa clé de registre.
.DESCRIPTION
    Ce script demande à l'utilisateur quel compte supprimer, vérifie les droits admin,
    demande une confirmation, puis nettoie toutes les traces du compte de manière fiable.
#>

# =============================================================================
# Étape 1: Vérification des privilèges administrateur
# =============================================================================
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Ce script necessite des privileges d'administrateur pour fonctionner."
    Write-Warning "Tentative de re-lancement automatique en tant qu'administrateur..."
    
    # Ré-exécute le script actuel avec des droits élevés
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
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
    Write-Host "Operation annulée par l'utilisateur." -ForegroundColor Yellow
    Read-Host "Appuyez sur Entree pour quitter."
    exit
}

# =============================================================================
# Étape 3: Processus de suppression
# =============================================================================
Write-Host "------------------------------------------------"
Write-Host "Debut du processus de suppression pour '$UserName'..." -ForegroundColor Cyan

try {
    # --- Recherche de l'utilisateur et de ses informations AVANT toute suppression ---
    $UserAccount = Get-LocalUser -Name $UserName -ErrorAction Stop
    $UserSID = $UserAccount.SID.Value
    Write-Host "[INFO] Utilisateur '$UserName' trouve avec le SID: $UserSID." -ForegroundColor Gray

    # --- Récupération du chemin du profil via WMI/CIM (plus fiable) ---
    $Profile = Get-CimInstance -ClassName Win32_UserProfile | Where-Object { $_.SID -eq $UserSID }
    $ProfilePath = $Profile.LocalPath
    
    # --- Suppression du compte utilisateur ---
    Write-Host "Tentative de suppression du compte..."
    Remove-LocalUser -Name $UserName -ErrorAction Stop
    Write-Host "[SUCCÈS] Le compte utilisateur '$UserName' a ete supprime." -ForegroundColor Green

    # --- Suppression du dossier de profil (C:\Users\...) ---
    if ($ProfilePath -and (Test-Path $ProfilePath)) {
        Write-Host "Tentative de suppression du dossier de profil '$ProfilePath'..."
        Remove-Item -Path $ProfilePath -Recurse -Force -ErrorAction Stop
        Write-Host "[SUCCÈS] Le dossier de profil a été supprime." -ForegroundColor Green
    } else {
        Write-Host "[INFO] Aucun dossier de profil trouve pour cet utilisateur." -ForegroundColor Gray
    }
    
    # La suppression de l'utilisateur via Remove-LocalUser supprime aussi la clé de registre du profil.
    # Une vérification manuelle n'est plus nécessaire mais peut être laissée par sécurité.
    $ProfileRegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\$UserSID"
    if (Test-Path $ProfileRegPath) {
        Write-Warning "[AVERTISSEMENT] La cle de registre du profil existe toujours. Tentative de suppression forcee."
        Remove-Item -Path $ProfileRegPath -Recurse -Force -ErrorAction SilentlyContinue
    } else {
        Write-Host "[INFO] La cle de registre du profil a bien ete nettoyee." -ForegroundColor Gray
    }

}
catch {
    # Gère toutes les erreurs qui ont pu se produire dans le bloc 'try'
    Write-Error "Une erreur est survenue : $($_.Exception.Message)"
    Write-Error "L'operation n'a peut-être pas ete completee. Vérification manuelle recommandee."
}
finally {
    # Ce bloc s'exécute toujours, que le 'try' réussisse ou échoue
    Write-Host "------------------------------------------------"
    Write-Host "Nettoyage termine !" -ForegroundColor Yellow
    Read-Host "Appuyez sur Entree pour fermer la fenetre."
}
