#######################################################################
#                                                                     #
#    Script pour verifier si le deploiement WDS s'est bien deroule    #
#                                                                     #
#                      Auteur : Nicolas CLAVERIE                      #
#                                                                     #
#######################################################################


# Vérifie si la session actuelle a les droits d'administrateur
$currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    # Si non, on relance le script actuel en demandant l'élévation
    $arguments = "& '" + $myinvocation.mycommand.definition + "'"
    Start-Process powershell.exe -Verb RunAs -ArgumentList $arguments
    # On quitte la session non-administrateur
    exit
}


# Definir le chemin du fichier de log
$LogFile = "C:\Temp\Validation_WDS_Simple.log"


####################################################################################
# 1. Demander les identifiants de domaine AD
# Un utilisateur AD valide qui a le droit de lire l'annuaire.
$ADCredentials = Get-Credential -Message "Veuillez entrer vos identifiants de domaine Active Directory"

# 2. Spécifier le chemin LDAP (la racine de votre domaine)
$DomainPath = "LDAP://TER_SUD.local" 

# 3. Créer un objet DirectoryEntry authentifié
# C'est cet objet qui établit la connexion au serveur AD avec les identifiants fournis.
$DomainEntry = New-Object System.DirectoryServices.DirectoryEntry `
    -ArgumentList $DomainPath, $ADCredentials.UserName, $ADCredentials.GetNetworkCredential().Password

# 4. Créer le DirectorySearcher et lui assigner la connexion authentifiée
$ADSI = New-Object System.DirectoryServices.DirectorySearcher
$ADSI.SearchRoot = $DomainEntry # Le SearchRoot utilise maintenant la connexion de domaine.

# 5. Définir le filtre et exécuter la recherche
$ADSI.Filter = "(&(objectCategory=computer)(cn=$env:COMPUTERNAME))"

# Effectuer la recherche et afficher/enregistrer le résultat
$SearchResult = $ADSI.FindOne()

if ($SearchResult) {
    Write-Host "Chemin AD trouve et enregistre : $($SearchResult.Path)"
} else {
    Write-Error "Impossible de trouver l'objet ordinateur dans l'Active Directory."
}


####################################################################################

# 1. ecrire l'heure et la date d'executionn
$DateExecution = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
"=======================================================" | Out-File $LogFile
"Deploiement WDS verifie le $DateExecution" | Out-File $LogFile -Append

# 2. ecrire le Hostname (Nom de l'ordinateur)
$Hostname = $env:COMPUTERNAME
"Hostname : $Hostname" | Out-File $LogFile -Append
$SearchResult.Path | Out-File $LogFile -Append
"Ordinateur verifie par $($ADCredentials.UserName)" | Out-File $LogFile -Append
#$ADSI = New-Object System.DirectoryServices.DirectorySearcher
#$ADSI.Filter = "(&(objectCategory=computer)(cn=$env:COMPUTERNAME))"
#$ADSI.FindOne().Path | Out-File $LogFile -Append
#$ADSI.FindOne().Path
"=======================================================" | Out-File $LogFile -Append

# 3. Verifie la presence du XML pour les applications par defaut

if (Test-Path -Path "C:\DefaultApps\AppDefault.xml") {
    "Fichier AppDefault.xml : OK" | Out-File $LogFile -Append 
    Write-Host "Fichier AppDefault.xml : OK" -ForegroundColor Green
} else {
    "Fichier AppDefault.xml : ABSENT. ERREUR DE DEPLOIEMENT." | Out-File $LogFile -Append
    Write-Host "Fichier AppDefault.xml : ERREUR" -ForegroundColor Red
}

# 4. Verifie la presence du certificat pour l'agent GLPI

if (Test-Path -Path "C:\Windows\Certificat\_.groupe-terresdusud.fr.crt") {
    "Certificat GLPI : OK" | Out-File $LogFile -Append
    Write-Host "Certificat GLPI : OK" -ForegroundColor Green
} else {
    "Certificat GLPI : ABSENT. ERREUR DE DEPLOIEMENT." | Out-File $LogFile -Append
    Write-Host "Certificat GLPI : ERREUR" -ForegroundColor Red
}

#############################################################################
#
#                                Partie Imprimante
#
#############################################################################


# Changement de section
"---" | Out-File $LogFile -Append

# 5. Verifie la presence du des drivers Canon

if (Test-Path -Path "C:\Imprimantes\CANON\GPlus_PCL6_Driver_V230_W64_00\Driver\CNP60MA64.INF") {
    "Pilote CANON : OK" | Out-File $LogFile -Append
    Write-Host "Drivers CANON : OK" -ForegroundColor Green
} else {
    "Drivers CANON : ABSENT. ERREUR DE DEPLOIEMENT." | Out-File $LogFile -Append
    Write-Host "Drivers CANON : ERREUR" -ForegroundColor Red
}

# 6. Verifie la presence du des drivers HP

if (Test-Path -Path "C:\Imprimantes\HP\pcl6-x64-6.9.0.24630") {
    "Pilote HP : OK" | Out-File $LogFile -Append
    Write-Host "Drivers HP : OK" -ForegroundColor Green
} else {
    "Drivers HP : ABSENT. ERREUR DE DEPLOIEMENT." | Out-File $LogFile -Append
    Write-Host "Drivers HP : ERREUR" -ForegroundColor Red
}

# 7. Verifie la presence du des drivers LEXMARK

if (Test-Path -Path "C:\Imprimantes\LEXMARK\Lexmark_Universal_v2_XL_3_0_2\Drivers\Print\GDI") {
    "Pilote LEXMARK : OK" | Out-File $LogFile -Append
    Write-Host "Drivers LEXMARK : OK" -ForegroundColor Green
} else {
    "Drivers LEXMARK : ABSENT. ERREUR DE DEPLOIEMENT." | Out-File $LogFile -Append
    Write-Host "Drivers LEXMARK : ERREUR" -ForegroundColor Red
}

# 8. Verifie la presence du des drivers XEROX

if (Test-Path -Path "C:\Imprimantes\XEROX\UNIV_5.1035.2.0_PCL6_x64_Driver.inf") {
    "Pilote XEROX : OK" | Out-File $LogFile -Append
    Write-Host "Drivers XEROX : OK" -ForegroundColor Green
} else {
    "Drivers XEROX : ABSENT. ERREUR DE DEPLOIEMENT." | Out-File $LogFile -Append
    Write-Host "Drivers XEROX : ERREUR" -ForegroundColor Red
}


#############################################################################
#
#                                Partie Logiciels
#
#############################################################################


# Changement de section
"---" | Out-File $LogFile -Append

################################################ Libre Office ################################################

# 9. Verifie la presence et la version de Libre Office

$LibreOfficeExe = Join-Path -Path "C:\Program Files\LibreOffice\program" -ChildPath "soffice.exe"

if (Test-Path -Path "C:\Program Files\LibreOffice\program") {
    
    # Le fichier existe, c'est OK
    "Statut LibreOffice : OK " | Out-File $LogFile -Append
    Write-Host "Verification LibreOffice : OK" -ForegroundColor Green
    
    # Tenter d'obtenir la version
    try {
        # Utiliser Get-Item pour lire les metadonnees du fichier
        $VersionInfo = Get-Item $LibreOfficeExe
        $Version = $VersionInfo.VersionInfo.FileVersion
        
        if ($Version) {
            "Version LibreOffice : $Version" | Out-File $LogFile -Append
            Write-Host "Version LibreOffice detectee : $Version"
        } else {
            "Version LibreOffice : Non detectee." | Out-File $LogFile -Append
            Write-Host "Version LibreOffice : ATTENTION, executable present mais version non detectee." -ForegroundColor Yellow
        }
    }
    catch {
        "Erreur lors de la lecture de la version." | Out-File $LogFile -Append
        Write-Host "Erreur lors de la lecture de la version du fichier." -ForegroundColor Yellow
    }
    
} else {
    
    # Le fichier est absent, c'est une ERREUR
    "Statut LibreOffice : ABSENT. ERREUR DE DEPLOIEMENT." | Out-File $LogFile -Append
    Write-Host "Verification LibreOffice : ERREUR, l'executable n'a pas ete trouve." -ForegroundColor Red
}

"---" | Out-File $LogFile -Append

################################################ GLPI ################################################

# 10. Verifie la presence et la version de GLPI Agent

# Definir les chemins
$GLPIAgentPath = "C:\Program Files\GLPI-Agent\perl\bin"
$GLPIAgentExe = Join-Path -Path $GLPIAgentPath -ChildPath "glpi-agent.exe"

if (Test-Path -Path $GLPIAgentExe) {
    
    # Le fichier existe, c'est OK
    "Statut Agent GLPI : OK " | Out-File $LogFile -Append
    Write-Host "Verification Agent GLPI : OK" -ForegroundColor Green
    
    # Tenter d'obtenir la version
    try {
        # Utiliser Get-Item pour lire les metadonnees du fichier
        $VersionInfo = Get-Item $GLPIAgentExe
        $Version = $VersionInfo.VersionInfo.FileVersion
        
        if ($Version) {
            "Version Agent GLPI : $Version" | Out-File $LogFile -Append
            Write-Host "Version Agent GLPI detectee : $Version"
        } else {
            "Version Agent GLPI : Non detectee." | Out-File $LogFile -Append
            Write-Host "Version Agent GLPI : ATTENTION, executable present mais version non detectee." -ForegroundColor Yellow
        }
    }
    catch {
        "Erreur lors de la lecture de la version de l'Agent GLPI." | Out-File $LogFile -Append
        Write-Host "Erreur lors de la lecture de la version du fichier GLPI." -ForegroundColor Yellow
    }
    
} else {
    
    # Le fichier est absent, c'est une ERREUR
    "Statut Agent GLPI : ABSENT. ERREUR DE DEPLOIEMENT." | Out-File $LogFile -Append
    Write-Host "Verification Agent GLPI : ERREUR, l'executable n'a pas ete trouve." -ForegroundColor Red
}

"---" | Out-File $LogFile -Append


################################################ Lenovo System Update ################################################

# 11. Verifie la presence et la version Lenovo System Update

# Definir les chemins
$TVSUPath = "C:\Program Files (x86)\Lenovo\System Update"
$TVSUExe = Join-Path -Path $TVSUPath -ChildPath "tvsu.exe"

if (Test-Path -Path $TVSUExe) {
    
    # Le fichier existe, c'est OK
    "Statut Lenovo System Update : OK" | Out-File $LogFile -Append
    Write-Host "Verification Lenovo System Update : OK" -ForegroundColor Green
    
    # Tenter d'obtenir la version
    try {
        # Utiliser Get-Item pour lire les metadonnees du fichier
        $VersionInfo = Get-Item $TVSUExe
        $Version = $VersionInfo.VersionInfo.FileVersion
        
        if ($Version) {
            "Version Lenovo System Update : $Version" | Out-File $LogFile -Append
            Write-Host "Version Lenovo System Update detectee : $Version"
        } else {
            "Version Lenovo System Update : Non detectee." | Out-File $LogFile -Append
            Write-Host "Version Lenovo System Update : ATTENTION, executable present mais version non detectee." -ForegroundColor Yellow
        }
    }
    catch {
        "Erreur lors de la lecture de la version de tvsu.exe." | Out-File $LogFile -Append
        Write-Host "Erreur lors de la lecture de la version du fichier TVSU." -ForegroundColor Yellow
    }
    
} else {
    
    # Le fichier est absent, c'est une ERREUR
    "Statut TVSU : ABSENT. ERREUR DE DEPLOIEMENT." | Out-File $LogFile -Append
    Write-Host "Verification TVSU : ERREUR, l'executable n'a pas ete trouve." -ForegroundColor Red
}

"---" | Out-File $LogFile -Append


################################################ Chrome Remote Desktop ################################################

# Chemin de base
$CRDBasePath = "C:\Program Files (x86)\Google\Chrome Remote Desktop"
# Nom de l'executable
$CRDVersionExe = "remoting_host.exe" 

try {
    # 1. Trouver le dossier versionne le plus recent sous le chemin de base
    # On utilise Get-ChildItem sans filtre pour lister tous les dossiers versionnes
    # On trie par date de derniere modification (LastWriteTime) pour prendre le plus recent (-First 1)
    $CRDFolder = Get-ChildItem -Path $CRDBasePath -Directory -ErrorAction Stop | 
        Sort-Object -Property LastWriteTime -Descending | 
        Select-Object -ExpandProperty FullName -First 1
    
    if (-not $CRDFolder) {
        throw "Dossier de version CRD introuvable dans $CRDBasePath."
    }

    # 2. Construire le chemin complet de l'executable
    $CRDExePath = Join-Path -Path $CRDFolder -ChildPath $CRDVersionExe
    
    # 3. Verification de la presence
    if (-not (Test-Path -Path $CRDExePath)) {
        throw "Executable '$CRDVersionExe' introuvable dans le dossier versionne trouve ($CRDFolder)."
    }

    # Fichiers OK
    "Statut Chrome Remote Desktop Fichiers : OK" | Out-File $LogFile -Append
    Write-Host "Verification Chrome Remote Desktop Fichiers : OK" -ForegroundColor Green
    
    # 4. Tenter d'obtenir la version
    $VersionInfo = Get-Item $CRDExePath
    $Version = $VersionInfo.VersionInfo.FileVersion
    
    if (-not $Version) {
        $Version = $VersionInfo.VersionInfo.ProductVersion
    }
    
    if ($Version) {
        "Version Chrome Remote Desktop : $Version" | Out-File $LogFile -Append
        Write-Host "Version Chrome Remote Desktop detectee : $Version"
    } else {
        "Version Chrome Remote Desktop : ATTENTION, executable present mais version non detectee." | Out-File $LogFile -Append
        Write-Host "Version Chrome Remote Desktop : ATTENTION, version non detectee." -ForegroundColor Yellow
    }
} 
catch {
    # Capture toutes les erreurs (dossier introuvable, executable introuvable, etc.)
    "Statut Chrome Remote Desktop : ABSENT. ERREUR DE DEPLOIEMENT. Erreur: $($_.Exception.Message)" | Out-File $LogFile -Append
    Write-Host "Verification Chrome Remote Desktop : ERREUR, l'agent n'a pas ete trouve." -ForegroundColor Red
}

"---" | Out-File $LogFile -Append

################################################ Bitser ################################################

# Definir les chemins
$BitserPath = "C:\Program Files (x86)\Bitser"
$BitserExe = Join-Path -Path $BitserPath -ChildPath "Bitser.exe"

if (Test-Path -Path $BitserExe) {
    
    # Le fichier existe, c'est OK
    "Statut Bitser : OK" | Out-File $LogFile -Append 
    Write-Host "Verification Bitser : OK" -ForegroundColor Green
    
    # Tenter d'obtenir la version
    try {
        # Utiliser Get-Item pour lire les metadonnees du fichier
        $VersionInfo = Get-Item $BitserExe
        $Version = $VersionInfo.VersionInfo.FileVersion
        
        if ($Version) {
            "Version Bitser : $Version" | Out-File $LogFile -Append
            Write-Host "Version Bitser detectee : $Version"
        } else {
            "Version Bitser : Non detectee." | Out-File $LogFile -Append
            Write-Host "Version Bitser : ATTENTION, executable present mais version non detectee." -ForegroundColor Yellow
        }
    }
    catch {
        "Erreur lors de la lecture de la version de Bitser.exe." | Out-File $LogFile -Append
        Write-Host "Erreur lors de la lecture de la version du fichier Bitser." -ForegroundColor Yellow
    }
    
} else {
    
    # Le fichier est absent, c'est une ERREUR
    "Statut Bitser : ABSENT. ERREUR DE DEPLOIEMENT." | Out-File $LogFile -Append
    Write-Host "Verification Bitser : ERREUR, l'executable n'a pas ete trouve." -ForegroundColor Red
}

"---" | Out-File $LogFile -Append

################################################ Manage Engine ################################################

# Definir le chemin du dossier
$MECritialPath = "C:\Program Files (x86)\ManageEngine\UEMS_Agent"
# Nom typique du service ManageEngine
$MEServiceName = "ManageEngine UEMS - Agent" 

# 1. Verification du Dossier
if (Test-Path -Path $MECritialPath -PathType Container) {
    "Statut Dossier Manage Engine : OK" | Out-File $LogFile -Append
    Write-Host "Verification Dossier Manage Engine : OK" -ForegroundColor Green
    
    # 2. Verification du Service
    try {
        $Service = Get-Service -Name $MEServiceName -ErrorAction Stop
        
        if ($Service.Status -eq "Running") {
            "Statut Service Manage Engine : DEMARRE" | Out-File $LogFile -Append
            Write-Host "Statut Service Manage Engine : OK (Demarre)" -ForegroundColor Green
        } else {
            "Statut Service Manage Engine : PRESENT mais ARRETE (Statut: $($Service.Status))" | Out-File $LogFile -Append
            Write-Host "Statut Service Manage Engine : ATTENTION (Arrete)" -ForegroundColor Yellow
        }
    }
    catch {
        "Statut Service ManageEngine : ABSENT ou Nom incorrecte (Recherche: $MEServiceName)" | Out-File $LogFile -Append
        Write-Host "Statut Service ManageEngine : ERREUR (Service non trouve)" -ForegroundColor Red
    }
    
} else {
    
    # Le dossier est absent, c'est une ERREUR
    "Statut Dossier ManageEngine : ABSENT. ERREUR DE DEPLOIEMENT." | Out-File $LogFile -Append
    Write-Host "Verification Dossier ManageEngine : ERREUR, le dossier n'a pas ete trouve." -ForegroundColor Red
}

"---" | Out-File $LogFile -Append

################################################ PDF Split and Merge ################################################

# Definir les chemins
$PDFSamPath = "C:\Program Files\PDFsam Basic"
$PDFSamExe = Join-Path -Path $PDFSamPath -ChildPath "pdfsam.exe"

if (Test-Path -Path $PDFSamExe) {
    
    # Le fichier existe, c'est OK
    "Statut PDFsam Basic : OK " | Out-File $LogFile -Append
    Write-Host "Verification PDFsam Basic : OK" -ForegroundColor Green
    
    # Tenter d'obtenir la version
    try {
        # Utiliser Get-Item pour lire les metadonnees du fichier
        $VersionInfo = Get-Item $PDFSamExe
        $Version = $VersionInfo.VersionInfo.FileVersion
        
        if ($Version) {
            "Version PDFsam Basic : $Version" | Out-File $LogFile -Append
            Write-Host "Version PDFsam Basic detectee : $Version"
        } else {
            "Version PDFsam Basic : Non detectee." | Out-File $LogFile -Append
            Write-Host "Version PDFsam Basic : ATTENTION, executable present mais version non detectee." -ForegroundColor Yellow
        }
    }
    catch {
        "Erreur lors de la lecture de la version de pdfsam.exe." | Out-File $LogFile -Append
        Write-Host "Erreur lors de la lecture de la version du fichier PDFsam." -ForegroundColor Yellow
    }
    
} else {
    
    # Le fichier est absent, c'est une ERREUR
    "Statut PDFsam Basic : ABSENT. ERREUR DE DEPLOIEMENT." | Out-File $LogFile -Append
    Write-Host "Verification PDFsam Basic : ERREUR, l'executable n'a pas ete trouve." -ForegroundColor Red
}

"---" | Out-File $LogFile -Append



################################################ Verification Gestion USB ################################################

# Retourne 0 (SUCCESS) si tout est OFF, 1 (ECHEC) sinon.

$MismatchedDevices = 0

# 1. Recuperer toutes les instances de gestion d'alimentation et tous les peripheriques USB
$PowerInstances = Get-CimInstance -ClassName MSPower_DeviceEnable -Namespace root/WMI
$UsbDevices = Get-CimInstance -ClassName Win32_PnPEntity -Filter "PNPClass = 'USB'"

# 2. Parcourir les peripheriques USB pour verifier l'etat de leur gestion d'alimentation
$UsbDevices | ForEach-Object {
    $pnpId = $_.PNPDeviceID
    
    # Trouver l'instance de gestion d'alimentation correspondante
    $PowerInstance = $PowerInstances | Where-Object { $_.InstanceName -like "*$($pnpId)*" }
    
    if ($PowerInstance) {
        # Si l'instance est trouvee et que Enable est TRUE (Active / ON)
        if ($PowerInstance.Enable -eq $true) {
            Write-Host "ATTENTION: Gestion de l'alimentation ACTIVE pour $($pnpId)" -ForegroundColor Yellow
            $MismatchedDevices++
        }
    }
}

# 3. Resultat final et code de sortie
if ($MismatchedDevices -gt 0) {
    "STATUT: ECHEC. $MismatchedDevices peripherique(s) ont la gestion de l'alimentation ACTIVE." | Out-File $LogFile -Append
    Write-Host "Verification eCHEC : $MismatchedDevices peripherique(s) a corriger." -ForegroundColor Red
    
} else {
    "STATUT USB: SUCCES. La gestion de l'alimentation USB est DESACTIVEE." | Out-File $LogFile -Append
    Write-Host "Verification SUCCeS : Tous les peripheriques sont OFF." -ForegroundColor Green
    
}


################################################ Verification Activation Visionneuse Photo ################################################

# Definir le chemin du fichier de log principal
$RegistryPath = "HKLM:\SOFTWARE\Classes\Applications\photoviewer.dll"

"---" | Out-File $LogFile -Append

if (Test-Path -Path $RegistryPath) {
    
    # La cle de base existe, ce qui est le signe de l'activation.
    "Statut Visionneuse : OK." | Out-File $LogFile -Append
    Write-Host "Verification Visionneuse Windows : OK" -ForegroundColor Green
    
    # Facultatif: Verifier la presence d'une sous-cle specifique pour plus de certitude
    if (Test-Path -Path "$RegistryPath\shell\open\command") {
        "Statut chemin d'ouverture Visionneuse : OK." | Out-File $LogFile -Append
    } else {
        "Statut Visionneuse : ATTENTION. Cle principale trouvee, mais la commande d'ouverture (shell\open\command) est manquante." | Out-File $LogFile -Append
        Write-Host "Verification Visionneuse Windows : ATTENTION (Cle de commande manquante)" -ForegroundColor Yellow
    }

} else {
    
    # La cle de base est absente.
    "Statut Visionneuse : ABSENT. La cle de Registre '$RegistryPath' n'a PAS ete trouvee." | Out-File $LogFile -Append
    Write-Host "Verification Visionneuse Windows : ERREUR (Activation par REG echouee)" -ForegroundColor Red
}

"---" | Out-File $LogFile -Append

################################################ Verification Application des LGPO ################################################

# Definir le chemin du fichier de log principal
$RegistryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"

if (Test-Path -Path $RegistryPath) {
    
    # Recuperer toutes les valeurs (regles) sous cette cle
    try {
        $RegProps = Get-ItemProperty -Path $RegistryPath
        
        "Statut GPO System : OK. Les regles suivantes sont appliquees :" | Out-File $LogFile -Append
        Write-Host "Verification GPO System : OK. Regles appliquees." -ForegroundColor Green
        
        # Parcourir chaque propriete (regle) et l'ecrire dans le log
        $RegProps.PSObject.Properties | ForEach-Object {
            # Exclure les proprietes standard de PowerShell (PSPath, PSParentPath, etc.)
            if ($_.Name -notlike "PS*") {
                " -> REGLE: $($_.Name) = $($_.Value)" | Out-File $LogFile -Append
            }
        }

    }
    catch {
        "Statut GPO System : ERREUR lors de la lecture des valeurs." | Out-File $LogFile -Append
        Write-Host "Verification GPO System : ERREUR de lecture." -ForegroundColor Red
    }

} else {
    
    "Statut GPO System : ABSENT. La cle de Registre '$RegistryPath' n'a PAS ete trouvee." | Out-File $LogFile -Append
    Write-Host "Verification GPO System : ERREUR (Cle non trouvee)" -ForegroundColor Red
}

"---" | Out-File $LogFile -Append


################################################ Installation SentinelOne, Version et Demarage du service ################################################

# Chemins et noms de service SentinelOne
$S1BasePath = "C:\Program Files\SentinelOne"
# Motif de recherche du dossier de l'agent (utilise un joker pour la version)
$S1FolderPattern = "Sentinel Agent *" 
$S1ServiceName = "SentinelAgent" # Nom standard du service
$S1VersionExe = "SentinelUI.exe" # L'executable contenant les metadonnees de version

$S1DeploymentStatus = "ERREUR"

# 1. Recherche dynamique du dossier de version
try {
    # Trouver le chemin complet du dossier qui correspond au motif. 
    # Select -Last 1 garantit que nous prenons le dossier s'il en existe plusieurs (la version la plus recente).
    $S1FullFolder = Get-ChildItem -Path $S1BasePath -Filter $S1FolderPattern -Directory -ErrorAction Stop | 
        Sort-Object -Property LastWriteTime -Descending | 
        Select-Object -ExpandProperty FullName -First 1
    
    if (-not $S1FullFolder) {
        throw "Dossier 'Sentinel Agent *' introuvable dans $S1BasePath."
    }
    
    $S1ExePath = Join-Path -Path $S1FullFolder -ChildPath $S1VersionExe
    
    # 2. Verification de la presence de l'executable
    if (-not (Test-Path -Path $S1ExePath)) {
        throw "Executable '$S1VersionExe' introuvable dans le dossier versionne trouve ($S1FullFolder)."
    }

    # Presence OK
    "Statut SentinelOne Fichiers : OK" | Out-File $LogFile -Append
    Write-Host "Verification SentinelOne Fichiers : OK" -ForegroundColor Green
    
    # 3. Tenter d'obtenir la version
    try {
        $VersionInfo = Get-Item $S1ExePath
        $Version = $VersionInfo.VersionInfo.FileVersion
        
        if ($Version) {
            "Version SentinelOne : $Version" | Out-File $LogFile -Append
            Write-Host "Version SentinelOne detectee : $Version"
        } else {
            "Version SentinelOne : Non detectee. (Fichier trouve mais version manquante)" | Out-File $LogFile -Append
            Write-Host "Version SentinelOne : ATTENTION, version non detectee." -ForegroundColor Yellow
        }
    }
    catch {
        "Erreur lors de la lecture de la version de $S1VersionExe. Erreur: $($_.Exception.Message)" | Out-File $LogFile -Append
        Write-Host "Erreur lors de la lecture de la version du fichier S1." -ForegroundColor Yellow
    }
    
    # 4. Verification du Service
    try {
        $Service = Get-Service -Name $S1ServiceName -ErrorAction Stop
        
        if ($Service.Status -eq "Running") {
            "Statut Service SentinelOne : DEMARRE" | Out-File $LogFile -Append
            Write-Host "Statut Service SentinelOne : OK (Demarre)" -ForegroundColor Green
            $S1DeploymentStatus = "SUCCES" # Tout est parfait
        } else {
            "Statut Service SentinelOne : PRESENT mais ARRETE (Statut: $($Service.Status))" | Out-File $LogFile -Append
            Write-Host "Statut Service SentinelOne : ATTENTION (Arrete)" -ForegroundColor Yellow
            $S1DeploymentStatus = "ATTENTION"
        }
    }
    catch {
        "Statut Service SentinelOne : ABSENT (Recherche: $S1ServiceName)" | Out-File $LogFile -Append
        Write-Host "Statut Service SentinelOne : ERREUR (Service non trouve)" -ForegroundColor Red
    }
    
} 
catch {
    # Capture toutes les erreurs (dossier introuvable, executable introuvable, etc.)
    "Statut SentinelOne Fichiers : ABSENT. ERREUR DE DEPLOIEMENT MAJEURE. Erreur: $($_.Exception.Message)" | Out-File $LogFile -Append
    Write-Host "Verification SentinelOne Fichiers : ERREUR, l'agent n'a pas ete trouve." -ForegroundColor Red
}

"---" | Out-File $LogFile -Append


################################################ Installation Sekoia et sysmon ################################################

# --- Parametres des Services de Securite ---
$SekoiaServiceName = "SEKOIAEndpointAgent"
$SysmonServiceName = "Sysmon64"
$SekoiaValidationStatus = "ERREUR"
$SysmonValidationStatus = "ERREUR"

# 1. Verification du Service SEKOIA
try {
    $ServiceSekoia = Get-Service -Name $SekoiaServiceName -ErrorAction Stop
    
    if ($ServiceSekoia.Status -eq "Running") {
        "Statut Service SEKOIA : DEMARRE" | Out-File $LogFile -Append
        Write-Host "Verification SEKOIA : OK (Service Demarre)" -ForegroundColor Green
        $SekoiaValidationStatus = "SUCCES"
    } else {
        "Statut Service SEKOIA : PRESENT mais ARRETE (Statut: $($ServiceSekoia.Status))" | Out-File $LogFile -Append
        Write-Host "Verification SEKOIA : ATTENTION (Service Arrete)" -ForegroundColor Yellow
        $SekoiaValidationStatus = "ATTENTION"
    }
}
catch {
    "Statut Service SEKOIA : ABSENT (Recherche: $SekoiaServiceName)" | Out-File $LogFile -Append
    Write-Host "Verification SEKOIA : ERREUR (Service non trouve)" -ForegroundColor Red
}


# 2. Verification du Service Sysmon
try {
    $ServiceSysmon = Get-Service -Name $SysmonServiceName -ErrorAction Stop
    
    if ($ServiceSysmon.Status -eq "Running") {
        "Statut Service Sysmon : DEMARRE" | Out-File $LogFile -Append
        Write-Host "Verification Sysmon : OK (Service Demarre)" -ForegroundColor Green
        $SysmonValidationStatus = "SUCCES"
    } else {
        "Statut Service Sysmon : PRESENT mais ARRETE (Statut: $($ServiceSysmon.Status))" | Out-File $LogFile -Append
        Write-Host "Verification Sysmon : ATTENTION (Service Arrete)" -ForegroundColor Yellow
        $SysmonValidationStatus = "ATTENTION"
    }
}
catch {
    # Sysmon64 n'est pas toujours le nom exact. On essaie le nom generique 'Sysmon' en cas d'echec
    try {
        $SysmonServiceName = "Sysmon"
        $ServiceSysmon = Get-Service -Name $SysmonServiceName -ErrorAction Stop
        
        if ($ServiceSysmon.Status -eq "Running") {
            "Statut Service Sysmon : PRESENT et DEMARRE (Nom trouve: $SysmonServiceName)" | Out-File $LogFile -Append
            Write-Host "Verification Sysmon : OK (Service Demarre)" -ForegroundColor Green
            $SysmonValidationStatus = "SUCCES"
        } else {
            "Statut Service Sysmon : PRESENT mais ARRETE (Nom trouve: $SysmonServiceName)" | Out-File $LogFile -Append
            Write-Host "Verification Sysmon : ATTENTION (Service Arrete)" -ForegroundColor Yellow
            $SysmonValidationStatus = "ATTENTION"
        }
    }
    catch {
        "Statut Service Sysmon : ABSENT (Noms recherches: Sysmon64, Sysmon)" | Out-File $LogFile -Append
        Write-Host "Verification Sysmon : ERREUR (Service non trouve)" -ForegroundColor Red
    }
}


"---" | Out-File $LogFile -Append


#############################################################################
#
#                                Impression
#
#############################################################################


# Bloc pour imprimer le rapport, le bloc est mis en fonction pour demander si on l'imprime ou non
function Invoke-RawPrint {
# Le chemin de votre fichier de validation doit être connu ici.

# --- Parametres a ajuster ---
$PrinterIP = "192.110.58.48"       # Remplacer par l'IP de votre imprimante
$PrinterPort = 9100                # Le port standard pour l'impression Raw

# --- NOUVELLE eTAPE : Charger le contenu du fichier Log ---

# -----------------------------------------------------------------------------------

# --- NOUVELLE LOGIQUE DE COUPE DE LIGNE (WrapWidth = 80) ---
$WrapWidth = 78

if (Test-Path -Path $LogFile) {
    Write-Host "Contenu du fichier log chargé. Formatage pour impression..."
    
    # Charger le contenu ligne par ligne
    $RawContentLines = Get-Content -Path $LogFile -Encoding ASCII 
    $FormattedContent = New-Object System.Text.StringBuilder

    # Couper les lignes trop longues
    foreach ($Line in $RawContentLines) {
        $CurrentLine = $Line
        
        while ($CurrentLine.Length -gt $WrapWidth) {
            # Ajout de la partie coupée + saut de ligne (CRLF)
            [void]$FormattedContent.Append($CurrentLine.Substring(0, $WrapWidth) + "`r`n")
            # Enlever la partie traitée
            $CurrentLine = $CurrentLine.Substring($WrapWidth)
        }
        
        # Ajouter le reste de la ligne + saut de ligne
        [void]$FormattedContent.Append($CurrentLine + "`r`n")
    }

    $ContentToPrint = $FormattedContent.ToString()
    Write-Host "Contenu formaté chargé. Taille : $($ContentToPrint.Length) octets."
} else {
    Write-Host "ERREUR : Fichier log ($LogFile) non trouvé. Impossible d'imprimer." -ForegroundColor Red
    return # Utiliser 'return' au lieu de 'exit' pour ne pas arrêter le script principal
}
# --- FIN DE LA LOGIQUE DE COUPE DE LIGNE ---

# --- Execution ---
try {
    # 1. Creer la connexion TCP
    $TCPClient = New-Object System.Net.Sockets.TcpClient
    $TCPClient.Connect($PrinterIP, $PrinterPort)

    if ($TCPClient.Connected) {
        Write-Host "Connexion etablie a $($PrinterIP):$($PrinterPort). Envoi des donnees..."

        # 2. Obtenir le flux de donnees
        $NetworkStream = $TCPClient.GetStream()

        # 3. Convertir le texte en tableau d'octets (Utilisez le nouveau contenu charge)
        $Encoding = [System.Text.Encoding]::ASCII
        # Utiliser $ContentToPrint
        $Bytes = $Encoding.GetBytes($ContentToPrint + "`r`n") 

        # 4. Envoyer les octets
        $NetworkStream.Write($Bytes, 0, $Bytes.Length)

        Write-Host "Impression envoyee avec succes." -ForegroundColor Green
    }
}
catch {
    Write-Error "Erreur lors de l'impression : $($_.Exception.Message)"
}
finally {
    # 5. Fermer la connexion
    if ($NetworkStream) { $NetworkStream.Dispose() }
    if ($TCPClient) { $TCPClient.Close() }
}
}
##################################################################################################

# Demande si on imprime le rapport 

Write-Host "Fichier de validation genere a $LogFile"

# 1. Declenchement de la question et capture de la reponse
$reponse = Read-Host "Voulez-vous imprimer le rapport ? (O/N)"
$FunctionName = "Invoke-RawPrint"

# 2. Verification de la reponse
# On verifie si la reponse est 'O' (Oui), en ignorant la casse (-clt = case-less equal, ou -match '^[oO] pour une expression reguliere)
if ($reponse -match '^[oO]') {
    # Execution de la fonction
    & $FunctionName
} else {
    Write-Host "Action annulee ou reponse non reconnue." -ForegroundColor Yellow
}