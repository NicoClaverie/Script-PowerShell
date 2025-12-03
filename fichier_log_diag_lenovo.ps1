<#
.SYNOPSIS
  Affiche une boîte de dialogue GUI pour sélectionner un fichier log Lenovo, 
  puis l'analyse et imprime un résumé des tests.
#>

# --- Fonction d'analyse (le coeur du script) ---
function Parse-DiagLog {
    param (
        [string]$FilePath
    )
    
    Write-Host "Analyse du fichier '$FilePath'..." -ForegroundColor Green

    # Initialiser les listes pour stocker les résultats
    $passedTests = [System.Collections.ArrayList]@()
    $failedTests = [System.Collections.ArrayList]@()
    $notApplicableTests = [System.Collections.ArrayList]@()

    $currentDiagnostic = "Inconnu"

    # Regex pour trouver le début d'un bloc de diagnostic
    $diagStartRegex = '^\+\+\+ \S+ (.*?) \d+$'

    # Regex pour trouver une ligne de résultat de test (STOP)
    $stopLineRegex = '^\S+ STOP (\S+) (SUCCESS|FAILED|NOT APPLICABLE)'

    try {
        # Utiliser Get-Content pour lire le fichier ligne par ligne
        Get-Content -Path $FilePath | ForEach-Object {
            $line = $_ # $_ est la ligne actuelle

            # 1. Vérifier si c'est le début d'un nouveau module
            if ($line -match $diagStartRegex) {
                $currentDiagnostic = $matches[1].Trim()
            }
            # 2. Sinon, vérifier si c'est une ligne de résultat (STOP)
            elseif ($line -match $stopLineRegex) {
                $testName = $matches[1]
                $result = $matches[2]
                
                $formattedTest = "[$currentDiagnostic] - $testName"
                
                switch ($result) {
                    "SUCCESS"         { [void]$passedTests.Add($formattedTest) }
                    "FAILED"          { [void]$failedTests.Add($formattedTest) }
                    "NOT APPLICABLE"  { [void]$notApplicableTests.Add($formattedTest) }
                }
            }
        }
    }
    catch {
        Write-Error "Une erreur est survenue lors de la lecture du fichier: $_"
        return
    }

    # --- Impression des résultats ---
    Write-Host "`n--- Résumé du Diagnostic ---" -ForegroundColor Yellow

    # Tests Réussis
    Write-Host "`n✅ Tests Réussis ($($passedTests.Count)):"
    if ($passedTests.Count -gt 0) {
        $passedTests | ForEach-Object { Write-Host "  - $_" }
    } else {
        Write-Host "  - Aucun test réussi."
    }

    # Tests Échoués
    Write-Host "`n❌ Tests Échoués ($($failedTests.Count)):"
    if ($failedTests.Count -gt 0) {
        $failedTests | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    } else {
        Write-Host "  - Aucun échec détecté."
    }

    # Tests Non Applicables
    Write-Host "`n⚠️ Tests Non Applicables ($($notApplicableTests.Count)):"
    if ($notApplicableTests.Count -gt 0) {
        $notApplicableTests | ForEach-Object { Write-Host "  - $_" -ForegroundColor Gray }
    } else {
        Write-Host "  - Aucun test non applicable."
    }
}

# --- Partie GUI (Sélection de fichier) ---
try {
    # Charger l'assembly Windows Forms pour la boîte de dialogue
    Add-Type -AssemblyName System.Windows.Forms
}
catch {
    Write-Warning "Impossible de charger l'assembly System.Windows.Forms. Ce script nécessite un environnement Windows avec GUI."
    Write-Warning "Lancement en mode console. Veuillez spécifier le chemin du fichier :"
    $manualPath = Read-Host "Chemin du fichier log"
    if (Test-Path $manualPath) {
        Parse-DiagLog -FilePath $manualPath
    } else {
        Write-Error "Fichier non trouvé: $manualPath"
    }
    return
}

# Créer un objet OpenFileDialog
$openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
$openFileDialog.Title = "Sélectionner un fichier de log Lenovo"
$openFileDialog.Filter = "Fichiers Log (*.log)|*.log|Tous les fichiers (*.*)|*.*"
$openFileDialog.InitialDirectory = (Get-Location).Path
$openFileDialog.RestoreDirectory = $true

# Afficher la boîte de dialogue
Write-Host "Ouverture de la boîte de dialogue de sélection de fichier..."
$result = $openFileDialog.ShowDialog()

# Vérifier si l'utilisateur a cliqué sur "Ouvrir"
if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
    # Récupérer le chemin du fichier sélectionné
    $selectedFile = $openFileDialog.FileName
    
    # Lancer l'analyse sur ce fichier
    Parse-DiagLog -FilePath $selectedFile
}
else {
    Write-Host "Opération annulée par l'utilisateur."
}