# --- ATTENTION : Ceci est un exemple conceptuel simplifié ---
# --- À utiliser avec prudence et après adaptation ---

# Charger l'assembly System.Drawing (peut ne pas être nécessaire sur certaines versions)
Add-Type -AssemblyName System.Drawing

# Chemin de l'image source et dossier de destination
$SourceImagePath = "C:\Logos\TDS User Windows.jpg"
$DestinationFolder = "$Env:USERPROFILE\AppData\Roaming\Microsoft\Windows\AccountPictures"
$BaseName = [System.IO.Path]::GetFileNameWithoutExtension($SourceImagePath)

# Tailles requises (exemple)
$RequiredSizes = @(448, 240, 96, 48, 40, 32)

# Charger l'image source
$SourceImage = [System.Drawing.Image]::FromFile($SourceImagePath)

# Boucler sur chaque taille requise
foreach ($Size in $RequiredSizes) {
    $DestinationPath = Join-Path -Path $DestinationFolder -ChildPath "$($BaseName)_$($Size).png"

    # Créer une nouvelle image (bitmap) à la taille cible
    $TargetBitmap = New-Object System.Drawing.Bitmap($Size, $Size)
    $TargetGraphics = [System.Drawing.Graphics]::FromImage($TargetBitmap)

    # Configurer la qualité du redimensionnement (optionnel mais recommandé)
    $TargetGraphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $TargetGraphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $TargetGraphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $TargetGraphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality

    # Dessiner l'image source redimensionnée sur la nouvelle image
    # Rectangle de destination (0, 0, $Size, $Size)
    # Rectangle source (0, 0, $SourceImage.Width, $SourceImage.Height)
    $TargetGraphics.DrawImage($SourceImage, (New-Object System.Drawing.Rectangle(0, 0, $Size, $Size)), (New-Object System.Drawing.Rectangle(0, 0, $SourceImage.Width, $SourceImage.Height)), [System.Drawing.GraphicsUnit]::Pixel)

    # Sauvegarder la nouvelle image (format PNG ici)
    $TargetBitmap.Save($DestinationPath, [System.Drawing.Imaging.ImageFormat]::Png)

    # Libérer les ressources
    $TargetGraphics.Dispose()
    $TargetBitmap.Dispose()
}

# Libérer l'image source
$SourceImage.Dispose()

Write-Host "Images redimensionnées créées dans $DestinationFolder"

#######################################################################

# 1. Obtenir le SID (exemple pour un compte local)
$UserSID = ([System.Security.Principal.WindowsIdentity]::GetCurrent()).User.Value

# 2. Définir les chemins où vous avez sauvegardé les images redimensionnées
# (Suppose que les images sont dans C:\AvatarsPréparés\ et nommées avec le SID)
$ImagePathBase = "C:\AvatarsPréparés\$($UserSID)" # Exemple de chemin
$Image448Path = "$($ImagePathBase)_448.png" # Chemin vers l'image 448x448
$Image240Path = "$($ImagePathBase)_240.png" # Chemin vers l'image 240x240
# ... etc. pour toutes les tailles requises

# 3. Chemin de la clé de Registre
$RegPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AccountPicture\Users\$UserSID"

# Vérifier si la clé existe, sinon la créer (peut nécessiter plus de logique)
if (-not (Test-Path $RegPath)) {
    New-Item -Path $RegPath -Force | Out-Null
}

# 4. Écrire les chemins dans le Registre (EXIGE PowerShell lancé en tant qu'Administrateur)
try {
    Set-ItemProperty -Path $RegPath -Name "Image448" -Value $Image448Path -Type String -Force -ErrorAction Stop
    Set-ItemProperty -Path $RegPath -Name "Image240" -Value $Image240Path -Type String -Force -ErrorAction Stop
    # ... Répéter Set-ItemProperty pour TOUTES les autres tailles (Image96, Image48, etc.)

    Write-Host "Les propriétés du Registre pour l'avatar de $UserName (SID: $UserSID) ont été mises à jour."
    Write-Host "Un redémarrage ou une déconnexion/reconnexion de l'utilisateur peut être nécessaire pour voir le changement."
} catch {
    Write-Error "Erreur lors de la mise à jour du Registre : $($_.Exception.Message)"
}

# --- Fin de l'exemple conceptuel ---