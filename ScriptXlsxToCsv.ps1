################################################################################################
#                                                                                              #
#  Script pour modifier un fichier XLSX en CSV sans accent, ni caractere speciaux, ni espace   #
#                                                                                              #
################################################################################################

# Chemin d'accès du fichier XLSX d'entrée et du fichier CSV de sortie
$fichierXLSX = "$env:USERPROFILE\Documents\test\lot1.xlsx"
$fichierCSV = "$env:USERPROFILE\Documents\test\lot2.csv"

# Charger le contenu du fichier XLSX
$data = Import-Excel -Path $fichierXLSX


# Exporter les données dans un fichier CSV avec encodage UTF-8 avec BOM
$data | Export-Csv -Path $fichierCSV -Encoding UTF8 -NoTypeInformation


# Définition de la fonction Remove-StringSpecialCharacters
function Remove-StringSpecialCharacters {
   param ([string]$String)

   Begin {}

   Process {

      $String = [Text.Encoding]::ASCII.GetString([Text.Encoding]::GetEncoding("Cyrillic").GetBytes($String))

      $String = $String  `
         -replace '/', '' `
         -replace '\*', '' `
         -replace "'", "" `
         -replace "°", " " `
         -replace "\)", "" `
         -replace "\(", ""    
      #-replace '-', ''
      #-replace ' ', '' `
   }

   End {
      return $String
   }
}


# Lire le contenu du fichier d'entrée
$contenu = Get-Content $fichierCSV

# Appliquer la fonction Remove-StringSpecialCharacters à chaque ligne
$contenuTraite = foreach ($ligne in $contenu) {
   Remove-StringSpecialCharacters -String $ligne

}

# Écrire les lignes traitées dans un nouveau fichier
$contenuTraite | Out-File -FilePath $fichierCSV -Encoding utf8


##################################################################
#                                                                #
#    Ajoute les colonnes Mot de passe, Imprimante et Logiciel    #
#                                                                #
##################################################################



# Rappel le fichier CSV pour modification
$FileSource = Import-Csv $fichierCSV

# Ajouter les colonnes mot de passe, imprimante, logiciel

foreach ($ligne in $FileSource) {
   $ligne | Add-Member -MemberType NoteProperty -Name "Mot de passe" -Value ""#=RECHERCHEX($F2;'Données utilisateurs'!$A:$A;'Données utilisateurs'!B:B)" # a adapter
   $ligne | Add-Member -MemberType NoteProperty -Name "Imprimante" -Value ""#=RECHERCHEX($F2;'Données utilisateurs'!$A:$A;'Données utilisateurs'!C:C)" # a adapter
   $ligne | Add-Member -MemberType NoteProperty -Name "Logiciel" -Value ""#=RECHERCHEX($F2;'Données utilisateurs'!$A:$A;'Données utilisateurs'!D:D)" # a adapter
   # ajouter colonne suivi 
   # ajouter colonne commentaire
}



# Écrire les lignes traitées dans un nouveau fichier
$FileSource | Export-Csv -Path $fichierCSV -Delimiter "," -NoTypeInformation