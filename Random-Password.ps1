$sizePass = Read-host "Longueur du mot de passe :"

$outPass = -join(48..57+65..90+97..122+33..47|ForEach-Object{[char]$_}|Get-Random -C $sizePass)

[System.windows.forms.messagebox]::Show("$outPass")
