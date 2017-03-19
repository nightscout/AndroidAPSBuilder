(get-host).ui.rawui.backgroundcolor = "black"
(get-host).ui.rawui.foregroundcolor = "green"
(get-host).ui.rawui.WindowTitle = "Build AndroidAPS"
$ErrorActionPreference = "SilentlyContinue"

function Get-ScriptDirectory {
    $Invocation = (Get-Variable MyInvocation -Scope 1).Value;
    if($Invocation.PSScriptRoot)
    {
        $Invocation.PSScriptRoot;
    }
    Elseif($Invocation.MyCommand.Path)
    {
        Split-Path $Invocation.MyCommand.Path
    }
    else
    {
        $Invocation.InvocationName.Substring(0,$Invocation.InvocationName.LastIndexOf("\"));
    }
}

$scriptroot = Get-ScriptDirectory 
$script = "$scriptroot\buildAndroidAPS.ps1"
function StartScript {Invoke-Expression "$script"}
$parentFolder = (get-item $scriptroot ).parent.FullName
$aapsFolder = "$parentFolder\AndroidAPS"
$apkFolder = "$aapsFolder\app\build\outputs\apk"
$gradlewPath = "$aapsFolder\gradlew.bat"

###############Menu functions########################
function DrawMenu {
	## supportfunction to the Menu function below
	param ($menuItems, $menuPosition, $menuTitel)
	$fcolor = "Green"
	$bcolor = "Black"
	$l = $menuItems.length + 1
	cls
	$menuwidth = $menuTitel.length + 4
	Write-Host -NoNewLine
	Write-Host ("*" * $menuwidth) -fore $fcolor -back $bcolor
	Write-Host -NoNewLine
	Write-Host "* $menuTitel *" -fore $fcolor -back $bcolor
	Write-Host -NoNewLine
	Write-Host ("*" * $menuwidth) -fore $fcolor -back $bcolor
	Write-Host ""
	Write-debug "L: $l MenuItems: $menuItems MenuPosition: $menuposition"
	for ($i = 0; $i -le $l;$i++) {
		Write-Host -NoNewLine
		if ($i -eq $menuPosition) {
			Write-Host "$($menuItems[$i])" -fore $bcolor -back $fcolor
		} 
		else {
			Write-Host "$($menuItems[$i])" -fore $fcolor -back $bcolor
		}
	}
}

function Menu {
    ## Generate a small "DOS-like" menu.
    ## Choose a menuitem using up and down arrows, select by pressing ENTER
    param ([array]$menuItems, $menuTitel = "MENU")
    $vkeycode = 0
    $pos = 0
    DrawMenu $menuItems $pos $menuTitel
    While ($vkeycode -ne 13) {
        $press = $host.ui.rawui.readkey("NoEcho,IncludeKeyDown")
        $vkeycode = $press.virtualkeycode
        Write-host "$($press.character)" -NoNewLine
        If ($vkeycode -eq 38) {$pos--}
        If ($vkeycode -eq 40) {$pos++}
        if ($pos -lt 0) {$pos = $menuItems.length -1}
		if ($pos -ge $menuItems.length) {$pos = 0}
        DrawMenu $menuItems $pos $menuTitel
    }
    Write-Output $($menuItems[$pos])
}
###############Menus and submenus########################

function MainMenu {
$options = "Install Git","Install Jdk","Install Android SDK to $Env:USERPROFILE\AppData\Local\Android\Sdk","Install Android Studio (Optional)","Clone AAPS to $aapsFolder","Switch to master Branch","Switch to dev Branch","Build","-Exit-"
	$selection = Menu $options "Build AndroidAPS"
	Switch ($selection) {
		"Install Git" {.$scriptroot\installGit.ps1;anykey;MainMenu}
		"Install Jdk" {.$scriptroot\installJdk.ps1;anykey;MainMenu}
		"Install Android SDK to $Env:USERPROFILE\AppData\Local\Android\Sdk" {.$scriptroot\installAndroidSDK.ps1;anykey;MainMenu}
		"Install Android Studio (Optional)" {.$scriptroot\installAndroidStudio.ps1;anykey;MainMenu}
		"Clone AAPS to $aapsFolder" {
		git clone https://github.com/MilosKozak/AndroidAPS.git $aapsFolder
		git --git-dir=$aapsFolder\.git --work-tree=$aapsFolder remote add mainRepo git://github.com/MilosKozak/AndroidAPS.git
		;anykey;MainMenu}
		"Switch to master Branch" {
		git --git-dir=$aapsFolder\.git --work-tree=$aapsFolder  fetch mainRepo
		git --git-dir=$aapsFolder\.git --work-tree=$aapsFolder reset --hard mainRepo/master;anykey;MainMenu}		
		"Switch to dev Branch" {
		git --git-dir=$aapsFolder\.git --work-tree=$aapsFolder  fetch mainRepo
		git --git-dir=$aapsFolder\.git --work-tree=$aapsFolder reset --hard mainRepo/dev;anykey;MainMenu}
		"Build" {buildaaps}
		"-Exit-" {Exit}
	}
}

function buildaaps {
$key = Set-Key "AndroidAPSpasswordkey"
#$plainText = "password"
#$encryptedTextThatIcouldSaveToFile = Set-EncryptedData -key $key -plainText $plaintext
#$encryptedTextThatIcouldSaveToFile
$passwordhash = "76492d1116743f0423413b16050a5345MgB8ADMAOQBIAG0AYwBkAEUANABTAGwARQBnAFcAVQBjAFAATwBoAGIASgB4AEEAPQA9AHwANwBlADQAYQAwADYAMwAxADUAMwBjADYAZgA1ADMAMQBlAGUAZQA3AGYAMwAxADMANQAwAGEAYQA4ADIAMQBiAA=="
$password2 = Get-EncryptedData -data $passwordhash -key $key
$password = read-host "password"
if (!($password -eq $password2)) {
MainMenu
}
$options = "Full","NSClient","Openloop","Pumpcontrol","-Main Menu-","-Exit-"
	$selection = Menu $options "Build AndroidAPS"
	Switch ($selection) {
		"Full" {$flavor = "Full";assembly;anykey;MainMenu}
		"NSClient" {$flavor = "NSClient";assembly;anykey;MainMenu}
		"Openloop" {$flavor = "Openloop";assembly;anykey;MainMenu}
		"Pumpcontrol" {$flavor = "Pumpcontrol";assembly;anykey;MainMenu}
		"-Main Menu-" {MainMenu}
		"-Exit-" {Exit}
	}
}

function assembly {
$options = "Nowear","Wear","Wearcontrol","-Main Menu-","-Exit-"
	$selection = Menu $options "Select Wear Options!"
	Switch ($selection) {
		"Nowear" {
		cmd.exe /C "`"$gradlewPath`" -p `"$aapsFolder`" assemble`"$flavor`"Nowear"
		cmd.exe /C "`"$gradlewPath`" --stop"
		if (Test-Path $apkFolder) { explorer $apkFolder}}
		"Wear" {
		cmd.exe /C "`"$gradlewPath`" -p `"$aapsFolder`" assemble`"$flavor`"Wear"
		cmd.exe /C "`"$gradlewPath`" --stop"
		if (Test-Path $apkFolder) { explorer $apkFolder}}
		"Wearcontrol" {
		cmd.exe /C "`"$gradlewPath`" -p `"$aapsFolder`" assemble`"$flavor`"Wearcontrol"
		cmd.exe /C "`"$gradlewPath`" --stop" 		
		if (Test-Path $apkFolder) { explorer $apkFolder}}
		"-Main Menu-" {MainMenu}
		"-Exit-" {Exit}
	}
}

function anykey {
Write-Host "Press Any Key To Continue... " 
$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Set-Key {
param([string]$string)
$length = $string.length
$pad = 32-$length
if (($length -lt 16) -or ($length -gt 32)) {Throw "String must be between 16 and 32 characters"}
$encoding = New-Object System.Text.ASCIIEncoding
$bytes = $encoding.GetBytes($string + "0" * $pad)
return $bytes
}

function Set-EncryptedData {
param($key,[string]$plainText)
$securestring = new-object System.Security.SecureString
$chars = $plainText.toCharArray()
foreach ($char in $chars) {$secureString.AppendChar($char)}
$encryptedData = ConvertFrom-SecureString -SecureString $secureString -Key $key
return $encryptedData
}

function Get-EncryptedData {
param($key,$data)
$data | ConvertTo-SecureString -key $key |
ForEach-Object {[Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($_))}
}

#call MainMenu
MainMenu



