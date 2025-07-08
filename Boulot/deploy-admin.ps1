
#######################################################################
#                                                                     #
#    SCRIPT POUR DEPLOIMENT POSTE DE TRAVAIL, A APPLIQUER EN ADMIN    #
#                     !!! WORK IN PROGRESS !!!                        #
#                                                                     #
#######################################################################


#-----------------------------
#
#  Formate la barre de recherche
#
#-----------------------------

# Déplacer la barre des tâches à gauche"
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAl" -Value 0 -Force

Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name Hidden -Value 1

# Masquer la recherche dans la barre des tâches
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "SearchboxTaskbarMode" -Value 0

# Désactiver la Vue des tâches
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowTaskViewButton" -Value 0

# Désactiver les Widgets
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarDa" -Value 0


# 1. Choisir la disposition "Autres éléments épinglés"
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_Layout" -Value 1

# 2. Désactiver les applications récemment ajoutées
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_TrackApps" -Value 1 # ou Start_ShowRecentlyAddedApps

# 3. Désactiver les applications les plus utilisées
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_TrackProgs" -Value 0

# 4. Désactiver les fichiers recommandés dans Démarrer
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_Recommendations" -Value 0

# 5. Désactiver les recommandations de contenu
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338389Enabled" -Value 0

# 6. Désactiver les notifications liées au compte
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\UserProfileEngagement" -Name "ScoobeSystemSettingEnabled" -Value 0

# Afficher toutes les icônes dans la barre d'état système
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer" -Name EnableAutoTray -Value 0

Write-Host "Configuration du menu Démarrer mise à jour !" -ForegroundColor Cyan


# Redémarrer l'explorateur Windows pour appliquer les changements
# Stop-Process -Name explorer -Force


#-----------------------------
#
#  Ajout du NAS
#
#-----------------------------

# --- Script pour mapper P: vers \\nasqnap\share en demandant les identifiants ---

$driveLetter = "P"
$networkPath = "\\nasqnap\share"

Write-Host "Vérification de l'existence du lecteur $driveLetter`:"

# Vérifier si le lecteur P: n'existe PAS déjà
if (-not (Test-Path -Path "${driveLetter}:")) {
    Write-Host "Le lecteur $driveLetter`: n'existe pas."
    Write-Host "Une fenêtre va s'ouvrir pour demander les identifiants nécessaires pour accéder à $networkPath" -ForegroundColor Yellow

    # Initialiser la variable credential
    $credential = $null
    try {
        # Demander les identifiants (nom d'utilisateur et mot de passe) à l'utilisateur
        # Le nom d'utilisateur doit souvent être au format DOMAINE\utilisateur ou utilisateur@domaine.com
        $credential = Get-Credential -Message "Entrez les identifiants pour $networkPath"
    }
    catch {
        Write-Warning "Impossible d'obtenir les identifiants. Erreur: $($_.Exception.Message)"
    }


    # Vérifier si l'utilisateur a fourni des identifiants (n'a pas cliqué sur Annuler)
    if ($credential -ne $null) {
        Write-Host "Tentative de mappage du lecteur $driveLetter`: vers $networkPath avec les identifiants fournis..."
        try {
            # Créer le lecteur réseau avec les identifiants et le rendre persistant
            # L'option -Persist tente de rendre le mappage permanent,
            # mais Windows pourrait redemander les identifiants lors de la prochaine connexion.
            New-PSDrive -Name $driveLetter -PSProvider FileSystem -Root $networkPath -Persist -Credential $credential -ErrorAction Stop
            Write-Host "Succès : Lecteur $driveLetter`: mappé vers $networkPath et configuré comme persistant (pour la session actuelle et tentative de persistance)." -ForegroundColor Green
        }
        catch {
            # Afficher un message en cas d'erreur lors du mappage
            Write-Error "Échec du mappage du lecteur $driveLetter`: vers $networkPath. Vérifiez les identifiants fournis, l'accès au chemin réseau et les permissions. Erreur : $($_.Exception.Message)"
        }
    }
    else {
        Write-Warning "Aucun identifiant fourni ou opération annulée par l'utilisateur. Aucun mappage effectué."
    }
}
else {
    # Afficher un message si le lecteur P: existe déjà
    Write-Warning "Le lecteur $driveLetter`: existe déjà. Aucun nouveau mappage effectué."
}

