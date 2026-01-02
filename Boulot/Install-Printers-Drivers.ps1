<#
.SYNOPSIS
    Script d'installation de pilotes pour MDT avec mécanisme de relance (Retry).
    Version : 1.3
    Auteur : GEMINI 3
#>

$driversConfig = @(
    @{ Path = "C:\Imprimantes\CANON\GPlus_PCL6_Driver_V230_W64_00\Driver"; Name = "Canon Generic Plus PCL6" },
    @{ Path = "C:\Imprimantes\HP\pcl6-x64-6.9.0.24630"; Name = "HP Universal Printing PCL 6" },
    @{ Path = "C:\Imprimantes\LEXMARK\Lexmark_Universal_v2_XL_3_0_2\Drivers\Print\GDI"; Name = "Lexmark Universal v2 XL" },
    @{ Path = "C:\Imprimantes\XEROX\UNIV_5.1035.2.0_PCL6_x64_Driver.inf"; Name = "Xerox Global Print Driver PCL6" }
)

Write-Host "--- DÉBUT DE L'INSTALLATION (AVEC RETRY) ---" -ForegroundColor Cyan

foreach ($driver in $driversConfig) {
    $path = $driver.Path
    $name = $driver.Name
    $success = $false
    $maxRetries = 2 # Nombre de tentatives supplémentaires après l'échec initial

    if (Test-Path $path) {
        Write-Host "`nTraitement de : $name" -ForegroundColor White
        
        # 1. Injection INF (une seule fois suffit généralement pour le Driver Store)
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
                Write-Host "   [OK] Pilote '$name' installé avec succès." -ForegroundColor Green
                $success = $true
                break # Sort de la boucle 'for' car c'est un succès
            }
            catch {
                Write-Host "   [ECHEC] Tentative $($attempt + 1) échouée pour '$name'." -ForegroundColor Red
            }
        }

        if (-not $success) {
            Write-Error "CRITIQUE : Impossible d'installer le pilote '$name' après plusieurs tentatives."
        }
    }
    else {
        Write-Host "   [SAUTÉ] Chemin introuvable : $path" -ForegroundColor Yellow
    }
}

Write-Host "`n--- FIN DU SCRIPT ---" -ForegroundColor Cyan
