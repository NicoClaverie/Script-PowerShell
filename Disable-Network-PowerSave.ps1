# Script de desactivation de l'economie d'energie reseau
# Integration ManageEngine OS Deployer (Post-Deployment Activity)

$LogFile = "C:\windows\temp\Disable-Network-PowerSave.log"

Function Write-Log {
    Param ([string]$LogString)
    $Stamp = (Get-Date).toString("yyyy-MM-dd HH:mm:ss")
    $LogMessage = "$Stamp $LogString"
    Add-content $LogFile -value $LogMessage
    Write-Host $LogString
}

Write-Log "=== Debut de la configuration de l'alimentation reseau ==="

# 1. Traitement des interfaces reseau physiques presentes (Ethernet, Wi-Fi, dongles USB)
try {
    $adapters = Get-NetAdapter -Physical -ErrorAction SilentlyContinue
    Write-Log "$($adapters.Count) carte(s) reseau physique(s) detectee(s)."

    $modifiedCount = 0

    foreach ($nic in $adapters) {
        Write-Log "Verification : $($nic.Name) [$($nic.InterfaceDescription)]"
        
        $power =$nic | Get-NetAdapterPowerManagement -ErrorAction SilentlyContinue
        if ($power -and$power.AllowComputerToTurnOffDevice -ne "Unsupported") {
            if ($power.AllowComputerToTurnOffDevice -eq "Enabled") {
                $power.AllowComputerToTurnOffDevice = "Disabled"
                $power | Set-NetAdapterPowerManagement -NoRestart -ErrorAction SilentlyContinue
                Write-Log "-> economie d'energie desactivee pour : $($nic.Name)"
                $modifiedCount++
            } else {
                Write-Log "-> Deja desactivee pour : $($nic.Name)"
            }
        } else {
            Write-Log "-> Gestion d'energie non prise en charge par le pilote pour : $($nic.Name)"
        }
    }

    Write-Log "$modifiedCount carte(s) modifiee(s)."
}
catch {
    Write-Log "Erreur lors du traitement NetAdapter : $($_.Exception.Message)"
}

# 2. Persistance pour les adaptateurs reseau USB branches ulterieurement
$ScriptInstallDir = "C:\ProgramData\OSDeployer\Scripts"
$ScriptTarget     = "$ScriptInstallDir\Disable-Network-PowerSave.ps1"

if (-not (Test-Path -Path $ScriptInstallDir)) {
    New-Item -ItemType Directory -Path $ScriptInstallDir -Force | Out-Null
}

# Copie locale du script si execute depuis l'agent ou un repertoire temporaire
if ($PSCommandPath -and ($PSCommandPath -ne$ScriptTarget)) {
    Copy-Item -Path $PSCommandPath -Destination $ScriptTarget -Force
}

$taskExists = Get-ScheduledTask -TaskName "Disable-Network-PowerSave" -ErrorAction SilentlyContinue
if (-not $taskExists) {
    Write-Log "Creation de la tâche planifiee pour les futurs adaptateurs USB..."
    $action    = New-ScheduledTaskAction -Execute 'PowerShell.exe' -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$ScriptTarget`""
    $trigger   = New-ScheduledTaskTrigger -AtStartup 
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    
    Register-ScheduledTask -TaskName "Disable-Network-PowerSave" -Action $action -Trigger $trigger -Principal $principal -Force | Out-Null
    Write-Log "Tâche planifiee enregistree (demarrage sous compte SYSTEM)."
}

Write-Log "=== Configuration terminee avec succes ==="
exit 0