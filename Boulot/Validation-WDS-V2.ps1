#######################################################################
#                                                                     #
#    Script de Validation de Deploiement WDS (Version Finale 2)       #
#                                                                     #
#    Auteur : Nicolas CLAVERIE                                        #
#                                                                     #
#######################################################################


# --- Verification des droits Administrateur ---
$currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $arguments = "& '" + $myinvocation.mycommand.definition + "'"
    Start-Process powershell.exe -Verb RunAs -ArgumentList $arguments
    exit
}

# --- Initialisation du Log ---
$LogFile = "C:\Temp\Validation_WDS_Simple.log"
$DateExecution = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$NumInventaire = Read-Host "Entrez numero d'inventaire"

if (!(Test-Path "C:\Temp")) { New-Item -ItemType Directory -Path "C:\Temp" | Out-Null }

"=======================================================" | Out-File $LogFile
"Deploiement WDS verifie le $DateExecution" | Out-File $LogFile -Append
"Hostname : $env:COMPUTERNAME / Numero d'inventaire : $NumInventaire" | Out-File $LogFile -Append


#############################################################################
#                            Partie Active Directory
#############################################################################

$ADCredentials = Get-Credential -Message "Veuillez entrer vos identifiants de domaine Active Directory"
$DomainPath = "LDAP://TER_SUD.local" 

