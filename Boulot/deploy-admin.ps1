
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

#------------------------------
#
#  Copie des dossiers Logos, Imprimantes et Maintenances sur le disque C:\
#
#------------------------------

Robocopy "\\nasqnap\share\Informatique\MASTER\WIN11\Sur C" C:\

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
#$newComputerName = Read-Host "Entrez le nouveau nom de l'ordinateur"

# Demander la nouvelle description de l'ordinateur
#$newDescription = Read-Host "Entrez la description de l'ordinateur"

# Changer le nom de l'ordinateur
#Write-Output "Changement du nom de l'ordinateur en '$newComputerName' "
#Rename-Computer -NewName $newComputerName -Force

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

# Vérifie si winget est disponible
if (-not (Get-Command "winget.exe" -ErrorAction SilentlyContinue)) {
    Write-Host "Winget n'est pas installé. Installation en cours..." -ForegroundColor Yellow

    $progressPreference = 'silentlyContinue'
    Write-Host "Installation du module WinGet PowerShell depuis PSGallery..."
    Install-PackageProvider -Name NuGet -Force | Out-Null
    Install-Module -Name Microsoft.WinGet.Client -Force -Repository PSGallery | Out-Null

    Write-Host "Utilisation de Repair-WinGetPackageManager pour bootstrapper WinGet..."
    Repair-WinGetPackageManager

    Write-Host "Winget a été installé avec succès." -ForegroundColor Green
}
else {
    Write-Host "Winget est déjà installé." -ForegroundColor Green
}

# Mise a jour des sources Winget
winget source update

# Installation des logiciels 
winget install --accept-package-agreements --accept-source-agreements google.chrome VideoLAN.VLC TheDocumentFoundation.LibreOffice Google.GoogleDrive Adobe.Acrobat.Reader.64-bit


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




