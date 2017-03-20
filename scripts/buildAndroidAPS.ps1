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
$androidSDK = "$Env:ANDROID_HOME"

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
$options = "Install Git","Install Jdk","Install Android SDK to $Env:USERPROFILE\AppData\Local\Android\Sdk","Install Android Studio (Optional)","Clone AAPS to $aapsFolder","Switch to master Branch","Switch to dev Branch","Build","Generate key for signing","Sign APKs and copy to $parentFolder\apk","Install APK","-Exit-"
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
		"Generate key for signing" {keytool -genkey -v -keystore $parentFolder\aaps-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias aaps-key;anykey;MainMenu}
		"Sign APKs and copy to $parentFolder\apk" {signAPK;anykey;MainMenu}
		"Install APK" {.$scriptroot\ADB.ps1;anykey;MainMenu}
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
		"Full" {$flavor = "Full";buildType;anykey;MainMenu}
		"NSClient" {$flavor = "NSClient";buildType;anykey;MainMenu}
		"Openloop" {$flavor = "Openloop";buildType;anykey;MainMenu}
		"Pumpcontrol" {$flavor = "Pumpcontrol";buildType;anykey;MainMenu}
		"-Main Menu-" {MainMenu}
		"-Exit-" {Exit}
	}
}

function buildType {
$options = "Debug","Release","-Main Menu-","-Exit-"
	$selection = Menu $options "Select Wear Options!"
	Switch ($selection) {
		"Debug" {$type= "Debug";assemble}
		"Release" {$type = "Release";assemble}
		"-Main Menu-" {MainMenu}
		"-Exit-" {Exit}
	}
}

function assemble {
$options = "Nowear","Wear","Wearcontrol","-Main Menu-","-Exit-"
	$selection = Menu $options "Select Wear Options!"
	Switch ($selection) {
		"Nowear" {
		cmd.exe /C "`"$gradlewPath`" -p `"$aapsFolder`" assemble`"$flavor`"Nowear`"$type`""
		cmd.exe /C "`"$gradlewPath`" --stop"
		copyDebugApk}
		"Wear" {
		cmd.exe /C "`"$gradlewPath`" -p `"$aapsFolder`" assemble`"$flavor`"Wear`"$type`""
		cmd.exe /C "`"$gradlewPath`" --stop"
		copyDebugApk}
		"Wearcontrol" {
		cmd.exe /C "`"$gradlewPath`" -p `"$aapsFolder`" assemble`"$flavor`"Wearcontrol`"$type`""
		cmd.exe /C "`"$gradlewPath`" --stop" 		
		copyDebugApk}
		"-Main Menu-" {MainMenu}
		"-Exit-" {Exit}
	}
}

function anykey {
Write-Host "Press Any Key To Continue... " 
$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function copyDebugApk {
Get-ChildItem $apkFolder -Filter *debug.apk | Foreach-Object {
		$fullname = $_.FullName
		write-host "======================================================"
		write-host "copy $_ to"
		write-host "$parentFolder\apk\"
		write-host "======================================================"
		Copy-Item "$fullname" -Destination (New-Item "$parentFolder\apk\" -Type container -Force) -Force
		}
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

function signAPK {
$buildTools = (gci $androidSDK\build-tools\ | sort LastWriteTime | select -last 1).FullName
Get-ChildItem $apkFolder -Filter *unsigned.apk | 
	Foreach-Object {
		write-host "======================================================"
		write-host "Signing $_"
		write-host "======================================================"
		write-host ""
		write-host ""
		$basename = $_.BaseName
		$signedName = $basename.Replace("unsigned","signed")
		& $buildtools\zipalign.exe -p 4 $_.FullName $apkFolder\$basename-aligned.apk
		write-host "---------"
		& $buildtools\apksigner.bat sign --verbose --ks $parentFolder\aaps-release-key.jks --out $apkFolder\$signedName.apk $apkFolder\$basename-aligned.apk
		write-host "---------"
		& $buildtools\apksigner.bat verify $apkFolder\$signedName.apk			
		write-host "Signing of $signedName.apk complete"
		If (Test-Path $apkFolder\$basename-aligned.apk){Remove-Item $apkFolder\$basename-aligned.apk}
		Copy-Item "$apkFolder\$signedName.apk" -Destination (New-Item "$parentFolder\apk\" -Type container -Force) -Force
		write-host ""
		write-host ""
	}
}

function disclaimer {

	Write-Host "
  * DISCLAIMER AND WARNING: *
	All information, thought, and code described here is intended for informational and educational purposes only. 
	Nightscout currently makes no attempt at HIPAA privacy compliance. 
	Use Nightscout and AndroidAPS at your own risk, 
	and do not use the information or code to make medical decisions.
	Use of code from github.com is without warranty or formal support of any kind. 
	Please review this repository's LICENSE for details.
	All product and company names, trademarks, servicemarks, registered trademarks, 
	and registered servicemarks are the property of their respective holders. 
	Their use is for information purposes and does not imply any affiliation with or endorsement by them.
	Please note - this project has no association with and is not endorsed by:
	SOOIL or Dexcom
	"
}

#call MainMenu
cls
disclaimer
anykey
MainMenu