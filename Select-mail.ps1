# Chemin vers les fichiers CSV

$ExtractLot =  Import-Csv "$env:USERPROFILE\documents\test\lot2.csv"
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



# Comparer les fichiers

$resultat = foreach ($ligne1 in $ExtractLot) {
    $NomRechercher = Extraire-Nom $ligne1.UTILISATEUR 
    $LigneCorrespondante = $ExtractMail | Where-Object { $_.Nom -eq $NomRechercher -replace " ", "." }  # Vérifie si le nom apparaît dans l'e-mail
    if ($LigneCorrespondante) {
        $LigneCorrespondante | Select-Object "Adresses de messagerie"
    }


}

# Exporter dans un fichier CSV

