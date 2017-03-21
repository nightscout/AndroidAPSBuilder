(get-host).ui.rawui.backgroundcolor = "black"
(get-host).ui.rawui.foregroundcolor = "green"
(get-host).ui.rawui.WindowTitle = "Install apk"

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

$androidSDK = "$Env:ANDROID_HOME"
$adbPath = "$androidSDK\platform-tools\adb.exe"
$scriptroot = Get-ScriptDirectory 
$parentFolder = (get-item $scriptroot ).parent.FullName
$apkFolder = "$parentFolder\apk\"

function anykey {
Write-Host "Press Any Key To Continue... " 
$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

	Write-Host "
  * DISCLAIMER: *
  I am not responsible for any lost files, bricked devices, thermonuclear war, 
  zombie holocaust or your dog dropping dead after using this script.
  Make sure you have a working backup of AAPS before using this script.
  "
	
	# Initialize ADB server
	& $adbPath start-server
	
	Write-Host ""
	Write-Host "Enable ADB debugging in developer settings on your phone."
	Write-Host "Now connect your device. When your device is connected. Look at the screen to grant access"
	anykey
		
	# Get serialno and write it
	Write-Host ""
	Write-Host –NoNewLine "Connected device: "
	$serial = & $adbPath get-serialno
	Write-Host "$serial"
	Write-Host ""
		
	# If no device is connected 
	if ($serial -eq "unknown") {
		Write-Host "Error: No device connected."
		return
	}
	elseif ($serial -eq "error*") {
		Write-Host "Error: No device connected."
		return
	} else {
	
	write-host "================================================"
	$apks = Get-ChildItem $apkFolder -Filter *.apk
	$menu = @{}
	for ($i=1;$i -le $apks.count; $i++) {
    Write-Host "$i $($apks[$i-1].name)" -fore "yellow"
    $menu.Add($i,($apks[$i-1].FullName))
    }
	write-host "================================================"

	[int]$ans = Read-Host 'Enter number of apk which you like to install'
	$selection = $menu.Item($ans)
	
	# Uninstall but keep cache and data
	write-host ""
	write-host "======================================================================================================="
	write-host "ATTENTION! if you installed AAPS as debug.apk and want to install release build then"
	write-host "please make a settings Backup and then Uninstall it over 'Settings > Apps' otherwise install fails"
	write-host ""
	write-host "Or you can sign your debug.apk before installing with release key. look at the menu to do this"
	Write-Host "Then you must not uninstall AAPS before."
	write-host "======================================================================================================="
	write-host ""
	anykey
	
	# Install APK
	Write-Host –NoNewLine "Installing: "
	& $adbPath install -r $selection
	
	# Shutdown ADB server
	& $adbPath kill-server
	Write-Host "* Shutdown ADB succesfully *"
	}