# --- Fin du script ---


# net use P: \\nasqnap\share /user:ADMIN@dom_maine /p:yes

#-----------------------------------------
#
#  Renommer le dossier Default dans C:\Users puis décompresser default.tar.gz a la place
#  Generer avec Gemini
#  
#-----------------------------------------
# Ren C:\Users\Default C:\Users\Default.old

# S'assurer que le script s'arrête en cas d'erreur
$ErrorActionPreference = "Stop"

# --- Début du Script ---
Write-Host "Démarrage du script de remplacement du profil utilisateur par défaut." -ForegroundColor Green

# Définir les chemins des dossiers
$defaultProfilePath = "C:\Users\Default"
$oldProfilePath = "C:\Users\Default.old"

# --- 1. Renommage de l'ancien profil ---
Write-Host "Vérification du profil par défaut existant..."
if (Test-Path $defaultProfilePath) {
    # Si un "Default.old" existe déjà, on le supprime pour éviter une erreur
    if (Test-Path $oldProfilePath) {
        Write-Host "Suppression d'un ancien dossier 'Default.old'..."
        Remove-Item -Path $oldProfilePath -Recurse -Force
    }
    
    # On renomme le dossier Default actuel
    Write-Host "Renommage de '$defaultProfilePath' en '$oldProfilePath'..."
    Rename-Item -Path $defaultProfilePath -NewName "Default.old"
    Write-Host "OK. Ancien profil archivé." -ForegroundColor Green
} else {
    Write-Host "Le dossier '$defaultProfilePath' n'existe pas, rien à renommer."
}

# --- 2. Recherche de l'archive sur les clés USB ---
Write-Host "Recherche de 'default.tar.gz' sur les clés USB..."
$sourceArchive = $null
$removableDrives = Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq 2 }

foreach ($drive in $removableDrives) {
    $potentialPath = Join-Path -Path $drive.DeviceID -ChildPath "default.tar.gz"
    if (Test-Path $potentialPath) {
        $sourceArchive = $potentialPath
        Write-Host "Archive trouvée sur le lecteur $($drive.DeviceID) !" -ForegroundColor Green
        break
    }
}

# Si aucune archive n'est trouvée, on arrête le script avec une erreur
if ($null -eq $sourceArchive) {
    Write-Error "ERREUR : Impossible de trouver le fichier 'default.tar.gz' à la racine d'une clé USB."
    exit 1
}

# --- 3. Décompression de la nouvelle archive ---
$destinationPath = "C:\Users\"
Write-Host "Décompression de '$sourceArchive' vers '$destinationPath'..."

try {
    # On utilise l'outil tar.exe intégré à Windows
    tar.exe -xzf $sourceArchive -C $destinationPath
    Write-Host "Décompression terminée avec succès !" -ForegroundColor Green
} catch {
    Write-Error "ERREUR lors de la décompression de l'archive. Assurez-vous que l'archive n'est pas corrompue."
    Write-Error $_.Exception.Message
    exit 1
}

Write-Host "Script terminé avec succès." -ForegroundColor Magenta


#------------------------------
#
#  Copie des dossiers Logos, Imprimantes et Maintenances sur le disque C:\
#
#------------------------------

# Cherche le dossier 'win11\surC' sur tous les lecteurs prêts et lance Robocopy dès qu'il est trouvé.
Get-CimInstance -ClassName Win32_LogicalDisk | ForEach-Object {
    $sourcePath = Join-Path -Path $_.DeviceID -ChildPath 'win11\surC'
    if (Test-Path -Path $sourcePath) {
        robocopy $sourcePath "C:\" /E /R:1 /W:1 /NP /LOG+:"C:\Windows\Temp\robocopy.log"
        break # Stoppe le script et la recherche une fois la copie lancée
    }
}

#------------------------------------
#
#  Active l'affichage des éléments masqué 
#
#------------------------------------

Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name Hidden -Value 1

