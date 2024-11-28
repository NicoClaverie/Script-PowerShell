#### NE FONCTIONNE PAS ####

# Demander à l'utilisateur de saisir le nom de l'imprimante (sans le préfixe \\tdsclai27\)
$imprimanteNom = Read-Host "Entrez le nom de l'imprimante (ex : pr600)"

# Vérifier si un nom a été entré
if ([string]::IsNullOrEmpty($imprimanteNom)) {
    Write-Host "Le nom de l'imprimante ne peut pas être vide. Veuillez relancer le script."
    exit
}

# Définir les chemins UNC des imprimantes
$cheminColor = "\\tdsclai27\$imprimanteNom couleur"
$cheminNB = "\\tdsclai27\$imprimanteNom nb"

# Afficher les chemins pour confirmation
Write-Host "Ajout des imprimantes :"
Write-Host "Couleur : $cheminColor"
Write-Host "Noir et blanc : $cheminNB"

# Ajouter l'imprimante couleur
try {
    Add-Printer -Name "$imprimanteNom couleur" -ConnectionName $cheminColor
    Write-Host "Imprimante $imprimanteNom couleur ajoutée."
} catch {
    Write-Host "Erreur lors de l'ajout de l'imprimante $imprimanteNom couleur : $_"
}

# Ajouter l'imprimante noir et blanc
try {
    Add-Printer -Name "$imprimanteNom nb" -ConnectionName $cheminNB
    Write-Host "Imprimante $imprimanteNom nb ajoutée."
} catch {
    Write-Host "Erreur lors de l'ajout de l'imprimante $imprimanteNom nb : $_"
}

# Configurer l'imprimante noir et blanc (si nécessaire)
try {
    Set-PrintConfiguration -PrinterName "$imprimanteNom nb" -Color $false
    Write-Host "Imprimante $imprimanteNom nb configurée en noir et blanc."
} catch {
    Write-Host "Erreur lors de la configuration de l'imprimante $imprimanteNom nb : $_"
}

Write-Host "Les imprimantes ont été installées et configurées avec succès."
