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
$options = "install Required Software`r`n","Clone AAPS to $aapsFolder","Switch or update local Branch`r`n","Build","Generate key for signing","Sign APK's","Install APK`r`n","-Exit-"
	$selection = Menu $options "Build AndroidAPS"
	Switch ($selection) {
		"install Required Software`r`n" {cls;requiredSoftware;anykey;MainMenu}
		"Clone AAPS to $aapsFolder" {cls;checkGit;git clone $gitRepo $aapsFolder;addRemote;anykey;MainMenu}
		"Switch or update local Branch`r`n" {cls;checkGit;checkaapsFolder;fetchRemoteRepo;selectRepo;anykey;MainMenu}
		"Build" {cls;checkaapsFolder;buildaaps;anykey;MainMenu}
		"Generate key for signing" {cls;generateKey;anykey;MainMenu}
		"Sign APK's" {cls;signAPK;anykey;MainMenu}
		"Install APK`r`n" {cls;checkAndroid_Home;.$scriptroot\ADB.ps1;anykey;MainMenu}
		"-Exit-" {Exit}
	}
}

function requiredSoftware {
$options = "First install Powershell 5 only for win 7/8/8.1","Install Git","Install Jdk","Install Android SDK to $Env:USERPROFILE\AppData\Local\Android\Sdk`r`n","Install Android Studio (Optional)`r`n","-Main Menu-","-Exit-"
	$selection = Menu $options "Select Software!"
	Switch ($selection) {
		"First install Powershell 5 only for win 7/8/8.1" {cls;installPS5;anykey;Exit}
		"Install Git" {cls;.$scriptroot\installGit.ps1;anykey;requiredSoftware}
		"Install Jdk" {cls;.$scriptroot\installJdk.ps1;anykey;requiredSoftware}
		"Install Android SDK to $Env:USERPROFILE\AppData\Local\Android\Sdk`r`n" {cls;checkJava_Home;.$scriptroot\installAndroidSDK.ps1;anykey;requiredSoftware}
		"Install Android Studio (Optional)`r`n" {cls;.$scriptroot\installAndroidStudio.ps1;anykey;requiredSoftware}
		"-Main Menu-" {MainMenu}
		"-Exit-" {Exit}
	}
}

