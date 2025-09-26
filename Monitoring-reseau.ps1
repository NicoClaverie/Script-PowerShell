<# Genere par Gemini
.SYNOPSIS
Script pour surveiller la connectivite (ping) de plusieurs machines a distance.
Demande les cibles et l'intervalle a l'utilisateur au demarrage.
Enregistre les resultats dans des fichiers logs separes.

.DESCRIPTION
Ce script PowerShell permet de :
1. Demander a l'utilisateur les adresses IP ou noms d'hôte des machines a surveiller.
2. Demander l'intervalle (en secondes) entre chaque serie de pings, avec une valeur par defaut.
3. Pinger chaque cible a l'intervalle defini.
4. Enregistrer le statut (OK/ECHEC) avec un timestamp dans un fichier log dedie a chaque cible.
5. Afficher le statut en temps reel dans la console.

.NOTES
Date de creation : 2025-04-11
Prerequis :
    - PowerShell 5.1 ou superieur.
    - Le pare-feu sur les machines CIBLES doit autoriser les requêtes Ping entrantes (ICMPv4 Echo Request).
    - Les droits d'ecriture dans le dossier de logs specifie ($LogDirectory).
#>

# --- Configuration ---
$LogDirectory = "C:\Temp\PingLogs" # Dossier racine pour les logs separes
$DefaultInterval = 15 # Intervalle par defaut en secondes
# $Targets et $IntervalSeconds sont definis par l'utilisateur ci-dessous
# ---------------------

# --- Demander les cibles a l'utilisateur ---
Write-Host "Configuration de la surveillance :" -ForegroundColor Yellow
$InputString = Read-Host "Entrez les adresses IP ou noms d'hote des PC a surveiller, separes par une virgule (,)"

if ([string]::IsNullOrWhiteSpace($InputString)) {
    Write-Error "Aucune cible n'a ete entree. Le script va s'arreter."
    Exit
}
# Traiter l'entree : separer par virgule, enlever les espaces vides, filtrer les entrees vides
$Targets = $InputString.Split(',') | ForEach-Object { $_.Trim() } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
if ($Targets.Count -eq 0) {
    Write-Error "Aucune cible valide trouvee apres traitement de l'entree. Le script va s'arreter."
    Exit
}
Write-Host "Cibles a surveiller :"
$Targets | ForEach-Object { Write-Host "- $_" }
# --- Fin de la demande des cibles ---

# --- Demander l'intervalle a l'utilisateur ---
$IntervalInput = Read-Host "Entrez l'intervalle entre les pings en secondes (Laissez vide pour utiliser la valeur par defaut : $DefaultInterval secondes)"

if ([string]::IsNullOrWhiteSpace($IntervalInput)) {
    # Si l'utilisateur n'entre rien, utiliser la valeur par defaut
    $IntervalSeconds = $DefaultInterval
    Write-Host "Utilisation de l'intervalle par defaut : $IntervalSeconds secondes."
} else {
    # Essayer de convertir l'entree en nombre entier positif
    try {
        $UserInputInt = [int]$IntervalInput
        if ($UserInputInt -gt 0) {
            # Utiliser la valeur de l'utilisateur si elle est valide
            $IntervalSeconds = $UserInputInt
            Write-Host "Intervalle personnalise utilise : $IntervalSeconds secondes."
        } else {
            # Si le nombre n'est pas positif
            Write-Warning "L'intervalle doit etre un nombre entier positif. Utilisation de la valeur par defaut ($DefaultInterval secondes)."
            $IntervalSeconds = $DefaultInterval
        }
    } catch {
        # Si l'entree n'est pas un nombre entier valide
        Write-Warning "Entree invalide pour l'intervalle. Utilisation de la valeur par defaut ($DefaultInterval secondes)."
        $IntervalSeconds = $DefaultInterval
    }
}
Write-Host "----------------------------------------" -ForegroundColor Yellow
# --- Fin de la demande d'intervalle ---


# --- Demarrage de la surveillance ---
Write-Host "Demarrage de la surveillance le $(Get-Date). Appuyez sur Ctrl+C pour arreter." -ForegroundColor Cyan
Write-Host "Les logs separes sont enregistres dans $LogDirectory" -ForegroundColor Cyan
Write-Host "Intervalle entre les pings : $IntervalSeconds secondes." -ForegroundColor Cyan
Write-Host "----------------------------------------" -ForegroundColor Yellow

# Creer le dossier de logs racine s'il n'existe pas
if (-not (Test-Path -Path $LogDirectory -PathType Container)) {
    try {
        New-Item -Path $LogDirectory -ItemType Directory -Force | Out-Null
        Write-Host "Dossier de logs cree : $LogDirectory"
    } catch {
        Write-Error "Impossible de creer le dossier de logs : $LogDirectory. Verifiez les permissions ou le chemin. Erreur : $($_.Exception.Message)"
        exit # Arrêter si le dossier ne peut pas être cree
    }
}

# Boucle infinie de surveillance (arrêter avec Ctrl+C)
while ($true) {
    foreach ($Target in $Targets) {
        $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

        # Nettoyer le nom de la cible pour l'utiliser dans le nom de fichier (remplace points et deux-points par des underscores)
        $CleanTargetName = $Target -replace '[\.\\:]', '_'
        $LogFilePath = Join-Path -Path $LogDirectory -ChildPath "${CleanTargetName}_PingLog.txt"

        # Creer le fichier log avec en-tête s'il n'existe pas
        if (-not (Test-Path $LogFilePath)) {
            try {
                # On utilise Add-Content directement, il cree le fichier s'il n'existe pas
                Add-Content -Path $LogFilePath -Value "--- Log de surveillance pour $Target demarre le $(Get-Date) ---" -ErrorAction Stop
            } catch {
                Write-Error "Impossible de creer/ecrire l'en-tete dans le fichier log : $LogFilePath. Erreur : $($_.Exception.Message)"
                # On passe a la cible suivante si ce fichier pose probleme
                continue
            }
        }

        # Executer le Test-Connection (Ping)
        if (Test-Connection -ComputerName $Target -Count 1 -Quiet -ErrorAction SilentlyContinue) {
            $Status = "OK"
            $Color = "Green"
        } else {
            $Status = "ECHEC"
            $Color = "Red"
            # On pourrait ajouter ici le message d'erreur specifique si besoin (ex: $Error[0].Exception.Message)
        }

        # Enregistrer dans le fichier log
        try {
            Add-Content -Path $LogFilePath -Value "$Timestamp - $Target - $Status" -ErrorAction Stop
        } catch {
            Write-Warning "Impossible d'ecrire dans $LogFilePath. Erreur: $($_.Exception.Message)"
            # On n'arrête pas la boucle, mais on log l'avertissement
        }

        # Afficher le statut dans la console
        Write-Host "$Timestamp - $Target - $Status" -ForegroundColor $Color

    } # Fin foreach Target

    # Attendre l'intervalle defini avant la prochaine serie de pings
    Start-Sleep -Seconds $IntervalSeconds

} # Fin while ($true)
