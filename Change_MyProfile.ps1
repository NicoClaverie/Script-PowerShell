# Chemin vers la nouvelle image
$NewImagePath = "C:\Users\Nico\Pictures\singe.jpg"

# SID de l'utilisateur ciblé
# Tu peux récupérer le SID du compte avec : 
# Get-LocalUser <NomUtilisateur> | Select-Object -ExpandProperty SID
$UserSID = "S-1-5-21-3544187701-1358832183-3138404945-1000"

# Dossier où les images seront stockées
$AccountPicturesFolder = "C:\Users\Public\AccountPictures\$UserSID"

# Créer le dossier si nécessaire
if (!(Test-Path $AccountPicturesFolder)) {
    New-Item -ItemType Directory -Path $AccountPicturesFolder -Force
}

# Liste des résolutions à générer
$Resolutions = @(32, 40, 48, 64, 96, 108, 192, 208, 240, 424, 448)

# Copier et redimensionner l'image pour chaque résolution
$ImageGUID = [guid]::NewGuid().ToString()
foreach ($res in $Resolutions) {
    $DestPath = Join-Path $AccountPicturesFolder "$ImageGUID-Image$res.jpg"
    # Redimensionner l'image
    Add-Type -AssemblyName System.Drawing
    $img = [System.Drawing.Image]::FromFile($NewImagePath)
    $thumb = $img.GetThumbnailImage($res, $res, $null, [IntPtr]::Zero)
    $thumb.Save($DestPath, [System.Drawing.Imaging.ImageFormat]::Jpeg)
    $thumb.Dispose()
    $img.Dispose()
}

# Mise à jour du registre
$RegPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AccountPicture\Users\$UserSID"
if (!(Test-Path $RegPath)) {
    New-Item -Path $RegPath -Force
}

foreach ($res in $Resolutions) {
    $ValueName = "Image$res"
    $ValuePath = Join-Path $AccountPicturesFolder "$ImageGUID-Image$res.jpg"
    Set-ItemProperty -Path $RegPath -Name $ValueName -Value $ValuePath
}

Write-Host "Avatar mis à jour pour l'utilisateur $UserSID"
