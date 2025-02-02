Add-Type -AssemblyName "System.Windows.Forms"

# Créer une boîte de dialogue pour sélectionner le fichier
$dialog = New-Object System.Windows.Forms.OpenFileDialog
$dialog.Filter = "Fichiers Excel (*.xlsx)|*.xlsx|Tous les fichiers (*.*)|*.*"  # Filtre pour les fichiers .xlsx
$dialog.Title = "Sélectionnez un fichier Excel"

# Afficher la boîte de dialogue et obtenir le chemin du fichier
if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
    $cheminFichier = $dialog.FileName
    Write-Host "Fichier sélectionné : $cheminFichier"
}
else {
    Write-Host "Aucun fichier sélectionné."
}