# Redémarrer l'explorateur Windows pour appliquer les changements
Stop-Process -Name explorer -Force

#--------------------------------------
#
# Modifie la gestion alimentation de l'USB 
#
#--------------------------------------


$powerMgmt = Get-CimInstance -ClassName MSPower_DeviceEnable -Namespace root/WMI |
where-Object InstanceName -like USB*

foreach ($p in $powerMgmt) {
    $p.Enable = $false
    Set-CimInstance -InputObject $p
}

#---------------------------------
#
# Lancement de l'installation Sentinel One
# En attente 
#
#---------------------------------

# Copier le token dans le presse-papier
# Get-Content -Path "D:\SentinelOne\token.txt" | Set-Clipboard 

# Lancement de l'installation
# Start-Process -FilePath "D:\SentinelOne\SentinelInstaller_windows_64bit_v24_1_5_277.msi" 

#---------------------------------
#
# Activation de la protection système pour le disque C:
#
#---------------------------------

Write-Host "Activation de la protection système sur le disque C:..."

# Reglage limite max de l'utilisation espace disque
vssadmin resize shadowstorage /For=C: /On=C: /MaxSize=5%

# Activer la protection 
Enable-ComputerRestore -Drive "C:\"

# Ouverture de la fenetre protection systeme pour verification
# SystemPropertiesProtection

# Write-Host "Protection système configurée avec succès pour le disque C:."


#---------------------------------
#
# Changement nom, description et domaine du pc
#
#  !!! EN ATTENTE !!!
#---------------------------------


# Demander le nouveau nom de l'ordinateur
#Write-host "Pensez a ajouter X au nom de l'ordinateur" -ForegroundColor Red
$newComputerName = Read-Host "Entrez le nouveau nom de l'ordinateur"

# Demander la nouvelle description de l'ordinateur
#$newDescription = Read-Host "Entrez la description de l'ordinateur"

# Changer le nom de l'ordinateur
Write-Output "Changement du nom de l'ordinateur en '$newComputerName' "
Rename-Computer -NewName $newComputerName -Force

# Changer la description de l'ordinateur dans le registre
#Write-Output "Modification de la description en '$newDescription' "
#Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -Name "srvcomment" -Value $newDescription

# Joindre l'ordinateur au domaine
#Write-Output "Ajout de l'ordinateur au domaine 'TER_SUD' "
#Add-Computer -DomainName TER_SUD -Credential (Get-Credential) -Force -Restart

#Write-Output "Les modifications ont été appliquées. L'ordinateur va redémarrer."



#-----------------------------
#
#   Désactiver les Pare-feu 
#
#-----------------------------

Set-NetFirewallProfile -Profile Domain, Public, Private -Enabled False




#------------------------------------
#
#  Installer .NET Framework net3.5
#
#------------------------------------

Enable-WindowsOptionalFeature -Online -FeatureName NetFx3 -All

#-----------------------------------------
#
#  Désinstalle Game Bar, Teams
#
#-----------------------------------------

Get-AppxPackage *xbox* -allusers | Remove-AppxPackage
Get-AppxPackage *teams* -allusers | Remove-AppxPackage
Get-AppxPackage *outlook* -allusers | Remove-AppxPackage

#-----------------------------------------
#
#  Désactiver l'écran de veille
#
#-----------------------------------------

# 1. Désactive l'activation de l'écran de veille
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name ScreenSaveActive -Value "0" -Type String -Force

# 2. Efface le chemin vers un éventuel écran de veille spécifique (équivaut à sélectionner "Aucun")
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "SCRNSAVE.EXE" -Value "" -Type String -Force

Write-Host "Configuration appliquée : Écran de veille désactivé (Aucun)."


#-----------------------------------------
#
#  !!! PARTIE DE TEST !!!
#
#-----------------------------------------

# Script PowerShell pour désactiver plusieurs paramètres du menu Démarrer via le Registre
# Aucune vérification n'est effectuée avant d'appliquer les modifications.

Write-Host "Tentative de désactivation des paramètres du menu Démarrer via le Registre..." -ForegroundColor Yellow