try {
    $DomainEntry = New-Object System.DirectoryServices.DirectoryEntry `
        -ArgumentList $DomainPath, $ADCredentials.UserName, $ADCredentials.GetNetworkCredential().Password
    $ADSI = New-Object System.DirectoryServices.DirectorySearcher
    $ADSI.SearchRoot = $DomainEntry
    $ADSI.Filter = "(&(objectCategory=computer)(cn=$env:COMPUTERNAME))"
    $SearchResult = $ADSI.FindOne()

    if ($SearchResult) {
        Write-Host "Chemin AD trouve : $($SearchResult.Path)" -ForegroundColor Green
        $SearchResult.Path | Out-File $LogFile -Append
    }
    else {
        Write-Host "ERREUR : Ordinateur introuvable dans l'AD." -ForegroundColor Red
        "ERREUR: Ordinateur introuvable dans l'AD" | Out-File $LogFile -Append
    }
}
catch {
    Write-Host "Erreur connexion AD : $($_.Exception.Message)" -ForegroundColor Red
    "ERREUR CRITIQUE AD : $($_.Exception.Message)" | Out-File $LogFile -Append
}
"Verifie par $($ADCredentials.UserName)" | Out-File $LogFile -Append
"=======================================================" | Out-File $LogFile -Append


#############################################################################
#                            Partie BIOS (Lenovo)
#############################################################################

"--- Verification BIOS ---" | Out-File $LogFile -Append
Write-Host "--- Verification BIOS Lenovo ---" -ForegroundColor Cyan

function Get-LenovoSettingValue {
    param ($Name, $Collection)
    $setting = $Collection | Where-Object { $_.CurrentSetting -like "$Name,*" } | Select-Object -First 1
    if ($setting) { return ($setting.CurrentSetting -split ",", 2)[1] }
    return "Non trouve"
}

try {
    # 1. Mot de passe BIOS
    $mdpWmi = Get-WmiObject -Namespace root\wmi -Class Lenovo_BiosPasswordSettings -ErrorAction Stop
    if ($mdpWmi.PasswordState -ge 2) { 
        $statusMdp = "PRESENT (Securise)"
        Write-Host "Mot de passe BIOS : $statusMdp" -ForegroundColor Green
    }
    elseif ($mdpWmi.PasswordState -eq 0) {
        $statusMdp = "ABSENT"
        Write-Host "Mot de passe BIOS : $statusMdp" -ForegroundColor Red
    }
    else {
        $statusMdp = "PRESENT (Type $($mdpWmi.PasswordState))"
        Write-Host "Mot de passe BIOS : $statusMdp" -ForegroundColor Yellow
    }
    "Bios Password : $statusMdp" | Out-File $LogFile -Append

    # 2. Autres reglages
    $biosSettings = Get-WmiObject -Namespace root\wmi -Class Lenovo_BiosSetting -ErrorAction Stop
    $CheckList = @(
        @{Name = "BIOSPasswordAtBootDeviceList"; Label = "Password at Boot Device List" },
        @{Name = "AbsolutePersistenceModuleActivation"; Label = "Absolute Persistence Module" },
        @{Name = "SecureBoot"; Label = "Secure Boot" },
        @{Name = "WakeOnLAN*"; Label = "Wake On LAN" },
        @{Name = "StartupOptionKeys"; Label = "Option Key Display" },
        @{Name = "BootOrder*"; Label = "Ordre de demarrage" }
    )

    foreach ($check in $CheckList) {
        $valeur = Get-LenovoSettingValue -Name $check.Name -Collection $biosSettings
        "$($check.Label) : $valeur" | Out-File $LogFile -Append
        if ($valeur -match "Enable|PermanentlyDisable|Active") {
            Write-Host "$($check.Label) : $valeur" -ForegroundColor Green
        }
        elseif ($valeur -match "Disable") {
            Write-Host "$($check.Label) : $valeur" -ForegroundColor Yellow
        }
        else {
            Write-Host "$($check.Label) : $valeur" 
        }
    }
}
catch {
    "Erreur lecture BIOS Lenovo." | Out-File $LogFile -Append
    Write-Host "Erreur lecture BIOS (WMI inaccessible ou PC non Lenovo)." -ForegroundColor Red
}

"---" | Out-File $LogFile -Append

#############################################################################
#                            Verifications Fichiers de base
#############################################################################

if (Test-Path "C:\DefaultApps\AppDefault.xml") {
    "Fichier AppDefault.xml : OK" | Out-File $LogFile -Append; Write-Host "AppDefault.xml : OK" -ForegroundColor Green
}
else {
    "Fichier AppDefault.xml : ABSENT" | Out-File $LogFile -Append; Write-Host "AppDefault.xml : ERREUR" -ForegroundColor Red
}

if (Test-Path "C:\Windows\Certificat\_.groupe-terresdusud.fr.crt") {
    "Certificat GLPI : OK" | Out-File $LogFile -Append; Write-Host "Certificat GLPI : OK" -ForegroundColor Green
}
else {
    "Certificat GLPI : ABSENT" | Out-File $LogFile -Append; Write-Host "Certificat GLPI : ERREUR" -ForegroundColor Red
}

#############################################################################
#                            Partie Imprimantes
#############################################################################

"---" | Out-File $LogFile -Append

$Drivers = @(
    @{Path = "C:\Imprimantes\CANON\GPlus_PCL6_Driver_V230_W64_00\Driver\CNP60MA64.INF"; Name = "CANON" },
    @{Path = "C:\Imprimantes\HP\pcl6-x64-6.9.0.24630"; Name = "HP" },
    @{Path = "C:\Imprimantes\LEXMARK\Lexmark_Universal_v2_XL_3_0_2\Drivers\Print\GDI"; Name = "LEXMARK" },
    @{Path = "C:\Imprimantes\XEROX\UNIV_5.1035.2.0_PCL6_x64_Driver.inf"; Name = "XEROX" }
)

foreach ($d in $Drivers) {
    if (Test-Path $d.Path) {
        "Pilote $($d.Name) : OK" | Out-File $LogFile -Append; Write-Host "Drivers $($d.Name) : OK" -ForegroundColor Green
    }
    else {
        "Pilote $($d.Name) : ABSENT" | Out-File $LogFile -Append; Write-Host "Drivers $($d.Name) : ERREUR" -ForegroundColor Red
    }
}

#############################################################################
#                            Partie Logiciels
#############################################################################

"---" | Out-File $LogFile -Append

# ----------------------------- Fonction generique pour verifier un EXE -----------------------------
function Check-App {
    param($Name, $Path)
    if (Test-Path $Path) {
        try {
            $Ver = (Get-Item $Path).VersionInfo.FileVersion
            if (!$Ver) { $Ver = "Version non detectee" }
            "Statut $Name : OK (v$Ver)" | Out-File $LogFile -Append
            Write-Host "Verification $Name : OK (v$Ver)" -ForegroundColor Green
        }
        catch {
            "Statut $Name : OK (Erreur lecture version)" | Out-File $LogFile -Append
            Write-Host "Verification $Name : OK (Erreur version)" -ForegroundColor Yellow
        }
    }
    else {
        "Statut $Name : ABSENT" | Out-File $LogFile -Append
        Write-Host "Verification $Name : ERREUR (Absent)" -ForegroundColor Red
    }
}

# Verification de Libre Office

Check-App -Name "LibreOffice" -Path "C:\Program Files\LibreOffice\program\soffice.exe"
"---" | Out-File $LogFile -Append

# Verification de l'Agent GLPI

Check-App -Name "Agent GLPI" -Path "C:\Program Files\GLPI-Agent\perl\bin\glpi-agent.exe"
"---" | Out-File $LogFile -Append

# Verification de Lenovo system update

Check-App -Name "Lenovo System Update" -Path "C:\Program Files (x86)\Lenovo\System Update\tvsu.exe"
"---" | Out-File $LogFile -Append

# ----------------------------- Chrome Remote Desktop -----------------------------

$CRDBase = "C:\Program Files (x86)\Google\Chrome Remote Desktop"
try {
    $CRDFolder = Get-ChildItem -Path $CRDBase -Directory -ErrorAction Stop | Sort-Object LastWriteTime -Descending | Select-Object -ExpandProperty FullName -First 1
    if ($CRDFolder -and (Test-Path "$CRDFolder\remoting_host.exe")) {
        $Ver = (Get-Item "$CRDFolder\remoting_host.exe").VersionInfo.FileVersion
        "Statut Chrome Remote Desktop : OK (v$Ver)" | Out-File $LogFile -Append
        Write-Host "Verification Chrome Remote Desktop : OK ($Ver)" -ForegroundColor Green
    }
    else { throw "EXE introuvable" }
}
catch {
    "Statut Chrome Remote Desktop : ABSENT/ERREUR" | Out-File $LogFile -Append
    Write-Host "Verification Chrome Remote Desktop : ERREUR" -ForegroundColor Red
}
"---" | Out-File $LogFile -Append

Check-App -Name "Bitser" -Path "C:\Program Files (x86)\Bitser\Bitser.exe"
"---" | Out-File $LogFile -Append

# ----------------------------- Manage Engine -----------------------------

if (Test-Path "C:\Program Files (x86)\ManageEngine\UEMS_Agent") {
    try {
        $Svc = Get-Service -Name "ManageEngine UEMS - Agent" -ErrorAction Stop
        if ($Svc.Status -eq "Running") {
            "Statut ManageEngine : OK (Service Demarre)" | Out-File $LogFile -Append
            Write-Host "ManageEngine : OK" -ForegroundColor Green
        }
        else {
            "Statut ManageEngine : ARRETE" | Out-File $LogFile -Append
            Write-Host "ManageEngine : ATTENTION (Arrete)" -ForegroundColor Yellow
        }
    }
    catch {
        "Statut ManageEngine : ERREUR SERVICE" | Out-File $LogFile -Append
        Write-Host "ManageEngine : ERREUR SERVICE" -ForegroundColor Red
    }
}
else {
    "Statut ManageEngine : DOSSIER ABSENT" | Out-File $LogFile -Append
    Write-Host "ManageEngine : ERREUR (Dossier absent)" -ForegroundColor Red
}
"---" | Out-File $LogFile -Append

Check-App -Name "PDFsam Basic" -Path "C:\Program Files\PDFsam Basic\pdfsam.exe"
"---" | Out-File $LogFile -Append

#############################################################################
#                            Verifications Systeme
#############################################################################

#----------------------------- Activation du RDP ----------------------------- 

$rdpKey = "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server"
$rdpValue = Get-ItemProperty -Path $rdpKey -Name fDenyTSConnections

if ($rdpValue.fDenyTSConnections -eq 0) {
    "RDP est ACTIVe" | Out-File $LogFile -Append
    Write-Host "RDP est ACTIVe" -ForegroundColor Green
}
else {
    "RDP est DeSACTIVe" | Out-File $LogFile -Append
    Write-Host "RDP est DeSACTIVe" -ForegroundColor Yellow
}

"---" | Out-File $LogFile -Append

#----------------------------- Gestion USB ----------------------------- 

$PowerInstances = Get-CimInstance -ClassName MSPower_DeviceEnable -Namespace root/WMI
$UsbDevices = Get-CimInstance -ClassName Win32_PnPEntity -Filter "PNPClass = 'USB'"
$Mismatched = 0
$UsbDevices | ForEach-Object {
    $pnpId = $_.PNPDeviceID
    $Inst = $PowerInstances | Where-Object { $_.InstanceName -like "*$($pnpId)*" }
    if ($Inst.Enable -eq $true) { $Mismatched++ }
}
if ($Mismatched -gt 0) {
    "USB Power : ECHEC ($Mismatched actifs)" | Out-File $LogFile -Append; Write-Host "USB Power : ECHEC ($Mismatched a corriger)" -ForegroundColor Red
}
else {
    "USB Power : OK" | Out-File $LogFile -Append; Write-Host "USB Power : OK" -ForegroundColor Green
}

# ----------------------------- Visionneuse Photo ----------------------------- 

"---" | Out-File $LogFile -Append
if (Test-Path "HKLM:\SOFTWARE\Classes\Applications\photoviewer.dll") {
    "Visionneuse Photo : OK" | Out-File $LogFile -Append; Write-Host "Visionneuse Photo : OK" -ForegroundColor Green
}
else {
    "Visionneuse Photo : ABSENT" | Out-File $LogFile -Append; Write-Host "Visionneuse Photo : ERREUR" -ForegroundColor Red
}

# ----------------------------- GPO System ----------------------------- 

"---" | Out-File $LogFile -Append
if (Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System") {
    "GPO System : OK (Regles trouvees)" | Out-File $LogFile -Append; Write-Host "GPO System : OK" -ForegroundColor Green
    (Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System").PSObject.Properties | Where-Object { $_.Name -notlike "PS*" } | ForEach-Object { " -> $($_.Name)=$($_.Value)" | Out-File $LogFile -Append }
}
else {
    "GPO System : ABSENT" | Out-File $LogFile -Append; Write-Host "GPO System : ERREUR" -ForegroundColor Red
}

"---" | Out-File $LogFile -Append

# ----------------------------- VSSadmin pour la protection systeme ----------------------------- 

$shadow = vssadmin list shadows | Select-String "C:"
if ($shadow) {
    "Protection systeme C: : ACTIVE" | Out-File $LogFile -Append; Write-Host "Protection systeme C: : ACTIVE" -ForegroundColor Green
}
else {
    "Protection systeme C: : INACTIVE/VIDE" | Out-File $LogFile -Append; Write-Host "Protection systeme C: : ATTENTION" -ForegroundColor Yellow
}

$line = vssadmin list shadowstorage | Select-String "Espace maximal" | Select-Object -First 1

# Extraction propre du pourcentage "nombre%"
if ($line -match '(\d+)\s*%') {
    $percent = [int]$matches[1]
}
else {
    $percent = $null
}

# Affichage avec couleur
if ($percent -eq 5) {
    "Espace maximal = $percent%" | Out-File $LogFile -Append; Write-Host "Espace maximal = $percent%" -ForegroundColor Green
}
else {
    "Espace maximal = $percent%" | Out-File $LogFile -Append; Write-Host "Espace maximal = $percent%" -ForegroundColor Yellow
}



"---" | Out-File $LogFile -Append

#----------------------------- 1. Windows Update (Methode Avancee : Securite vs Office) ----------------------------- 

Write-Host "Analyse Windows Update (OS vs Office 2016 vs Antivirus)..." -ForegroundColor Cyan
try {
    $UpdateSession = New-Object -ComObject Microsoft.Update.Session
    $UpdateSearcher = $UpdateSession.CreateUpdateSearcher()
    $AllUpdates = $UpdateSearcher.Search("IsInstalled=0 and IsHidden=0 and Type='Software'").Updates

    # Filtres
    $DefUpdates = $AllUpdates | Where-Object { $_.Title -match "Definition|Intelligence" -or $_.Categories.Name -contains "Definition Updates" }
    $Office16Updates = $AllUpdates | Where-Object { $_.Title -match "2016" -and $_.Title -match "Office|Word|Excel|Outlook|PowerPoint|Visio|Project|Access|Proofing" }
    $SecuUpdates = $AllUpdates | Where-Object { 
        ($_.MsrcSeverity -match "Critical|Important" -or $_.Categories.Name -contains "Security Updates") -and 
        ($_.Title -notin $DefUpdates.Title) -and ($_.Title -notin $Office16Updates.Title)
    }
    $OtherUpdates = $AllUpdates | Where-Object { $_.Title -notin $DefUpdates.Title -and $_.Title -notin $Office16Updates.Title -and $_.Title -notin $SecuUpdates.Title }

    # Logique d'affichage
    if ($SecuUpdates.Count -gt 0) {
        "Windows Update : ECHEC. $($SecuUpdates.Count) patchs SeCURITe SYSTEME manquants." | Out-File $LogFile -Append
        Write-Host "Windows Update : ALERTE ROUGE ($($SecuUpdates.Count) patchs OS manquants)" -ForegroundColor Red
        foreach ($u in $SecuUpdates) { 
            " -> MANQUE OS : $($u.Title)" | Out-File $LogFile -Append
            Write-Host "    -> $($u.Title)" -ForegroundColor Red 
        }
    }
    elseif ($Office16Updates.Count -gt 0) {
        "Windows Update : ATTENTION. $($Office16Updates.Count) patchs Office 2016 en attente." | Out-File $LogFile -Append
        Write-Host "Windows Update : A faire ($($Office16Updates.Count) patchs Office 2016)" -ForegroundColor Yellow
    }
    elseif ($DefUpdates.Count -gt 0) {
        "Windows Update : OK. $($DefUpdates.Count) maj Defender en attente." | Out-File $LogFile -Append
        Write-Host "Windows Update : OK ($($DefUpdates.Count) maj Defender)" -ForegroundColor Green
    }
    elseif ($OtherUpdates.Count -gt 0) {
        "Windows Update : INFO. $($OtherUpdates.Count) maj optionnelles." | Out-File $LogFile -Append
        Write-Host "Windows Update : Info ($($OtherUpdates.Count) maj optionnelles)" -ForegroundColor Yellow
    }
    else {
        "Windows Update : SYSTEME A JOUR" | Out-File $LogFile -Append
        Write-Host "Windows Update : OK (A jour)" -ForegroundColor Green
    }

    # Reboot Pending
    if ((New-Object -ComObject Microsoft.Update.SystemInfo).RebootRequired) {
        "Windows Update : Redemarrage en attente : OUI" | Out-File $LogFile -Append
        Write-Host "Windows Update : Redemarrage REQUIS" -ForegroundColor Red
    }
}
catch {
    "Windows Update : ERREUR AGENT" | Out-File $LogFile -Append; Write-Host "Windows Update : ERREUR AGENT" -ForegroundColor Red
}
"---" | Out-File $LogFile -Append

#----------------------------- 2. Verification WINGET (Methode demandee : Comptage mots-cles) ----------------------------- 

Write-Host "Verification Winget..." -ForegroundColor Cyan

$wingetUpdates = winget upgrade --accept-source-agreements --accept-package-agreements 2>$null
$updateCount = ($wingetUpdates | Select-String "Disponi" -Context 0, 1).Count
# fallback si format different (Anglais ou autre)
if ($updateCount -eq 0) {
    $updateCount = ($wingetUpdates | Select-String "Upgrade available|mis a jour").Count
}

"Applications (Winget) : $updateCount mise(s) a jour disponible(s)" | Out-File $LogFile -Append
if ($updateCount -gt 0) {
    Write-Host "Winget : $updateCount mise(s) a jour disponible(s)" -ForegroundColor Yellow
}
else {
    Write-Host "Winget : 0 mise(s) a jour disponible(s)" -ForegroundColor Green
}

#----------------------------- 3. Verification Microsoft Store ----------------------------- 
Write-Host "Verification Microsoft Store..." -ForegroundColor Cyan

$storeResult = winget upgrade --source msstore 2>$null
$storeCount = ($storeResult | Select-String "Disponi|available|mis a jour").Count

"Microsoft Store : $storeCount mise(s) a jour disponible(s)" | Out-File $LogFile -Append
if ($storeCount -gt 0) {
    Write-Host "Microsoft Store : $storeCount mise(s) a jour disponible(s)" -ForegroundColor Yellow
}
else {
    Write-Host "Microsoft Store : 0 mise(s) a jour disponible(s)" -ForegroundColor Green
}

"---" | Out-File $LogFile -Append

#############################################################################
#                            Securite Finale (Agents)
#############################################################################

#----------------------------- SentinelOne ----------------------------- 
$S1BasePath = "C:\Program Files\SentinelOne"
try {
    $S1FullFolder = Get-ChildItem -Path $S1BasePath -Filter "Sentinel Agent *" -Directory -ErrorAction Stop | Sort-Object LastWriteTime -Descending | Select-Object -ExpandProperty FullName -First 1
    if ($S1FullFolder -and (Test-Path "$S1FullFolder\SentinelUI.exe")) {
        $Ver = (Get-Item "$S1FullFolder\SentinelUI.exe").VersionInfo.FileVersion
        "SentinelOne : Fichiers OK (v$Ver)" | Out-File $LogFile -Append
        Write-Host "SentinelOne : Fichiers OK (v$Ver)" -ForegroundColor Green
        
        $Svc = Get-Service -Name "SentinelAgent" -ErrorAction Stop
        if ($Svc.Status -eq "Running") {
            "SentinelOne Service : DEMARRE" | Out-File $LogFile -Append; Write-Host "SentinelOne Service : OK" -ForegroundColor Green
        }
        else {
            "SentinelOne Service : ARRETE" | Out-File $LogFile -Append; Write-Host "SentinelOne Service : ARRETE" -ForegroundColor Yellow
        }
    }
    else { throw "Fichiers introuvables" }
}
catch {
    "SentinelOne : ABSENT/ERREUR" | Out-File $LogFile -Append; Write-Host "SentinelOne : ERREUR" -ForegroundColor Red
}

"---" | Out-File $LogFile -Append

#----------------------------- Sekoia & Sysmon ----------------------------- 
function Check-SecService {
    param($Name, $Display)
    try {
        $Svc = Get-Service -Name $Name -ErrorAction Stop
        if ($Svc.Status -eq "Running") {
            "$Display : DEMARRE" | Out-File $LogFile -Append; Write-Host "$Display : OK" -ForegroundColor Green
        }
        else {
            "$Display : ARRETE" | Out-File $LogFile -Append; Write-Host "$Display : ARRETE" -ForegroundColor Yellow
        }
    }
    catch {
        "$Display : NON TROUVE" | Out-File $LogFile -Append; Write-Host "$Display : NON TROUVE" -ForegroundColor Red
    }
}

Check-SecService -Name "SEKOIAEndpointAgent" -Display "SEKOIA"
Check-SecService -Name "Sysmon64" -Display "Sysmon"

"---" | Out-File $LogFile -Append

#############################################################################
#                           Export fichier de log sur lecteur reseau
#############################################################################


$NetworkPath = "G:\Mon Drive\temp"
$DriveName = "LogDrive"

try {
    # Montre du lecteur reseau
    $psDrive = New-PSDrive -Name $DriveName -PSProvider FileSystem -Root $NetworkPath -Credential $ADCredentials -ErrorAction Stop

    # Creation du nom en fonction de l’ordi + date
    $ComputerName = $env:COMPUTERNAME
    $Date = Get-Date -Format "yyyy-MM-dd"
    $RemoteFileName = "$NumInventaire-$ComputerName-$Date.txt"

    # Chemin distant final
    $RemotePath = "$($psDrive.Root)\$RemoteFileName"

    # ➜ COPIE DU FICHIER LOCAL VERS LE PARTAGE
    Copy-Item -Path $LogFile -Destination $RemotePath -Force -ErrorAction Stop

    Write-Host "Fichier transfere vers $RemotePath" -ForegroundColor Green
}
catch {
    $errorMessage = $_.Exception.Message

    if ($errorMessage -match "Access is denied") {
        Write-Host "Acces refuse au partage reseau." -ForegroundColor Red
    }
    else {
        Write-Host "Erreur : $errorMessage" -ForegroundColor Red
    }
}
finally {
    Remove-PSDrive -Name $DriveName -Force -ErrorAction SilentlyContinue
}


#############################################################################
#                            Impression
#############################################################################

function Invoke-RawPrint {
    $PrinterIP = "192.110.58.48"
    $PrinterPort = 9100
    $WrapWidth = 78
    
    # --- Code PCL pour Duplex (Recto Verso) ---
    # ESC (caractère ASCII 27)
    $ESC = [char]27
    
    # Commande PCL pour activer le recto verso (Long-Edge Binding - reliure bord long)
    # [ESC]&l1S
    $DuplexCommand = "$ESC&l1S" # Utilisez $ESC&l2S pour Short-Edge Binding si vous préférez l'autre sens
    
    # Ajoutez un saut de page (Form Feed - ASCII 12) à la fin du flux pour éjecter la dernière page
    $FormFeed = [char]12
    # -------------------------------------------

    if (Test-Path $LogFile) {
        Write-Host "Preparation impression..."
        
        # 1. Préfixer le contenu avec la commande PCL
        $PCLContent = $DuplexCommand + "`r`n"
        $FormattedContent = New-Object System.Text.StringBuilder
        [void]$FormattedContent.Append($PCLContent)
        
        # ... (votre code existant pour le WrapWidth et la mise en forme du texte) ...
        
        foreach ($Line in (Get-Content $LogFile -Encoding ASCII)) {
            $CurrentLine = $Line
            while ($CurrentLine.Length -gt $WrapWidth) {
                [void]$FormattedContent.Append($CurrentLine.Substring(0, $WrapWidth) + "`r`n")
                $CurrentLine = $CurrentLine.Substring($WrapWidth)
            }
            [void]$FormattedContent.Append($CurrentLine + "`r`n")
        }
        
        # 2. Ajouter un saut de page pour terminer l'impression
        [void]$FormattedContent.Append($FormFeed)

        # 3. Encoder et envoyer le tout
        $Bytes = [System.Text.Encoding]::ASCII.GetBytes($FormattedContent.ToString()) 
        
        try {
            $TCP = New-Object System.Net.Sockets.TcpClient
            $TCP.Connect($PrinterIP, $PrinterPort)
            $Stream = $TCP.GetStream()
            $Stream.Write($Bytes, 0, $Bytes.Length)
            Write-Host "Impression OK (avec tentative Duplex PCL)" -ForegroundColor Green
            $Stream.Dispose(); $TCP.Close()
        }
        catch { Write-Error "Erreur impression : $($_.Exception.Message)" }
    }
}

Write-Host "Log genere : $LogFile"
$rep = Read-Host "Imprimer le rapport ? (O/N)"
if ($rep -match '^[oO]') { Invoke-RawPrint }
