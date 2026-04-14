######################################################################
#
#       Script pour analyser les log de monitoring-reseau.ps1
#
#                    Auteur : Nicolas Claverie
#                    Aide : Gemini
#
######################################################################


Add-Type -AssemblyName System.Windows.Forms

# 1. Selection du fichier via fenêtre
$FileBrowser = New-Object System.Windows.Forms.OpenFileDialog
$cheminBase = "C:\Temp\PingLogs"
$FileBrowser.InitialDirectory = if (Test-Path $cheminBase) { $cheminBase } else { [Environment]::GetFolderPath('Desktop') }
$FileBrowser.Filter = "Fichiers Log (*.txt)|*.txt"
$FileBrowser.Title = "Selectionnez le log a analyser"

if ($FileBrowser.ShowDialog() -eq 'OK') {
    $logFile = $FileBrowser.FileName
} else {
    Write-Host "Action annulee." -ForegroundColor Yellow
    exit
}

# 2. Analyse des donnees
$logs = Get-Content $logFile
$total = $logs.Count
$reussites = 0
$echecs = 0
$horodatagesEchecs = @()

foreach ($line in $logs) {
    if ($line -like "* - OK") { 
        $reussites++ 
    }
    elseif ($line -like "* - ECHEC") {
        $echecs++
        if ($line.Length -ge 19) { $horodatagesEchecs += $line.Substring(0, 19) }
    }
}

# 3. Calculs des pourcentages
$pctOK = if ($total -gt 0) { ($reussites / $total) * 100 } else { 0 }
$pctEchec = if ($total -gt 0) { ($echecs / $total) * 100 } else { 0 }

# 4. Affichage console avec tes lignes preferees
Write-Host "`n--- RAPPORT D'ANALYSE ---" -ForegroundColor Cyan
Write-Host "Fichier : $((Get-Item $logFile).Name)"
Write-Host "Total de lignes : $total"
Write-Host ""
Write-Host "Succes (OK)    : $reussites ($([Math]::Round($pctOK, 2))%)" -ForegroundColor Green
Write-Host "echecs (ECHEC) : $echecs ($([Math]::Round($pctEchec, 2))%)" -ForegroundColor Red
Write-Host ""

if ($echecs -gt 0) {
    Write-Host "Horodatages des echecs :" -ForegroundColor Yellow
    $horodatagesEchecs | ForEach-Object { Write-Host " - $_" }
}

# 5. Option d'enregistrement
Write-Host ""
$reponse = Read-Host "Voulez-vous enregistrer ce resume dans C:\Temp\PingLogs ? (o/n)"

if ($reponse -eq 'o') {
    $nomFichierSeul = [System.IO.Path]::GetFileNameWithoutExtension($logFile)
    $cheminSortie = Join-Path $cheminBase "$($nomFichierSeul)_resume.txt"
    
    # Preparation du contenu du fichier
    $rapportTexte = @"
RAPPORT D'ANALYSE DU LOG
------------------------
Fichier : $((Get-Item $logFile).Name)
Date : $(Get-Date -Format "dd/MM/yyyy HH:mm:ss")

Total lignes : $total
Succes : $reussites ($([Math]::Round($pctOK, 2))%)
echecs : $echecs ($([Math]::Round($pctEchec, 2))%)

Horodatages des echecs :
$($horodatagesEchecs -join "`r`n")
"@

    if (-not (Test-Path $cheminBase)) { New-Item -ItemType Directory -Path $cheminBase | Out-Null }
    $rapportTexte | Out-File -FilePath $cheminSortie -Encoding utf8
    Write-Host "Fichier enregistre avec succes : $cheminSortie" -ForegroundColor Green
} else {
    Write-Host "Fin du script." -ForegroundColor Gray
}