# Chemin principal pour la plupart des paramètres
$pathExplorerAdvanced = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
$pathContentDelivery = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
$pathUserProfileEngagement = "HKCU:\Software\Microsoft\Windows\CurrentVersion\UserProfileEngagement"

# Désactiver "Afficher les applications récemment ajoutées"
try {
    Set-ItemProperty -Path $pathExplorerAdvanced -Name "Start_ShowRecentlyAddedApps" -Value 0 -Type DWord -Force -ErrorAction Stop
    Write-Host "[OK] Start_ShowRecentlyAddedApps désactivé."
}
catch {
    Write-Warning "[ERREUR] Impossible de modifier Start_ShowRecentlyAddedApps : $($_.Exception.Message)"
}

# Désactiver "Afficher les applications les plus utilisées"
try {
    Set-ItemProperty -Path $pathExplorerAdvanced -Name "Start_TrackProgs" -Value 0 -Type DWord -Force -ErrorAction Stop
    Write-Host "[OK] Start_TrackProgs désactivé."
}
catch {
    Write-Warning "[ERREUR] Impossible de modifier Start_TrackProgs : $($_.Exception.Message)"
}

# Désactiver "Afficher les fichiers recommandés..." (partie affichage Démarrer)
try {
    Set-ItemProperty -Path $pathExplorerAdvanced -Name "Start_RecommendationsEnabled" -Value 0 -Type DWord -Force -ErrorAction Stop
    Write-Host "[OK] Start_RecommendationsEnabled désactivé."
}
catch {
    Write-Warning "[ERREUR] Impossible de modifier Start_RecommendationsEnabled : $($_.Exception.Message)"
}

# Désactiver aussi le suivi général des documents/programmes (impacte récents/recommandés)
try {
    Set-ItemProperty -Path $pathExplorerAdvanced -Name "Start_TrackDocs" -Value 0 -Type DWord -Force -ErrorAction Stop
    Write-Host "[OK] Start_TrackDocs désactivé."
}
catch {
    Write-Warning "[ERREUR] Impossible de modifier Start_TrackDocs : $($_.Exception.Message)"
}

# Désactiver "Afficher des recommandations pour les conseils, etc."
try {
    Set-ItemProperty -Path $pathExplorerAdvanced -Name "Start_SuggestionsEnabled" -Value 0 -Type DWord -Force -ErrorAction Stop
    Write-Host "[OK] Start_SuggestionsEnabled désactivé."
}
catch {
    Write-Warning "[ERREUR] Impossible de modifier Start_SuggestionsEnabled : $($_.Exception.Message)"
}

# Désactiver une clé liée aux suggestions/contenu (ContentDeliveryManager)
# On vérifie si le chemin parent existe pour éviter une erreur si la clé n'est pas présente
if (Test-Path $pathContentDelivery) {
    try {
        Set-ItemProperty -Path $pathContentDelivery -Name "SubscribedContent-310093Enabled" -Value 0 -Type DWord -Force -ErrorAction Stop
        Write-Host "[OK] SubscribedContent-310093Enabled (ContentDelivery) désactivé."
    }
    catch {
        Write-Warning "[ERREUR] Impossible de modifier SubscribedContent-310093Enabled : $($_.Exception.Message)"
    }
}
else {
    Write-Host "[INFO] Chemin $pathContentDelivery inexistant, clé SubscribedContent ignorée."
}

# Tentative de désactivation des notifications/suggestions liées au compte (clé moins certaine)
if (Test-Path $pathUserProfileEngagement) {
    try {
        Set-ItemProperty -Path $pathUserProfileEngagement -Name "ScoobeSystemSettingEnabled" -Value 0 -Type DWord -Force -ErrorAction Stop
        Write-Host "[OK] ScoobeSystemSettingEnabled (UserProfileEngagement) désactivé."
    }
    catch {
        Write-Warning "[ERREUR] Impossible de modifier ScoobeSystemSettingEnabled : $($_.Exception.Message)"
    }
}
else {
    Write-Host "[INFO] Chemin $pathUserProfileEngagement inexistant, clé ScoobeSystemSettingEnabled ignorée."
}


