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
$gitRepo = 'https://github.com/MilosKozak/AndroidAPS.git'


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
			Write-Host "	$($menuItems[$i])" -fore $bcolor -back $fcolor
		} 
		else {
			Write-Host "	$($menuItems[$i])" -fore $fcolor -back $bcolor
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
$options = "First install Powershell 5 only for win 7/8/8.1","Install Git","Install Jdk","Install Android SDK to $Env:USERPROFILE\AppData\Local\Android\Sdk","Install Android Studio (Optional)`r`n","Clone AAPS to $aapsFolder","Switch to or update master Branch","Switch to or update dev Branch`r`n","Build","Generate key for signing","Sign APK's","Install APK`r`n","-Exit-"
	$selection = Menu $options "Build AndroidAPS"
	Switch ($selection) {
		"First install Powershell 5 only for win 7/8/8.1" {cls;installPS5;anykey;Exit}
		"Install Git" {cls;.$scriptroot\installGit.ps1;anykey;MainMenu}
		"Install Jdk" {cls;.$scriptroot\installJdk.ps1;anykey;MainMenu}
		"Install Android SDK to $Env:USERPROFILE\AppData\Local\Android\Sdk" {cls;.$scriptroot\installAndroidSDK.ps1;anykey;MainMenu}
		"Install Android Studio (Optional)`r`n" {cls;.$scriptroot\installAndroidStudio.ps1;anykey;MainMenu}
		"Clone AAPS to $aapsFolder" {cls;git clone $gitRepo $aapsFolder;addRemote;anykey;MainMenu}
		"Switch to or update master Branch" {cls;fetchMainRepo;resetRepo master;anykey;MainMenu}		
		"Switch to or update dev Branch`r`n" {cls;fetchMainRepo;resetRepo dev;anykey;MainMenu}
		"Build" {buildaaps}
		"Generate key for signing" {cls;generateKey;anykey;MainMenu}
		"Sign APK's" {cls;signAPK;anykey;MainMenu}
		"Install APK`r`n" {cls;.$scriptroot\ADB.ps1;anykey;MainMenu}
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
	$selection = Menu $options "Select Build Flavor"
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
	$selection = Menu $options "Select Build Type!"
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

function fetchMainRepo {
git --git-dir=$aapsFolder\.git --work-tree=$aapsFolder fetch mainRepo
}

function resetRepo($branch) {
git --git-dir=$aapsFolder\.git --work-tree=$aapsFolder reset --hard mainRepo/$branch		
}

function addRemote {
git --git-dir=$aapsFolder\.git --work-tree=$aapsFolder remote add mainRepo $gitRepo
}

function installPS5 {
Start-Process "$PSHome\PowerShell.exe" -Verb RunAs -ArgumentList " -ExecutionPolicy bypass  -file $scriptroot\installPowershell5.ps1" -Wait
}

function generateKey {
keytool -genkey -v -keystore $parentFolder\aaps-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias aaps-key
}

function copyDebugApk {
Get-ChildItem $apkFolder -Filter *debug.apk | Foreach-Object {
		$fullname = $_.FullName
		write-host "======================================================"
		write-host "copy $_ to`r`n$parentFolder\apk\" -foregroundcolor yellow
		write-host "======================================================"
		Copy-Item "$fullname" -Destination (New-Item "$parentFolder\apk\" -Type container -Force) -Force
		}
}

function copyApk {
Get-ChildItem $apkFolder -Filter *.apk | Foreach-Object {
		$fullname = $_.FullName
		write-host "======================================================" 
		write-host "copy $_ to`r`n$parentFolder\apk\" -foregroundcolor yellow
		write-host "======================================================`r`n"
		Copy-Item "$fullname" -Destination (New-Item "$parentFolder\apk\" -Type container -Force) -Force
		}
}

function removeApk {
Get-ChildItem $parentFolder\apk\ -Filter *debug.apk | Remove-Item
Get-ChildItem $parentFolder\apk\ -Filter *aligned.apk | Remove-Item
Get-ChildItem $parentFolder\apk\ -Filter *unsigned.apk | Remove-Item
}

function signAPK {
$buildTools = (gci $androidSDK\build-tools\ | sort LastWriteTime | select -last 1).FullName
$keystorepw = read-host "Keystore password"
copyApk
Get-ChildItem $parentFolder\apk -Filter *unsigned.apk | 
	Foreach-Object {
		write-host "======================================================"
		write-host "Signing $_" -foregroundcolor magenta
		write-host "======================================================"
		write-host ""
		$basename = $_.BaseName
		$signedName = $basename.Replace("unsigned","signed")
		$zipalign = cmd /c $buildtools\zipalign.exe -p 4 $_.FullName $parentFolder\apk\$basename-aligned.apk '2>&1' | Out-String | Tee-Object -Variable zipalign
		$signer= cmd /c $buildtools\apksigner.bat sign --verbose --ks $parentFolder\aaps-release-key.jks --ks-pass pass:$keystorepw --out $parentFolder\apk\$signedName.apk $parentFolder\apk\$basename-aligned.apk '2>&1' | Out-String | Tee-Object -Variable signer
		if ($signer -like "*password was incorrect*") {
		write-host "password was incorrect" -foregroundcolor red
		anykey
		removeApk
		MainMenu
		} else {
		$verify = cmd /c $buildtools\apksigner.bat verify -v $parentFolder\apk\$signedName.apk '2>&1' | Out-String | Tee-Object -Variable verify
		write-host -nonewline $verify
		write-host "Signing of $signedName.apk complete"  -foregroundcolor magenta
		write-host ""}
	}

Get-ChildItem $parentFolder\apk\ -Filter *debug.apk | 
	Foreach-Object {
		write-host "======================================================"
		write-host "Signing $_" -foregroundcolor magenta
		write-host "======================================================"
		write-host ""
		$basename = $_.BaseName
		$signedName = $basename.Replace("debug","debug-release-signed")
		$zipalign = cmd /c $buildtools\zipalign.exe -p 4 $_.FullName $parentFolder\apk\$basename-aligned.apk '2>&1' | Out-String | Tee-Object -Variable zipalign
		$signer= cmd /c $buildtools\apksigner.bat sign --verbose --ks $parentFolder\aaps-release-key.jks --ks-pass pass:$keystorepw --out $parentFolder\apk\$signedName.apk $parentFolder\apk\$basename-aligned.apk '2>&1' | Out-String | Tee-Object -Variable signer
		if ($signer -like "*password was incorrect*") {
		write-host "password was incorrect" -foregroundcolor red
		anykey
		removeApk
		MainMenu
		} else {
		$verify = cmd /c $buildtools\apksigner.bat verify -v $parentFolder\apk\$signedName.apk '2>&1' | Out-String | Tee-Object -Variable verify
		write-host -nonewline $verify
		write-host "Signing of $signedName.apk complete"  -foregroundcolor magenta
		write-host ""}
	}
	removeApk
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
	" -foregroundcolor magenta
}

#call MainMenu
cls
disclaimer
anykey
MainMenu