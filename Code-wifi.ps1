# Script récuperation code wifi
# Source : https://www.dsfc.net/infra/reseau/recuperer-cles-securite-wifi-systeme-windows/
# Info supplémentaire : https://www.it-connect.fr/wifi-retrouver-la-cle-de-securite-du-reseau-en-cours/


$wifi=@()
#Visualisation des réseaux bloqués
$cmd0=netsh wlan show blockednetworks
#Liste des SSID
$cmd1=netsh wlan show profiles
ForEach($row1 in $cmd1)
{
    #Récupération des ssids par expression régulière
    If($row1 -match 'Profil Tous les utilisateurs[^:]+:.(.+)$')
    {
        $ssid=$Matches[1]
        $cmd2=netsh wlan show profiles $ssid key=clear
        ForEach($row2 in $cmd2)
        {
            #Récupération des clés par expression régulière
            If($row2 -match 'Contenu de la c[^:]+:.(.+)$')
            {
                $key=$Matches[1]
                #Stockage des ssids et des clés dans un tableau
                $wifi+=[PSCustomObject]@{ssid=$ssid;key=$key}
            }
        }
    }
}
#Export du tableau dans un fichier csv
$wifi|Export-CSV -Path "C:\Users\$env:USERNAME\Desktop\wifi.txt" -NoTypeInformation
$wifi|Export-CSV -Path "C:\Users\$env:USERNAME\Desktop\wifi.csv" -NoTypeInformation
#Visualisation du tableau
$wifi|Sort -Property ssid|Out-GridView -Title 'Clés des SSID du poste'