Write-Host "Opération terminée." -ForegroundColor Green
Write-Host "Pour que tous les changements prennent effet, vous devrez peut-être redémarrer l'Explorateur Windows ou votre ordinateur."

# Pour redémarrer l'Explorateur Windows automatiquement (décommenter la ligne ci-dessous) :
# Write-Host "Redémarrage de l'Explorateur Windows..." ; Stop-Process -Name explorer -Force; Start-Process explorer

#--------------------------
#
#  Installation des programmes via Winget
#
#---------------------------

# Script pour installer les applications via winget.
# À placer dans les "FirstLogon scripts", après le script de profil.

# --- 1. Configuration du journal ---
$logFile = "$env:USERPROFILE\Desktop\Winget-Install-Log.txt"
function Write-Log { param($message) ; Add-Content -Path $logFile -Value "($(Get-Date -Format G)) - $message" }
Write-Log "--- Début du script d'installation des applications ---"

# --- 2. Attendre une connexion Internet ---
$connected = $false
1..12 | ForEach-Object {
    if (Test-NetConnection -ComputerName "www.msftconnecttest.com" -WarningAction SilentlyContinue) {
        Write-Log "Connexion Internet détectée."
        $connected = $true
        return
    }
    Start-Sleep -Seconds 15
}

if (-not $connected) {
    Write-Log "ERREUR: Pas de connexion Internet. L'installation des applications est annulée."
    exit
}

# --- 3. Mise à jour des sources Winget ---
Write-Log "Mise à jour des sources winget..."
try {
    winget source update --silent | Out-Null
    Write-Log "Sources winget mises à jour."
} catch {
    Write-Log "AVERTISSEMENT: La mise à jour des sources winget a échoué."
}

# --- 4. Liste des applications à installer ---
$appsToInstall = @(
    @{ Name = "Google Chrome"; Id = "Google.Chrome" },
    @{ Name = "VLC media player"; Id = "VideoLAN.VLC" },
    @{ Name = "LibreOffice"; Id = "TheDocumentFoundation.LibreOffice" },
    @{ Name = "Google Drive"; Id = "Google.Drive" },
    @{ Name = "Adobe Acrobat Reader DC"; Id = "Adobe.Acrobat.Reader.64-bit" },
    @{ Name = "Lenovo Commercial Vantage"; Id = "9NR5B8GVVM13"; Source = "msstore" },
    @{ Name = "Microsoft Sticky Notes"; Id = "9NBLGGH4QGHW"; Source = "msstore" }
)

# --- 5. Boucle d'installation ---
foreach ($app in $appsToInstall) {
    Write-Log "Installation de : $($app.Name) (ID: $($app.Id))"
    $source = if ($app.Source) { $app.Source } else { "winget" }
    try {
        winget install --id $app.Id --source $source --accept-package-agreements --accept-source-agreements -h
        Write-Log "SUCCÈS: $($app.Name) a été installé."
    }
    catch {
        Write-Log "ERREUR lors de l'installation de $($app.Name). Message : $($_.Exception.Message)"
    }
}

Write-Log "--- Fin du script d'installation des applications ---"


#--------------------------------------
#
#   Passe tout les dossiers sur la racine C: en masqué
#
#--------------------------------------

Get-ChildItem -Path C:\ -Directory | ForEach-Object {
    Set-ItemProperty -Path $_.FullName -Name Attributes -Value Hidden
}



#-----------------------------------------
#
#  Désactiver les messages du centre Sécurité et maintenance
#
#-----------------------------------------

$paths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\ActionCenter\Notifications"
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ActionCenter\Checks"
)

$valuesToDisable = @(
    "Uac",
    "WindowsUpdate",
    "SpywareProtection",
    "InternetSecurity",
    "Firewall",
    "AutoUpdate",
    "WindowsBackup",
    "DriveStatus",
    "SmartScreen",
    "AccountProtection",
    "SecurityCenter",
    "Maintenance",
    "Troubleshooting",
    "HomeGroup",
    "StorageSpaces",
    "FileHistory"
)