function buildaaps {
checkAndroid_Home
checkJava_Home
checkaapsFolder
$key = Set-Key "AndroidAPSpasswordkey"
#$plainText = "password"
#$encryptedTextThatIcouldSaveToFile = Set-EncryptedData -key $key -plainText $plaintext
#$encryptedTextThatIcouldSaveToFile
$passwordhash = "76492d1116743f0423413b16050a5345MgB8ADMAOQBIAG0AYwBkAEUANABTAGwARQBnAFcAVQBjAFAATwBoAGIASgB4AEEAPQA9AHwANwBlADQAYQAwADYAMwAxADUAMwBjADYAZgA1ADMAMQBlAGUAZQA3AGYAMwAxADMANQAwAGEAYQA4ADIAMQBiAA=="
$password2 = Get-EncryptedData -data $passwordhash -key $key
$password = read-host "password"
if (!($password -eq $password2)) {
	write-host "`r`nwrong password!" -foregroundcolor red
	anykey
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
		renameAPK
		cmd.exe /C "`"$gradlewPath`" --stop"
		copyDebugApk}
		"Wear" {
		cmd.exe /C "`"$gradlewPath`" -p `"$aapsFolder`" assemble`"$flavor`"Wear`"$type`""
		renameAPK
		cmd.exe /C "`"$gradlewPath`" --stop"
		copyDebugApk}
		"Wearcontrol" {
		cmd.exe /C "`"$gradlewPath`" -p `"$aapsFolder`" assemble`"$flavor`"Wearcontrol`"$type`""
		renameAPK
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

function renameAPK {
#git --git-dir=$aapsFolder\.git --work-tree=$aapsFolder branch -vv | select-string -pattern '\*'				
$commitID = git --git-dir=$aapsFolder\.git --work-tree=$aapsFolder show --format="%h" --no-patch
$currentBranch = (git --git-dir=$aapsFolder\.git --work-tree=$aapsFolder status -b)[0]
$currentBranch = $currentBranch.replace("HEAD detached at remoteRepo/","")
$currentBranch = $currentBranch.replace("On branch ","")
$latest = Get-ChildItem -Path $apkFolder | Sort-Object LastAccessTime -Descending | Select-Object -First 1 
$oldfilename = ($latest.Name).replace("app-","")
$filename = "$currentBranch" + "_" + "$commitID" + "_" + $oldfilename
Get-ChildItem -Path $apkFolder | Sort-Object LastAccessTime -Descending | Select-Object -First 1 | Rename-Item -NewName "$filename"
}

function checkAndroid_Home {
$env:ANDROID_HOME = [System.Environment]::GetEnvironmentVariable("ANDROID_HOME","Machine") 
If (Test-Path env:ANDROID_HOME) {			
	$androidSDK = "$Env:ANDROID_HOME"
	} else {
	Write-Host "`r`nANDROID_HOME environment variable not set. please install android SDK!`r`n" -foregroundcolor red
	anykey
	MainMenu
	}
}

function checkJava_Home {
$env:PATH = [System.Environment]::GetEnvironmentVariable("PATH","Machine") 
$env:JAVA_HOME = [System.Environment]::GetEnvironmentVariable("JAVA_HOME","Machine") 
If (!(Test-Path env:JAVA_HOME)) {			
	Write-Host "`r`JAVA_HOME environment variable not set. please install JDK!`r`n" -foregroundcolor red
	anykey
	MainMenu
	}
}

function checkGit {
$env:PATH = [System.Environment]::GetEnvironmentVariable("PATH","Machine") 
if (!(Get-Command git -errorAction SilentlyContinue)) {
	Write-Host "`r`nGIT not installed. please install GIT!`r`n" -foregroundcolor red
	anykey
	MainMenu
	}
}

function checkaapsFolder {
If (!(Test-Path $aapsFolder)) {			
	Write-Host "`r`nplease clone aaps first!`r`n" -foregroundcolor red
	anykey
	MainMenu
	}
}

function fetchRemoteRepo {
git --git-dir=$aapsFolder\.git --work-tree=$aapsFolder fetch remoteRepo
cls
}

function selectRepo {
	Write-Host "
  * WARNING: *
	if you select a branch all local data will be reset, this means all changes you have done
	to the original aaps source code are lost. Backup it before continue.
	" -foregroundcolor magenta
anykey
cls
$currentBranch = (git --git-dir=$aapsFolder\.git --work-tree=$aapsFolder status -b)[0]
$currentBranch = $currentBranch.replace("HEAD detached at remoteRepo/","")
$currentBranch = $currentBranch.replace("On branch ","")
write-host "`r`n	Current Branch: $currentBranch`r`n" -foregroundcolor magenta
$apks = (git --git-dir=$aapsFolder\.git --work-tree=$aapsFolder ls-remote --heads remoteRepo).Substring(52)
write-host "	================================================"
write-host "	=============== select branch =================="
write-host "	================================================"
$menu = @{}
for ($i=1;$i -le $apks.count; $i++) {
   Write-Host "	$i $($apks[$i-1])" -fore "yellow"
   $menu.Add($i,($apks[$i-1]))
   }
write-host "	================================================"
write-host ""
[int]$ans = Read-Host 'Enter number of branch'
$branch = $menu.Item($ans)
resetRepo $branch
}

function resetRepo($branch) {
git --git-dir=$aapsFolder\.git --work-tree=$aapsFolder checkout -f remoteRepo/$branch				
}

function addRemote {
git --git-dir=$aapsFolder\.git --work-tree=$aapsFolder remote add remoteRepo $gitRepo
}

function installPS5 {
Start-Process "$PSHome\PowerShell.exe" -Verb RunAs -ArgumentList " -ExecutionPolicy bypass  -file $scriptroot\installPowershell5.ps1" -Wait
}

function generateKey {
checkJava_Home
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
Get-ChildItem $parentFolder\apk\ -Filter *aligned.apk | Remove-Item
Get-ChildItem $parentFolder\apk\ -Filter *unsigned.apk | Remove-Item
}

function signAPK {
checkJava_Home
checkAndroid_Home
copyApk
$androidSDK = "$Env:ANDROID_HOME" 
$buildTools = (gci $androidSDK\build-tools\ | sort LastWriteTime | select -last 1).FullName
$keystorepw = read-host "Keystore password"
Get-ChildItem $parentFolder\apk\* -Include *unsigned.apk, *debug.apk | 
	Foreach-Object {
		write-host ("=" * ($_.FullName.length + 10))
		write-host "Signing $_" -foregroundcolor magenta
		write-host ("=" * ($_.FullName.length + 10))
		write-host ""
		$basename = $_.BaseName
		if ($_.FullName -like "*debug.apk") {
			$signedName = $basename.Replace("debug","debug-signed")
		}
		if ($_.FullName -like "*unsigned.apk") {
			$signedName = $basename.Replace("unsigned","signed")
		}
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