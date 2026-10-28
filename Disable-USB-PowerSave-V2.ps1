# Script de desactivation de la gestion de l'alimentation USB (WMI/CIM)
# Integration ManageEngine OS Deployer / MDT avec persistance au demarrage

# --- Configuration du journal ---
$LogFile = "C:\windows\temp\Disable-USBPowerSave-WMI.log"

Function Write-Log {
    Param ([string]$LogString)
    $Stamp = (Get-Date).toString("yyyy-MM-dd HH:mm:ss")
    $LogMessage = "$Stamp $LogString"
    Add-content $LogFile -value $LogMessage
    Write-Host $LogString
}

# --- Debut du Script ---
Write-Log "=== Debut de la configuration de l'alimentation USB ==="

# 1. Traitement des peripheriques USB actuellement connectes
try {
    Write-Log "Recuperation des instances de gestion d'alimentation (MSPower_DeviceEnable)..."
    $powerManagementInstances = Get-CimInstance -ClassName MSPower_DeviceEnable -Namespace root/WMI -ErrorAction Stop
    Write-Log "$($powerManagementInstances.Count) instances trouvees."

    Write-Log "Recuperation des peripheriques PnP de la classe 'USB'..."
    $usbDevices = Get-CimInstance -ClassName Win32_PnPEntity -Filter "PNPClass = 'USB'" -ErrorAction Stop
    Write-Log "$($usbDevices.Count) peripheriques USB trouves."

    Write-Log "Filtrage pour trouver les correspondances..."
    $devicesToAdjust = $usbDevices | ForEach-Object {
        $pnpDevice = $_
        $matchingPowerInstance = $powerManagementInstances | Where-Object { $_.InstanceName -like "*$($pnpDevice.PNPDeviceID)*" }
        if ($matchingPowerInstance) {
            Write-Log "-> Correspondance trouvee pour : $($pnpDevice.Caption) ($($pnpDevice.PNPDeviceID))"
            return $matchingPowerInstance
        }
    }

    if ($devicesToAdjust.Count -gt 0) {
        Write-Log "$($devicesToAdjust.Count) peripherique(s) a modifier."
        Write-Log "Application du parametre 'Enable = false'..."
        $devicesToAdjust | Set-CimInstance -Property @{ Enable = $false } -ErrorAction Stop
        Write-Log "Gestion de l'alimentation desactivee avec succes."
    } else {
        Write-Log "Aucun peripherique USB correspondant avec gestion active n'a ete trouve."
    }
}
catch {
    Write-Log "ERREUR : Une erreur critique est survenue. Erreur: $($_.Exception.Message)"
}

# 2. Persistance pour les peripheriques USB branches ulterieurement
$ScriptInstallDir = "C:\ProgramData\OSDeployer\Scripts"
$ScriptTarget     = "$ScriptInstallDir\Disable-USB-PowerSave.ps1"

if (-not (Test-Path -Path $ScriptInstallDir)) {
    New-Item -ItemType Directory -Path $ScriptInstallDir -Force | Out-Null
}

# Copie locale du script si execute depuis l'agent ou un repertoire temporaire
if ($PSCommandPath -and ($PSCommandPath -ne $ScriptTarget)) {
    Copy-Item -Path $PSCommandPath -Destination $ScriptTarget -Force
}

$taskExists = Get-ScheduledTask -TaskName "Disable-USB-PowerSave" -ErrorAction SilentlyContinue
if (-not $taskExists) {
    Write-Log "Creation de la tâche planifiee pour les peripheriques USB..."
    $action    = New-ScheduledTaskAction -Execute 'PowerShell.exe' -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$ScriptTarget`""
    $trigger   = New-ScheduledTaskTrigger -AtStartup
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

    Register-ScheduledTask -TaskName "Disable-USB-PowerSave" -Action $action -Trigger $trigger -Principal $principal -Force | Out-Null
    Write-Log "Tâche planifiee enregistree (demarrage sous compte SYSTEM)."
}

Write-Log "=== Configuration terminee avec succes ==="
exit 0