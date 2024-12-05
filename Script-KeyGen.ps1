#################################################
#                                               #
#       Script générateur de mot de passe       #
#                                               #
#        Propriété : Dominique Collevile        #
#                                               #
#################################################



Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Function Generate-Password
{
    param(
        [int]$Length = 17,
        [bool]$Lowercase = $true,
        [bool]$Uppercase = $true,
        [bool]$Numbers = $true,
        [bool]$SpecialChars = $true
    )
    $Chars = @()
    If ($Lowercase) { $Chars += 97..122 }
    If ($Uppercase) { $Chars += 65..90 }
    If ($Numbers) { $Chars += 48..57 }
    If ($SpecialChars) { $Chars += 33..47 + 58..64 + 91..96 + 123..126 }
    $Password = ""
    For ($i = 0; $i -lt $Length; $i++)
    {
        $Password += [Char]$Chars[(Get-Random -Minimum 0 -Maximum $Chars.Count)]
    }
    Return $Password
}
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "Password Generator"
$Form.Size = New-Object System.Drawing.Size(435,435)
$Form.StartPosition = "CenterScreen"
$Form.FormBorderStyle = "FixedDialog"
$Form.MaximizeBox = $false
$LabelLength = New-Object System.Windows.Forms.Label
$LabelLength.Location = New-Object System.Drawing.Point(10,20)
$LabelLength.Size = New-Object System.Drawing.Size(150,20)
$LabelLength.Text = "Password Length:"
$Form.Controls.Add($LabelLength)
$NumLength = New-Object System.Windows.Forms.NumericUpDown
$NumLength.Location = New-Object System.Drawing.Point(160,20)
$NumLength.Size = New-Object System.Drawing.Size(50,20)
$NumLength.Value = 17
$Form.Controls.Add($NumLength)
$LabelLower = New-Object System.Windows.Forms.Label
$LabelLower.Location = New-Object System.Drawing.Point(10,50)
$LabelLower.Size = New-Object System.Drawing.Size(150,20)
$LabelLower.Text = "Lowercase Letters"
$Form.Controls.Add($LabelLower)
$LabelUpper = New-Object System.Windows.Forms.Label
$LabelUpper.Location = New-Object System.Drawing.Point(10,80)
$LabelUpper.Size = New-Object System.Drawing.Size(150,20)
$LabelUpper.Text = "Uppercase Letters"
$Form.Controls.Add($LabelUpper)
$LabelNumbers = New-Object System.Windows.Forms.Label
$LabelNumbers.Location = New-Object System.Drawing.Point(10,110)
$LabelNumbers.Size = New-Object System.Drawing.Size(150,20)
$LabelNumbers.Text = "Numbers"
$Form.Controls.Add($LabelNumbers)
$LabelSpecial = New-Object System.Windows.Forms.Label
$LabelSpecial.Location = New-Object System.Drawing.Point(10,140)
$LabelSpecial.Size = New-Object System.Drawing.Size(150,20)
$LabelSpecial.Text = "Special Characters"
$Form.Controls.Add($LabelSpecial)
$CheckboxLower = New-Object System.Windows.Forms.CheckBox
$CheckboxLower.Location = New-Object System.Drawing.Point(160,50)
$CheckboxLower.Size = New-Object System.Drawing.Size(150,20)
$CheckboxLower.Checked = $true
$Form.Controls.Add($CheckboxLower)
$CheckboxUpper = New-Object System.Windows.Forms.CheckBox
$CheckboxUpper.Location = New-Object System.Drawing.Point(160,80)
$CheckboxUpper.Size = New-Object System.Drawing.Size(150,20)
$CheckboxUpper.Checked = $true
$Form.Controls.Add($CheckboxUpper)
$CheckboxNumbers = New-Object System.Windows.Forms.CheckBox
$CheckboxNumbers.Location = New-Object System.Drawing.Point(160,110)
$CheckboxNumbers.Size = New-Object System.Drawing.Size(150,20)
$CheckboxNumbers.Checked = $true
$Form.Controls.Add($CheckboxNumbers)
$CheckboxSpecial = New-Object System.Windows.Forms.CheckBox
$CheckboxSpecial.Location = New-Object System.Drawing.Point(160,140)
$CheckboxSpecial.Size = New-Object System.Drawing.Size(150,20)
$CheckboxSpecial.Checked = $true
$Form.Controls.Add($CheckboxSpecial)
$LabelCount = New-Object System.Windows.Forms.Label
$LabelCount.Location = New-Object System.Drawing.Point(10,170)
$LabelCount.Size = New-Object System.Drawing.Size(150,20)
$LabelCount.Text = "Number of Passwords:"
$Form.Controls.Add($LabelCount)
$NumCount = New-Object System.Windows.Forms.NumericUpDown
$NumCount.Location = New-Object System.Drawing.Point(160,170)
$NumCount.Size = New-Object System.Drawing.Size(50,20)
$NumCount.Minimum = 1
$NumCount.Value = 1
$Form.Controls.Add($NumCount)
$ListBoxPasswords = New-Object System.Windows.Forms.ListBox
$ListBoxPasswords.Location = New-Object System.Drawing.Point(10,200)
$ListBoxPasswords.Size = New-Object System.Drawing.Size(300,150)
$ListBoxPasswords.SelectionMode = "One"
$Form.Controls.Add($ListBoxPasswords)
$ButtonGenerate = New-Object System.Windows.Forms.Button
$ButtonGenerate.Location = New-Object System.Drawing.Point(10,360)
$ButtonGenerate.Size = New-Object System.Drawing.Size(150,30)
$ButtonGenerate.Text = "Generate Passwords"
$ButtonGenerate.Add_Click(
    {
        $listBoxPasswords.Items.Clear()
        for ($i = 0; $i -lt $NumCount.Value; $i++)
        {
            $Password = Generate-Password -Length $NumLength.Value `
                                             -Lowercase $CheckboxLower.Checked `
                                             -Uppercase $CheckboxUpper.Checked `
                                             -Numbers $CheckboxNumbers.Checked `
                                             -SpecialChars $CheckboxSpecial.Checked
            $ListBoxPasswords.Items.Add($Password)
        }
    }
)
$Form.Controls.Add($ButtonGenerate)
$ButtonCopy = New-Object System.Windows.Forms.Button
$ButtonCopy.Location = New-Object System.Drawing.Point(320,200)
$ButtonCopy.Size = New-Object System.Drawing.Size(100,30)
$ButtonCopy.Text = "Copy"
$ButtonCopy.Add_Click(
    {
        If ($ListBoxPasswords.SelectedItem -ne $null) {
            [System.Windows.Forms.Clipboard]::SetText($ListBoxPasswords.SelectedItem)
            [System.Windows.Forms.MessageBox]::Show("Mot de passe copié dans le presse-papier", "Copie du mot de passe", "OK", "Information")
        }
        Else
        {
            [System.Windows.Forms.MessageBox]::Show("Sélectionner un mot de passe à copier", "Copie du mot de passe", "OK", "Warning")
        }
    }
)
$Form.Controls.Add($ButtonCopy)
$Form.ShowDialog() | Out-Null
