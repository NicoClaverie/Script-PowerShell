<# Généré par Gemini
.SYNOPSIS
Script pour surveiller la connectivité (ping) de plusieurs machines à distance.
Demande les cibles et l'intervalle à l'utilisateur au démarrage.
Enregistre les résultats dans des fichiers logs séparés.

.DESCRIPTION
Ce script PowerShell permet de :
1. Demander à l'utilisateur les adresses IP ou noms d'hôte des machines à surveiller.
2. Demander l'intervalle (en secondes) entre chaque série de pings, avec une valeur par défaut.
3. Pinger chaque cible à l'intervalle défini.
4. Enregistrer le statut (OK/ECHEC) avec un timestamp dans un fichier log dédié à chaque cible.
5. Afficher le statut en temps réel dans la console.

.NOTES
Date de création : 2025-04-11
Prérequis :
    - PowerShell 5.1 ou supérieur.
    - Le pare-feu sur les machines CIBLES doit autoriser les requêtes Ping entrantes (ICMPv4 Echo Request).
    - Les droits d'écriture dans le dossier de logs spécifié ($LogDirectory).
#>

# --- Configuration ---
$LogDirectory = "C:\Temp\PingLogs" # Dossier racine pour les logs séparés
$DefaultInterval = 15 # Intervalle par défaut en secondes
# $Targets et $IntervalSeconds sont définis par l'utilisateur ci-dessous
# ---------------------

# --- Demander les cibles à l'utilisateur ---
Write-Host "Configuration de la surveillance :" -ForegroundColor Yellow
$InputString = Read-Host "Entrez les adresses IP ou noms d'hôte des PC à surveiller, séparés par une virgule (,)"

if ([string]::IsNullOrWhiteSpace($InputString)) {
    Write-Error "Aucune cible n'a été entrée. Le script va s'arrêter."
    Exit
}
# Traiter l'entrée : séparer par virgule, enlever les espaces vides, filtrer les entrées vides
$Targets = $InputString.Split(',') | ForEach-Object { $_.Trim() } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
if ($Targets.Count -eq 0) {
    Write-Error "Aucune cible valide trouvée après traitement de l'entrée. Le script va s'arrêter."
    Exit
}
Write-Host "Cibles à surveiller :"
$Targets | ForEach-Object { Write-Host "- $_" }
# --- Fin de la demande des cibles ---

# --- Demander l'intervalle à l'utilisateur ---
$IntervalInput = Read-Host "Entrez l'intervalle entre les pings en secondes (Laissez vide pour utiliser la valeur par défaut : $DefaultInterval secondes)"

if ([string]::IsNullOrWhiteSpace($IntervalInput)) {
    # Si l'utilisateur n'entre rien, utiliser la valeur par défaut
    $IntervalSeconds = $DefaultInterval
    Write-Host "Utilisation de l'intervalle par défaut : $IntervalSeconds secondes."
} else {
    # Essayer de convertir l'entrée en nombre entier positif
    try {
        $UserInputInt = [int]$IntervalInput
        if ($UserInputInt -gt 0) {
            # Utiliser la valeur de l'utilisateur si elle est valide
            $IntervalSeconds = $UserInputInt
            Write-Host "Intervalle personnalisé utilisé : $IntervalSeconds secondes."
        } else {
            # Si le nombre n'est pas positif
            Write-Warning "L'intervalle doit être un nombre entier positif. Utilisation de la valeur par défaut ($DefaultInterval secondes)."
            $IntervalSeconds = $DefaultInterval
        }
    } catch {
        # Si l'entrée n'est pas un nombre entier valide
        Write-Warning "Entrée invalide pour l'intervalle. Utilisation de la valeur par défaut ($DefaultInterval secondes)."
        $IntervalSeconds = $DefaultInterval
    }
}
Write-Host "----------------------------------------" -ForegroundColor Yellow
# --- Fin de la demande d'intervalle ---


# --- Démarrage de la surveillance ---
Write-Host "Démarrage de la surveillance le $(Get-Date). Appuyez sur Ctrl+C pour arrêter." -ForegroundColor Cyan
Write-Host "Les logs séparés sont enregistrés dans $LogDirectory" -ForegroundColor Cyan
Write-Host "Intervalle entre les pings : $IntervalSeconds secondes." -ForegroundColor Cyan
Write-Host "----------------------------------------" -ForegroundColor Yellow

# Créer le dossier de logs racine s'il n'existe pas
if (-not (Test-Path -Path $LogDirectory -PathType Container)) {
    try {
        New-Item -Path $LogDirectory -ItemType Directory -Force | Out-Null
        Write-Host "Dossier de logs créé : $LogDirectory"
    } catch {
        Write-Error "Impossible de créer le dossier de logs : $LogDirectory. Vérifiez les permissions ou le chemin. Erreur : $($_.Exception.Message)"
        exit # Arrêter si le dossier ne peut pas être créé
    }
}

# Boucle infinie de surveillance (arrêter avec Ctrl+C)
while ($true) {
    foreach ($Target in $Targets) {
        $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

        # Nettoyer le nom de la cible pour l'utiliser dans le nom de fichier (remplace points et deux-points par des underscores)
        $CleanTargetName = $Target -replace '[\.\\:]', '_'
        $LogFilePath = Join-Path -Path $LogDirectory -ChildPath "${CleanTargetName}_PingLog.txt"

        # Créer le fichier log avec en-tête s'il n'existe pas
        if (-not (Test-Path $LogFilePath)) {
            try {
                # On utilise Add-Content directement, il crée le fichier s'il n'existe pas
                Add-Content -Path $LogFilePath -Value "--- Log de surveillance pour $Target démarré le $(Get-Date) ---" -ErrorAction Stop
            } catch {
                Write-Error "Impossible de créer/écrire l'en-tête dans le fichier log : $LogFilePath. Erreur : $($_.Exception.Message)"
                # On passe à la cible suivante si ce fichier pose problème
                continue
            }
        }

        # Exécuter le Test-Connection (Ping)
        if (Test-Connection -ComputerName $Target -Count 1 -Quiet -ErrorAction SilentlyContinue) {
            $Status = "OK"
            $Color = "Green"
        } else {
            $Status = "ECHEC"
            $Color = "Red"
            # On pourrait ajouter ici le message d'erreur spécifique si besoin (ex: $Error[0].Exception.Message)
        }

        # Enregistrer dans le fichier log
        try {
            Add-Content -Path $LogFilePath -Value "$Timestamp - $Target - $Status" -ErrorAction Stop
        } catch {
            Write-Warning "Impossible d'écrire dans $LogFilePath. Erreur: $($_.Exception.Message)"
            # On n'arrête pas la boucle, mais on log l'avertissement
        }

        # Afficher le statut dans la console
        Write-Host "$Timestamp - $Target - $Status" -ForegroundColor $Color

    } # Fin foreach Target

    # Attendre l'intervalle défini avant la prochaine série de pings
    Start-Sleep -Seconds $IntervalSeconds

} # Fin while ($true)
