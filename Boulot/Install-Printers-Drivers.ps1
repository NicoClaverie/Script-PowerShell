<#
.SYNOPSIS
    Script d'installation de pilotes pour MDT avec mecanisme de relance (Retry).
    Version : 1.3
    Auteur : GEMINI 3
    Modification : CLAVERIE Nicolas
#>

$driversConfig = @(
    # Pilotes pour imprimantes CANON
    @{ Path = "C:\Imprimantes\CANON\GPlus_PCL6_Driver_V230_W64_00\Driver"; Name = "Canon Generic Plus PCL6" },
    @{ Path = "C:\Imprimantes\CANON\GPlus_PCL6_Driver_V260_32_64_00\x64\Driver"; Name = "Canon Generic Plus PCL6" },
    @{ Path = "C:\Imprimantes\CANON\GPlus_PCL6_Driver_V290_32_64_00\x64\Driver"; Name = "Canon Generic Plus PCL6" },
    # Pilotes pour imprimantes LEXMARK
    @{ Path = "C:\Imprimantes\LEXMARK\Lexmark_Universal_v2_XL_3_0_2\Drivers\Print\GDI"; Name = "Lexmark Universal v2 XL" },
    # Pilotes pour imprimantes XEROX
    @{ Path = "C:\Imprimantes\XEROX\UNIV_5.1035.2.0_PCL6_x64_Driver.inf"; Name = "Xerox Global Print Driver PCL6" },
    @{ Path = "C:\Imprimantes\XEROX\UNIV_5.496.7.0_PCL6_x64_Driver.inf"; Name = "Xerox Global Print Driver PCL6" },
    @{ Path = "C:\Imprimantes\XEROX\UNIV_5.548.8.0_PCL_x64"; Name = "Xerox Global Print Driver PCL" },
    @{ Path = "C:\Imprimantes\XEROX\UNIV_5.548.8.0_PCL6_x64"; Name = "Xerox Global Print Driver PCL6" },
    @{ Path = "C:\Imprimantes\XEROX\UNIV_5.548.8.0_PS_x64"; Name = "Xerox Global Print Driver PS" },
    @{ Path = "C:\Imprimantes\XEROX\UNIV_5.645.5.0_PCL6_x64"; Name = "Xerox Global Print Driver PCL6" },    
    # Pilotes pour imprimantes HP
    @{ Path = "C:\Imprimantes\HP\pcl6-x64-6.9.0.24630"; Name = "HP Universal Printing PCL 6" },
    @{ Path = "C:\Imprimantes\HP\pcl6-x64-6.6.0.23029"; Name = "HP Universal Printing PCL 6" },
    @{ Path = "C:\Imprimantes\HP\pcl6-x64-7.0.1.24923"; Name = "HP Universal Printing PCL 6" },
    @{ Path = "C:\Imprimantes\HP\pcl6-x64-6.0.0.18849"; Name = "HP Universal Printing PCL 6" },
    @{ Path = "C:\Imprimantes\HP\pcl6-x64-7.9.0.26347"; Name = "HP Universal Printing PCL 6" }
)

Write-Host "--- DEBUT DE L'INSTALLATION (AVEC RETRY) ---" -ForegroundColor Cyan

foreach ($driver in $driversConfig) {
    $path = $driver.Path
    $name = $driver.Name
    $success = $false
    $maxRetries = 2 # Nombre de tentatives supplementaires apres l'echec initial

    if (Test-Path $path) {
        Write-Host "`nTraitement de : $name" -ForegroundColor White
        
        # 1. Injection INF (une seule fois suffit generalement pour le Driver Store)
        Get-ChildItem -Path $path -Filter "*.inf" -Recurse | ForEach-Object {
            & pnputil.exe /add-driver $_.FullName /install | Out-Null
        }

        # 2. Boucle de tentative pour l'enregistrement du pilote (Add-PrinterDriver)
        for ($attempt = 0; $attempt -le $maxRetries; $attempt++) {
            try {
                if ($attempt -gt 0) { 
                    Write-Host "   -> Tentative de relance $attempt/$maxRetries..." -ForegroundColor Yellow
                    Start-Sleep -Seconds 5 # Pause pour laisser le spooler respirer
                }

                Add-PrinterDriver -Name $name -ErrorAction Stop
                Write-Host "   [OK] Pilote '$name' installe avec succes." -ForegroundColor Green
                $success = $true
                break # Sort de la boucle 'for' car c'est un succes
            }
            catch {
                Write-Host "   [ECHEC] Tentative $($attempt + 1) echouee pour '$name'." -ForegroundColor Red
            }
        }

        if (-not $success) {
            Write-Error "CRITIQUE : Impossible d'installer le pilote '$name' apres plusieurs tentatives."
        }
    }
    else {
        Write-Host "   [SAUTE] Chemin introuvable : $path" -ForegroundColor Yellow
    }
}

Write-Host "`n--- FIN DU SCRIPT ---" -ForegroundColor Cyan
