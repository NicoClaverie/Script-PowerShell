# Script PowerShell pour desactiver la gestion de l'alimentation des peripheriques USB en utilisant WMI/CIM.
# Inclut une journalisation detaillee pour le suivi dans MDT.

# --- Configuration du journal ---
$LogFile = "C:\Temp\Disable-USBPowerSave-WMI.log"

Function Write-Log {
    Param ([string]$LogString)
    $Stamp = (Get-Date).toString("yyyy-MM-dd HH:mm:ss")
    $LogMessage = "$Stamp $LogString"
    Add-content $LogFile -value $LogMessage
    Write-Host $LogString # Affiche aussi dans les logs MDT en temps reel
}

# --- Debut du Script ---
Write-Log "Debut du script de desactivation de la gestion de l'alimentation USB (methode WMI/CIM)."

try {
    # 1. Recuperer toutes les instances de gestion d'alimentation
    Write-Log "Recuperation des instances de gestion d'alimentation (MSPower_DeviceEnable)..."
    $powerManagementInstances = Get-CimInstance -ClassName MSPower_DeviceEnable -Namespace root/WMI -ErrorAction Stop
    Write-Log "$($powerManagementInstances.Count) instances trouvees."

    # 2. Recuperer tous les peripheriques PnP de la classe USB
    Write-Log "Recuperation des peripheriques PnP de la classe 'USB'..."
    $usbDevices = Get-CimInstance -ClassName Win32_PnPEntity -Filter "PNPClass = 'USB'" -ErrorAction Stop
    Write-Log "$($usbDevices.Count) peripheriques USB trouves."

    # 3. Filtrer pour trouver les instances de gestion d'alimentation qui correspondent aux peripheriques USB
    Write-Log "Filtrage pour trouver les correspondances..."
    $devicesToAdjust = $usbDevices | ForEach-Object {
        $pnpDevice = $_
        # Cherche l'instance de gestion d'alimentation qui contient l'ID du peripherique USB
        $matchingPowerInstance = $powerManagementInstances | Where-Object { $_.InstanceName -like "*$($pnpDevice.PNPDeviceID)*" }
        if ($matchingPowerInstance) {
            Write-Log "-> Correspondance trouvee pour : $($pnpDevice.Caption) ($($pnpDevice.PNPDeviceID))"
            # Retourne l'objet de gestion d'alimentation pour qu'il soit ajoute a la liste $devicesToAdjust
            return $matchingPowerInstance
        }
    }

    if ($devicesToAdjust.Count -gt 0) {
        Write-Log "$($devicesToAdjust.Count) peripherique(s) a modifier."
        
        # 4. Appliquer le parametre pour desactiver la gestion de l'alimentation
        Write-Log "Application du parametre 'Enable = false'..."
        $devicesToAdjust | Set-CimInstance -Property @{ Enable = $false } -ErrorAction Stop
        Write-Log "La gestion de l'alimentation a ete desactivee avec succes pour les peripheriques correspondants."
    } else {
        Write-Log "Aucun peripherique USB correspondant avec une gestion d'alimentation active n'a ete trouve."
    }
}
catch {
    Write-Log "ERREUR: Une erreur critique est survenue. Erreur: $($_.Exception.Message)"
}

Write-Log "Script termine."
exit 0
