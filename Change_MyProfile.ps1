# https://github.com/RonildoSouza/ResizeImageModulePS

# Source : https://www.ntlite.com/community/index.php?threads/how-to-change-default-user-account-picture-to-my-custom-picture-in-install-wim.4637/

function Resize-Image {
    <#
    .SYNOPSIS
        Resize-Image resizes an image file.

    .DESCRIPTION
        This function uses the native .NET API to resize an image file and save it to a file.
        It supports the following image formats: BMP, GIF, JPEG, PNG, TIFF

    .PARAMETER InputFile
        Type [string]
        The parameter InputFile is used to define the value of image name or path to resize.

    .PARAMETER OutputFile
        Type [string]
        The parameter OutputFile is used to define the value of output image resize.

    .PARAMETER Width
        Type [int32]
        The parameter Width is used to define the value of new width to image.

    .PARAMETER Height
        Type [int32]
        The parameter Height is used to define the value of new height to image.

    .PARAMETER ProportionalResize
        Type [bool]
        The optional parameter ProportionalResize is used to define if execute proportional resize.

    .EXAMPLE
        Resize-Image -InputFile "C:/image.png" -OutputFile "C:/image2.png" -Width 300 -Height 300

    .NOTES
        Author: Ronildo Souza
        Last Edit: 2018-10-09
        Version 1.0.0 - initial release
        Version 1.0.1 - add proportional resize
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$InputFile,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$OutputFile,
        [Parameter(Mandatory = $true)]
        [int32]$Width,
        [Parameter(Mandatory = $true)]
        [int32]$Height,
        [Parameter(Mandatory = $false)]
        [bool]$ProportionalResize = $true)

    # Add assemblies
    Add-Type -AssemblyName System
    Add-Type -AssemblyName System.Drawing

    $image = [System.Drawing.Image]::FromFile((Get-Item $InputFile))

    $ratioX = $Width / $image.Width;
    $ratioY = $Height / $image.Height;
    $ratio = [System.Math]::Min($ratioX, $ratioY);

    [int32]$newWidth = If ($ProportionalResize) { $image.Width * $ratio } Else { $Width }
    [int32]$newHeight = If ($ProportionalResize) { $image.Height * $ratio } Else { $Height }

    $destImage = New-Object System.Drawing.Bitmap($newWidth, $newHeight)

    # Draw new image on the empty canvas
    $graphics = [System.Drawing.Graphics]::FromImage($destImage)
    $graphics.DrawImage($image, 0, 0, $newWidth, $newHeight)
    $graphics.Dispose()

    # Save the image
    $destImage.Save($OutputFile)
}

$PNG = "$env:SYSTEMROOT\Setup\profile.png"

$PrimaryUser = @(foreach ($User in (Get-WmiObject Win32_UserAccount)) {
    [PSCustomObject]@{
        SortKey = [int]($User.SID -split '-')[-1]
        SID = $User.SID
        Name = $User.Name
    }
}) | Where-Object { $_.SortKey -ge 1000 } | Sort-Object SortKey | select -First 1

$UserName = $PrimaryUser.Name
$SID = $PrimaryUser.SID

$UserPublic_Folder = "C:\Users\Public\AccountPictures\$UserName"
$null = New-Item -Path $UserPublic_Folder -ItemType Directory -Force

$reg_AccountPicture = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AccountPicture\Users'
$null = New-Item -Path $reg_AccountPicture -Name $SID -Force

foreach ($Size in @(32, 40, 48, 64, 96, 192, 208, 240)) {
    $File = "$UserPublic_Folder\${Size}x${Size}.png"
    Resize-Image -InputFile $PNG -OutputFile $File -Width $Size -Height $Size
    $null = New-ItemProperty -Path "$reg_AccountPicture\$SID" -Name "Image$Size" -Value $File -Force
}

$ProgramData_Folder = 'C:\ProgramData\Microsoft\User Account Pictures'
Copy-Item $PNG "$ProgramData_Folder\user.png" -Force

foreach ($Size in @(32, 40, 48, 192)) {
    Copy-Item "$UserPublic_Folder\${Size}x${Size}.png" "$ProgramData_Folder\user-${Size}.png" -Force
}
