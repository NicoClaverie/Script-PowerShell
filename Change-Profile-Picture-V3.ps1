# Répertoire contenant les images
$AvatarFolder = "C:\Users\Public\Avatars"
$Avatar_Toto = Join-Path $AvatarFolder "toto.jpg"
$Avatar_Default = Join-Path $AvatarFolder "user.jpg"

# Résolutions requises
$Resolutions = @(32, 40, 48, 64, 96, 108, 192, 208, 240, 424, 448, 1080)

# Charger System.Drawing
Add-Type -AssemblyName System.Drawing

# Récupérer TOUS les SIDs ayant un profil local (local + domaine)
$ProfileListKey = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList"
$Users = Get-ChildItem $ProfileListKey | Where-Object {
    $_.PSChildName -match "^S-1-5-21" -and `
    (Get-ItemProperty $_.PsPath).ProfileImagePath -match "C:\\Users\\"
}

foreach ($User in $Users) {

    $UserSID = $User.PSChildName
    $ProfilePath = (Get-ItemProperty $User.PSPath).ProfileImagePath
    $UserName = Split-Path $ProfilePath -Leaf

    Write-Host "Traitement de : $UserName ($UserSID)"

    # Déterminer l’image correcte
    if ($UserName -ieq "TOTO") {
        $NewImagePath = $Avatar_Toto
    }
    else {
        $NewImagePath = $Avatar_Default
    }

    # Dossier de destination
    $AccountPicturesFolder = "C:\Users\Public\AccountPictures\$UserSID"
    if (!(Test-Path $AccountPicturesFolder)) {
        New-Item -ItemType Directory -Path $AccountPicturesFolder -Force | Out-Null
    }

    # Chemin du hash
    $HashFile = Join-Path $AccountPicturesFolder "source.hash"
    $CurrentHash = (Get-FileHash $NewImagePath -Algorithm SHA256).Hash
    $OldHash = if (Test-Path $HashFile) { Get-Content $HashFile } else { "" }

    # Si hash différent → régénération obligatoire
    $ForceUpdate = $CurrentHash -ne $OldHash


    # Vérifier si une série d'images existe déjà
    $Existing = Get-ChildItem $AccountPicturesFolder -Filter "*-Image32.jpg" -ErrorAction SilentlyContinue

    if (-not $ForceUpdate -and $Existing) {
        # On garde le même GUID
        $ImageGUID = ($Existing.Name -replace "-Image32.jpg", "")
        Write-Host " → Avatar déjà présent, GUID : $ImageGUID (inchangé)"
    }
    else {
        # Nouvelle image détectée → on régénère
        Write-Host " → Nouvelle image détectée, génération d'un nouvel avatar..."
    
        # Supprimer les anciennes miniatures
        Remove-Item "$AccountPicturesFolder\*.jpg" -Force -ErrorAction SilentlyContinue

        $ImageGUID = [guid]::NewGuid().ToString()

    foreach ($res in $Resolutions) {
        $DestPath = Join-Path $AccountPicturesFolder "$ImageGUID-Image$res.jpg"
        $img = [System.Drawing.Image]::FromFile($NewImagePath)
        $thumb = $img.GetThumbnailImage($res, $res, $null, [IntPtr]::Zero)
        $thumb.Save($DestPath, [System.Drawing.Imaging.ImageFormat]::Jpeg)
        $thumb.Dispose()
        $img.Dispose()
    }

    # Écrire le hash
    $CurrentHash | Out-File $HashFile -Encoding ascii -Force
}


    # Mise à jour du registre Windows
    $RegPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AccountPicture\Users\$UserSID"
    if (!(Test-Path $RegPath)) { New-Item -Path $RegPath -Force | Out-Null }

    foreach ($res in $Resolutions) {
        $ValueName = "Image$res"
        $ValuePath = Join-Path $AccountPicturesFolder "$ImageGUID-Image$res.jpg"
        Set-ItemProperty -Path $RegPath -Name $ValueName -Value $ValuePath
    }

    Write-Host "Avatar OK pour $UserName ($UserSID)"
}
