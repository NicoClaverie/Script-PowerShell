<# Généré par GEMINI
.SYNOPSIS
    Supprime de manière complète un utilisateur local, son profil, sa clé de registre et les caches associés.
.DESCRIPTION
    Ce script demande à l'utilisateur quel compte supprimer, vérifie les droits admin,
    demande une confirmation, puis nettoie toutes les traces du compte de manière fiable,
    y compris les données en cache du LogonUI et des Stratégies de Groupe.
#>

# =============================================================================
# Étape 1: Vérification des privilèges administrateur
# =============================================================================
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Ce script necessite des privileges d'administrateur pour fonctionner."
    Write-Warning "Tentative de re-lancement automatique en tant qu'administrateur..."
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# =============================================================================
# Étape 2: Demande interactive à l'utilisateur
# =============================================================================
Clear-Host
Write-Host "Outil de suppression COMPLETE de compte utilisateur local" -ForegroundColor Yellow
Write-Host "--------------------------------------------------------"

$UserName = Read-Host -Prompt "Veuillez saisir le nom du compte local a supprimer"
if ([string]::IsNullOrWhiteSpace($UserName)) {
    Write-Error "Le nom d'utilisateur ne peut pas etre vide. Operation annulee."
    Read-Host "Appuyez sur Entree pour quitter."
    exit
}

Write-Host ""
$Confirmation = Read-Host "Etes-vous certain de vouloir supprimer DEFINITIVEMENT le compte '$UserName' et TOUTES ses donnees ? (O/N)"
if ($Confirmation.ToUpper() -ne 'O') {
    Write-Host "Operation annulee par l'utilisateur." -ForegroundColor Yellow
    Read-Host "Appuyez sur Entree pour quitter."
    exit
}

# =============================================================================
# Étape 3: Processus de suppression
# =============================================================================
Write-Host "--------------------------------------------------------"
Write-Host "Debut du processus de suppression pour '$UserName'..." -ForegroundColor Cyan

try {
    # --- Recherche de l'utilisateur et de ses informations AVANT toute suppression ---
    $UserAccount = Get-LocalUser -Name $UserName -ErrorAction Stop
    $UserSID = $UserAccount.SID.Value
    Write-Host "[INFO] Utilisateur '$UserName' trouve avec le SID: $UserSID." -ForegroundColor Gray

    # --- Récupération du chemin du profil via WMI/CIM ---
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
        Write-Host "[SUCCÈS] Le dossier de profil a ete supprime." -ForegroundColor Green
    } else {
        Write-Host "[INFO] Aucun dossier de profil physique trouve pour cet utilisateur." -ForegroundColor Gray
    }
    
    # --- [NOUVEAU] Nettoyage des caches résiduels dans le registre ---
    Write-Host "Nettoyage des traces residuelles dans le registre..."

    # 1. Nettoyage du cache des Stratégies de Groupe (Group Policy)
    $GPStorePath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Group Policy\DataStore\$UserSID"
    if (Test-Path $GPStorePath) {
        Remove-Item -Path $GPStorePath -Recurse -Force
        Write-Host "[SUCCES] Le cache des strategies de groupe a ete supprime." -ForegroundColor Green
    }

    # 2. Nettoyage du cache de l'écran de connexion (LogonUI)
    $SessionDataPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\SessionData"
    Get-ChildItem -Path $SessionDataPath -ErrorAction SilentlyContinue | ForEach-Object {
        # Pour chaque session en cache, on vérifie si le SID correspond à celui de l'utilisateur supprimé
        $SessionSID = (Get-ItemProperty -Path $_.PSPath -Name LoggedOnUserSID -ErrorAction SilentlyContinue).LoggedOnUserSID
        if ($SessionSID -eq $UserSID) {
            Remove-Item -Path $_.PSPath -Recurse -Force
            Write-Host "[SUCCES] L'entree de cache LogonUI pour la session '$($_.PSChildName)' a ete supprimee." -ForegroundColor Green
        }
    }
}
catch {
    Write-Error "Une erreur est survenue : $($_.Exception.Message)"
    Write-Error "L'operation n'a peut-etre pas ete completee. Verification manuelle recommandee."
}
finally {
    Write-Host "--------------------------------------------------------"
    Write-Host "Nettoyage complet termine !" -ForegroundColor Yellow
    Read-Host "Appuyez sur Entree pour fermer la fenetre."
}
