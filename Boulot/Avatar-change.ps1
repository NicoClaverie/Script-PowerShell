#Requires -RunAsAdministrator

<#
.SYNOPSIS
Change l'image du compte d'un utilisateur local Windows.
.DESCRIPTION
Ce script modifie les entrées de registre nécessaires pour changer l'avatar
d'un compte utilisateur local spécifié. Nécessite des droits administrateur.
.PARAMETER UserName
Le nom d'utilisateur du compte local dont l'avatar doit être changé.
Par défaut, tente de changer l'avatar de l'utilisateur courant si lancé depuis sa session
(mais nécessite quand même l'élévation de privilèges).
.PARAMETER ImagePath
Le chemin complet vers le fichier image (.jpg, .png, .bmp) à utiliser comme nouvel avatar.
.EXAMPLE
.\Set-UserTile.ps1 -UserName "MonUser" -ImagePath "C:\Images\avatar.png"
.EXAMPLE
# Change l'avatar de l'utilisateur actuel (nécessite élévation admin)
.\Set-UserTile.ps1 -ImagePath "C:\Users\Public\Pictures\nouvel_avatar.jpg"
.NOTES
ATTENTION : Ce script modifie le Registre. À utiliser avec précaution.
La modification peut ne pas être visible immédiatement et nécessiter une déconnexion/reconnexion.
Fonctionne principalement pour les comptes locaux. Pour les comptes de domaine,
la gestion peut être différente (via AD par exemple).
#>
param(
    [Parameter(Mandatory=$false)]
    [string]$UserName = $env:USERNAME, # Prend l'utilisateur actuel par défaut

    [Parameter(Mandatory=$true)]
    [ValidateScript({ Test-Path $_ -PathType Leaf })] # Vérifie que le fichier image existe
    [string]$ImagePath
)

Write-Host "Tentative de changement d'avatar pour l'utilisateur '$UserName' avec l'image '$ImagePath'."

try {
    # 1. Trouver le SID de l'utilisateur
    $UserAccount = New-Object System.Security.Principal.NTAccount($UserName)
    $UserSid = $UserAccount.Translate([System.Security.Principal.SecurityIdentifier]).Value
    Write-Host "SID trouvé pour '$UserName': $UserSid"

    # 2. Définir le chemin de base dans le Registre
    $RegPathBase = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AccountPicture\Users"
    $UserRegPath = Join-Path -Path $RegPathBase -ChildPath $UserSid

    # 3. S'assurer que la clé de registre pour l'utilisateur existe
    if (-not (Test-Path $UserRegPath)) {
        Write-Host "Création de la clé de Registre : $UserRegPath"
        New-Item -Path $UserRegPath -Force | Out-Null
    } else {
        Write-Host "Clé de Registre existante trouvée : $UserRegPath"
    }

    # 4. Définir les valeurs de registre pour différentes tailles d'image
    # Windows utilise ces tailles, mais elles peuvent toutes pointer vers le même fichier source.
    # Windows se chargera de redimensionner l'image source au besoin.
    $ImageSizes = @("Image40", "Image48", "Image96", "Image192", "Image200", "Image240", "Image448") # Liste commune de tailles

    foreach ($SizeName in $ImageSizes) {
        $RegValuePath = Join-Path -Path $UserRegPath -ChildPath $SizeName
        Write-Host "Définition de la valeur '$SizeName' sur '$ImagePath' dans '$UserRegPath'"
        # Utilise Set-ItemProperty avec -Force pour créer ou écraser la valeur
        Set-ItemProperty -Path $UserRegPath -Name $SizeName -Value $ImagePath -Type String -Force
    }

    Write-Host "Modification des clés de Registre terminée pour l'utilisateur '$UserName'."
    Write-Host "Il peut être nécessaire de se déconnecter et se reconnecter pour voir le changement."

} catch {
    Write-Error "Une erreur est survenue : $($_.Exception.Message)"
    Write-Error "Le script n'a peut-être pas pu changer l'avatar."
}