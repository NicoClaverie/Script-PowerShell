# Répertoire contenant les images
$AvatarFolder = "C:\Users\Public\Avatars"   # mettre ici les images toto.jpg et user.jpg
$Avatar_Toto = Join-Path $AvatarFolder "toto.jpg"
$Avatar_Default = Join-Path $AvatarFolder "user.jpg"

# Liste des utilisateurs locaux actifs
$Users = Get-LocalUser | Where-Object { $_.Enabled -eq $true }

# Liste des résolutions à générer
$Resolutions = @(32, 40, 48, 64, 96, 108, 192, 208, 240, 424, 448, 1080)

# Charger l'assembly System.Drawing
Add-Type -AssemblyName System.Drawing

foreach ($User in $Users) {

    $UserSID = $User.SID
    $UserName = $User.Name
    Write-Host "Traitement de l'utilisateur : $UserName ($UserSID)"

    # Déterminer l'image à utiliser
    if ($UserName -eq "TOTO") {
        $NewImagePath = $Avatar_Toto
    } else {
        $NewImagePath = $Avatar_Default
    }

    # Dossier pour les images de l'utilisateur
    $AccountPicturesFolder = "C:\Users\Public\AccountPictures\$UserSID"
    if (!(Test-Path $AccountPicturesFolder)) {
        New-Item -ItemType Directory -Path $AccountPicturesFolder -Force | Out-Null
    }

    # Copier et redimensionner l'image pour chaque résolution
    $ImageGUID = [guid]::NewGuid().ToString()
    foreach ($res in $Resolutions) {
        $DestPath = Join-Path $AccountPicturesFolder "$ImageGUID-Image$res.jpg"
        $img = [System.Drawing.Image]::FromFile($NewImagePath)
        $thumb = $img.GetThumbnailImage($res, $res, $null, [IntPtr]::Zero)
        $thumb.Save($DestPath, [System.Drawing.Imaging.ImageFormat]::Jpeg)
        $thumb.Dispose()
        $img.Dispose()
    }

    # Mise à jour du registre
    $RegPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AccountPicture\Users\$UserSID"
    if (!(Test-Path $RegPath)) {
        New-Item -Path $RegPath -Force | Out-Null
    }

    foreach ($res in $Resolutions) {
        $ValueName = "Image$res"
        $ValuePath = Join-Path $AccountPicturesFolder "$ImageGUID-Image$res.jpg"
        Set-ItemProperty -Path $RegPath -Name $ValueName -Value $ValuePath
    }

    Write-Host "Avatar mis à jour pour l'utilisateur $UserName ($UserSID)"
}