foreach ($path in $paths) {
    foreach ($name in $valuesToDisable) {
        if (!(Test-Path $path)) {
            New-Item -Path $path -Force | Out-Null
        }
        New-ItemProperty -Path $path -Name $name -Value 0 -PropertyType DWord -Force | Out-Null
    }
}



#-----------------------------------------
#
#  appliquer les options Win11
#
#-----------------------------------------

reg.exe add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /f
taskkill /F /IM explorer.exe
start explorer

#-----------------------------------------
#
#  ajout du wifi GEA
#
#-----------------------------------------

netsh wlan add profile filename="D:\WIN11\Wi-Fi-GEA.xml" user=all
netsh wlan connect name="GEA"
netsh wlan show profiles



#-----------------------------------------
#
#  Active la visionneuse image Windows
#
#-----------------------------------------


$regFileContent = @"
Windows Registry Editor Version 5.00

[HKEY_CLASSES_ROOT\Applications\photoviewer.dll]

[HKEY_CLASSES_ROOT\Applications\photoviewer.dll\shell]

[HKEY_CLASSES_ROOT\Applications\photoviewer.dll\shell\open]
"MuiVerb"="@photoviewer.dll,-3043"

[HKEY_CLASSES_ROOT\Applications\photoviewer.dll\shell\open\command]
@=hex(2):25,00,53,00,79,00,73,00,74,00,65,00,6d,00,52,00,6f,00,6f,00,74,00,25,\
00,5c,00,53,00,79,00,73,00,74,00,65,00,6d,00,33,00,32,00,5c,00,72,00,75,00,\
6e,00,64,00,6c,00,6c,00,33,00,32,00,2e,00,65,00,78,00,65,00,20,00,22,00,25,\
00,50,00,72,00,6f,00,67,00,72,00,61,00,6d,00,46,00,69,00,6c,00,65,00,73,00,\
25,00,5c,00,57,00,69,00,6e,00,64,00,6f,00,77,00,73,00,20,00,50,00,68,00,6f,\
00,74,00,6f,00,20,00,56,00,69,00,65,00,77,00,65,00,72,00,5c,00,50,00,68,00,\
6f,00,74,00,6f,00,56,00,69,00,65,00,77,00,65,00,72,00,2e,00,64,00,6c,00,6c,\
00,22,00,2c,00,20,00,49,00,6d,00,61,00,67,00,65,00,56,00,69,00,65,00,77,00,\
5f,00,46,00,75,00,6c,00,6c,00,73,00,63,00,72,00,65,00,65,00,6e,00,20,00,25,\
00,31,00,00,00

[HKEY_CLASSES_ROOT\Applications\photoviewer.dll\shell\open\DropTarget]
"Clsid"="{FFE2A43C-56B9-4bf5-9A79-CC6D4285608A}"

[HKEY_CLASSES_ROOT\Applications\photoviewer.dll\shell\print]

[HKEY_CLASSES_ROOT\Applications\photoviewer.dll\shell\print\command]
@=hex(2):25,00,53,00,79,00,73,00,74,00,65,00,6d,00,52,00,6f,00,6f,00,74,00,25,\
00,5c,00,53,00,79,00,73,00,74,00,65,00,6d,00,33,00,32,00,5c,00,72,00,75,00,\
6e,00,64,00,6c,00,6c,00,33,00,32,00,2e,00,65,00,78,00,65,00,20,00,22,00,25,\
00,50,00,72,00,6f,00,67,00,72,00,61,00,6d,00,46,00,69,00,6c,00,65,00,73,00,\
25,00,5c,00,57,00,69,00,6e,00,64,00,6f,00,77,00,73,00,20,00,50,00,68,00,6f,\
00,74,00,6f,00,20,00,56,00,69,00,65,00,77,00,65,00,72,00,5c,00,50,00,68,00,\
6f,00,74,00,6f,00,56,00,69,00,65,00,77,00,65,00,72,00,2e,00,64,00,6c,00,6c,\
00,22,00,2c,00,20,00,49,00,6d,00,61,00,67,00,65,00,56,00,69,00,65,00,77,00,\
5f,00,46,00,75,00,6c,00,6c,00,73,00,63,00,72,00,65,00,65,00,6e,00,20,00,25,\
00,31,00,00,00

