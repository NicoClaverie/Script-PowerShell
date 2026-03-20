<#
.SYNOPSIS
    Script d'installation de pilotes (Écrans, Docks, Chipsets) pour MDT via PnPUtil.
    Version : 1.4
    Auteur : Gemini 3
#>

# Vérifie si la session actuelle a les droits d'administrateur
$currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    # Si non, on relance le script actuel en demandant l'élévation
    $arguments = "& '" + $myinvocation.mycommand.definition + "'"
    Start-Process powershell.exe -Verb RunAs -ArgumentList $arguments
    # On quitte la session non-administrateur
    exit
}


$genericDriversConfig = @(
    @{ Path = "C:\pilotes\dock"; Name = "Dock Lenvo" },
    @{ Path = "C:\pilotes\ThinkVision T24i-30"; Name = "Ecran Lenovo ThinkVision T24i-30" },
    @{ Path = "C:\pilotes\ThinkVision T24-40"; Name = "Ecran Lenovo ThinkVision T24i-40" },
    @{ Path = "C:\pilotes\ThinkVision T24mv-30-63D7\t24mv_30_driver"; Name = "Ecran Lenovo ThinkVision T24mv-30" }
)

Write-Host "--- DÉBUT DE L'INSTALLATION MATÉRIELLE (PnP) ---" -ForegroundColor Cyan

foreach ($item in $genericDriversConfig) {
    $path = $item.Path
    $name = $item.Name
    $maxRetries = 2
    $success = $false

    if (Test-Path $path) {
        Write-Host "`nTraitement de : $name" -ForegroundColor White
        
        # Pour le matériel PnP, on boucle sur l'injection elle-même (pnputil)
        for ($attempt = 0; $attempt -le $maxRetries; $attempt++) {
            try {
                if ($attempt -gt 0) { 
                    Write-Host "   -> Nouvelle tentative $attempt/$maxRetries..." -ForegroundColor Yellow
                    Start-Sleep -Seconds 3
                }

                # Récupération de tous les fichiers .inf dans le dossier
                $infFiles = Get-ChildItem -Path $path -Filter "*.inf" -Recurse

                if ($null -eq $infFiles) {
                    throw "Aucun fichier .inf trouvé dans le dossier."
                }

                foreach ($inf in $infFiles) {
                    # /add-driver : Ajoute au magasin
                    # /install    : Tente de l'installer sur les périphériques connectés
                    $process = Start-Process -FilePath "pnputil.exe" -ArgumentList "/add-driver `"$($inf.FullName)`" /install" -Wait -PassThru -NoNewWindow
                    
                    if ($process.ExitCode -ne 0 -and $process.ExitCode -ne 3010) {
                        # 3010 signifie "Succès, mais redémarrage requis"
                        throw "Erreur PnPUtil (Code: $($process.ExitCode))"
                    }
                }

                Write-Host "   [OK] Pilote '$name' injecté avec succès." -ForegroundColor Green
                $success = $true
                break
            }
            catch {
                Write-Host "   [ECHEC] Tentative $($attempt + 1) pour '$name' : $($_.Exception.Message)" -ForegroundColor Red
            }
        }

        if (-not $success) {
            Write-Warning "AVERTISSEMENT : Le pilote '$name' n'a pas pu être totalement injecté."
        }
    }
    else {
        Write-Host "   [SAUTÉ] Chemin introuvable : $path" -ForegroundColor Yellow
    }
}

Write-Host "`n--- FIN DU SCRIPT ---" -ForegroundColor Cyan