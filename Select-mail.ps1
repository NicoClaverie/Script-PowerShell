# Chemin vers les fichiers CSV

$ExtractLot =  Import-Csv "$env:USERPROFILE\documents\test\lot2.csv"
$ExtractMail = Import-Csv "$env:userprofile\documents\test\glpi.csv"
$CSVSortie = "$env:USERPROFILE\documents\test\Mail-Lot.csv"


# Comparer les fichiers

$resultat = foreach ($ligne1 in $ExtractLot) {
    $NomRechercher = $ligne1.UTILISATEUR 
    $LigneCorrespondante = $ExtractMail | Where-Object { $_.Nom -eq $NomRechercher }
    if ($LigneCorrespondante) {
        $LigneCorrespondante | Select-Object "Adresses de messagerie"
    }


}

# Exporter dans un fichier CSV