[HKEY_CLASSES_ROOT\Applications\photoviewer.dll\shell\print\DropTarget]
"Clsid"="{60fd46de-f830-4894-a628-6fa81bc0190d}"
"@
$tempFile = New-TemporaryFile
Set-Content -Path $tempFile.FullName -Value $regFileContent -Encoding Unicode
Start-Process reg.exe -ArgumentList "import ""$($tempFile.FullName)""" -Verb RunAs -Wait
Remove-Item $tempFile.FullName -Force

#-----------------------------------------
#
#  
#
#-----------------------------------------




#-----------------------------------------
#
#  
#
#-----------------------------------------




#-----------------------------------------
#
#  
#
#-----------------------------------------




#-----------------------------------------
#
#  
#
#-----------------------------------------




#-----------------------------------------
#
#  
#
#-----------------------------------------




#-----------------------------------------
#
#  
#
#-----------------------------------------




#-----------------------------------------
#
#  
#
#-----------------------------------------




#-----------------------------------------
#
#  
#
#-----------------------------------------




#-----------------------------------------
#
#  
#
#-----------------------------------------




#-----------------------------------------
#
#  
#
#-----------------------------------------




#-----------------------------------------
#
#  
#
#-----------------------------------------




#-----------------------------------------
#
#  
#
#-----------------------------------------




#-----------------------------------------
#
#  
#
#-----------------------------------------




#-----------------------------------------
#
#  
#
#-----------------------------------------




#-----------------------------------------
#
#  
#
#-----------------------------------------




#-----------------------------------------
#
#  
#
#-----------------------------------------




#-----------------------------------------
#
#  
#
#-----------------------------------------




#-----------------------------------------
#
#  
#
#-----------------------------------------




#-----------------------------------------
#
#  
#
#-----------------------------------------




#-----------------------------------------
#
#  
#
#-----------------------------------------




#-----------------------------------------
#
#  
#
#-----------------------------------------




#-----------------------------------------
#
#  
#
#-----------------------------------------




#-----------------------------------------
#
#  
#
#-----------------------------------------




#-----------------------------------------
#
#  
#
#-----------------------------------------




#-----------------------------------------
#
#  
#
#-----------------------------------------




#-----------------------------------------
#
#  
#
#-----------------------------------------




#-----------------------------------------
#
#  
#
#-----------------------------------------




#-----------------------------------------
#
#  
#
#-----------------------------------------




#-----------------------------------------
#
#  
#
#-----------------------------------------




#-----------------------------------------
#
#  
#
#-----------------------------------------




#-----------------------------------------
#
#  
#
#-----------------------------------------




#-----------------------------------------
#
#  
#
#-----------------------------------------




#-----------------------------------------
#
#  
#
#-----------------------------------------




#-----------------------------------------
#
#  
#
#-----------------------------------------




#-----------------------------------------
#
#  
#
#-----------------------------------------




#-----------------------------------------
#
#  
#
#-----------------------------------------




#-----------------------------------------
#
#  
#
#-----------------------------------------




#-----------------------------------------
#
#  
#
#-----------------------------------------




#-----------------------------------------
#
#  
#
#-----------------------------------------




#-----------------------------------------
#
#  
#
#-----------------------------------------




#-----------------------------------------
#
#  
#
#-----------------------------------------




#-----------------------------------------
#
#  
#
#-----------------------------------------




#-----------------------------------------
#
#  
#
#-----------------------------------------




#-----------------------------------------
#
#  
#
#-----------------------------------------




#-----------------------------------------
#
#  
#
#-----------------------------------------




#-----------------------------------------
#
#  
#
#-----------------------------------------




#-----------------------------------------
#
#  
#
#-----------------------------------------




#-----------------------------------------
#
#  
#
#-----------------------------------------




#-----------------------------------------
#
#  
#
#-----------------------------------------




#-----------------------------------------
#
#  
#
#-----------------------------------------




