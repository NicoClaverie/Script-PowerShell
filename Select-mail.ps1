################################################


# Chemins des fichiers CSV
$ExtractLot = Import-Csv "$env:USERPROFILE\documents\test\lot2.csv"
$ExtractMail = Import-Csv "$env:userprofile\documents\test\glpi.csv"
$CSVSortie = "$env:USERPROFILE\documents\test\Mail-Lot.csv"

# Fonction pour extraire le prénom + nom (derniers mots de la colonne Utilisateur)
function Extraire-Nom {
    param ([string]$texte)
    $mots = $texte -split " "
    if ($mots.Count -ge 2) {
        return "$($mots[-2]) $($mots[-1])"  # Derniers mots = Prénom + Nom
    }
    return $texte
}


# Initialiser un tableau pour stocker les résultats
#$resultat = @()

# Comparaison et extraction des e-mails correspondants
foreach ($ligne1 in $ExtractLot) {
    $nomRecherche = Extraire-Nom $ligne1.Utilisateur
    $nomFormatEmail = $nomRecherche -replace " ", "."  # Convertir en format prénom.nom

    $nomFormatEmail | export-csv -Path $CSVSortie -NoTypeInformation -Encoding UTF8 -Append

    # Trouver les correspondances
    # $emails = ($ExtractMail | Where-Object { $_."Adresses de messagerie" -match $nomFormatEmail })."Adresses de messagerie"

    # Si on trouve une correspondance, l'ajouter au tableau des résultats
    #if ($emails) {
    #     $resultat += @{ "Utilisateur" = $ligne1.Utilisateur; "Adresses de messagerie" = ($emails -join ", ") }
    #}
}

# Exporter les résultats sous forme de CSV
#$resultat | Export-Csv -Path $CSVSortie -NoTypeInformation -Encoding UTF8

Write-Host "Les adresses e-mail correspondantes ont été exportées vers : $CSVSortie"
