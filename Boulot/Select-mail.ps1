# Chemins des fichiers CSV
$ExtractLot = Import-Csv "$env:USERPROFILE\documents\test\lot2.csv" -Delimiter "," | Select-Object UTILISATEUR, LIBELLE, NUMERO, Societe, Site
$ExtractMail = Import-Csv "$env:userprofile\documents\test\glpi.csv" -Delimiter ";" | Select-Object "Adresses de messagerie"
$CSVSortieMail = "$env:USERPROFILE\documents\test\mail-a-envoye.csv"
$CSVSortieRestant = "$env:USERPROFILE\documents\test\utilisateur-restant.csv"

# Fonction pour extraire le prénom + nom (derniers mots de la colonne Utilisateur)
function Extraire-Nom {
    param ([string]$texte)
    $mots = $texte -split " "
    if ($mots.Count -ge 2) {
        return "$($mots[-2]) $($mots[-1])"  # Derniers mots = Prénom + Nom
    }
    return $texte
}

# Filtrer les ordinateurs uniquement
$ExtractLotFiltre = $ExtractLot | Where-Object {
    ($_ -notmatch "ECRAN IIYAMA prolite 22") -and ($_ -notmatch "DOCK Hybrid USB-C")# -and ($_ -notmatch "ThinkCentre M75q-2")
}

# Mise en forme pour n'avoir que les prenom.nom des adresses mail
$ListeMail = $ExtractMail | ForEach-Object {
    ($_."Adresses de messagerie" -split "@")[0].ToLower()  # Partie avant @ en minuscules
}

# Listes pour stocker les résultats
$mailAEnvoye = @()
$utilisateurRestant = @()

# Comparaison des utilisateurs avec la liste des e-mails
foreach ($ligne1 in $ExtractLotFiltre) {
    $nomFormatEmail = Extraire-Nom $ligne1.UTILISATEUR

    # Remplacer l'espace par un point pour correspondre au format prénom.nom
    $nomFormatEmail = $nomFormatEmail -replace " ", "."  # Remplacement de l'espace par un point

    Write-Host "Vérification pour l'utilisateur : $nomFormatEmail"  # Affiche pour chaque utilisateur
    Write-Host "Correspondance avec les emails : $($nomFormatEmail.ToLower())"  # Affiche ce qui est comparé

    # Vérifie si l'utilisateur existe dans la liste des emails
    if ($nomFormatEmail.ToLower() -in $ListeMail) {
        # Ajouter l'adresse email à la liste des mails à envoyer
        $email = ($ExtractMail | Where-Object { ($_."Adresses de messagerie" -split "@")[0].ToLower() -eq $nomFormatEmail.ToLower() })."Adresses de messagerie"
        $mailAEnvoye += [PSCustomObject]@{
            AdresseEmail = $email
        }
    }
    else {
        # Ajouter l'utilisateur et ses informations (nom, libelle, numero) à la liste des utilisateurs restants
        $utilisateurRestant += [PSCustomObject]@{
            Societe = $ligne1.Societe
            Site = $ligne1.site
            Utilisateur = $ligne1.UTILISATEUR
            Libelle     = $ligne1.LIBELLE
            Numero      = $ligne1.NUMERO
        }
    }
}

# Exporter les utilisateurs trouvés dans mail-a-envoye.csv
$mailAEnvoye | Export-Csv $CSVSortieMail -NoTypeInformation -Encoding UTF8

# Exporter les utilisateurs non trouvés dans utilisateur-restant.csv avec les colonnes Libelle et Numero
$utilisateurRestant | Export-Csv $CSVSortieRestant -NoTypeInformation -Encoding UTF8

Write-Output "✅ Résultats enregistrés dans mail-a-envoye.csv et utilisateur-restant.csv"
