(get-host).ui.rawui.backgroundcolor = "black"
(get-host).ui.rawui.foregroundcolor = "green"
(get-host).ui.rawui.WindowTitle = "Download Logs"

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
$logFolder = "$parentFolder\files\"

function anykey {
Write-Host "Press Any Key To Continue... " 
$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

Write-Host "
* DISCLAIMER: *
I am not responsible for any lost files, bricked devices, thermonuclear war, 
zombie holocaust or your dog dropping dead after using this script.
Make sure you have a working backup of AAPS before using this script.
" -foregroundcolor magenta
	
# Initialize ADB server
& $adbPath start-server
	
Write-Host "
Enable ADB debugging in developer settings on your phone.
Now connect your device. When your device is connected. Look at the screen to grant access" -foregroundcolor magenta
anykey
		
# Get serialno and write it
Write-Host ""
Write-Host –NoNewLine "Connected device: "
$serial= cmd /c $adbPath get-serialno '2>&1' | Out-String | Tee-Object -Variable serial
$serial
# If no device is connected 
if ($serial -like "*unknown*") {
	Write-Host "Error: No device connected." -foregroundcolor red
	& $adbPath kill-server
	return
	} elseif ($serial -like "*no devices/emulators found*") {
	Write-Host "Error: No device connected." -foregroundcolor red
	& $adbPath kill-server
	return
	} elseif ($serial -like "*unauthorized*") {
	Write-Host "Error: Device not authorized. Check Screen to grand authorization." -foregroundcolor red
	& $adbPath kill-server
	return
} else {


if (!(Test-Path $logFolder)) {
	new-item $logFolder -itemtype directory | out-null
}
	
# Download Logs
Write-Host "Download Logs to $parentFolder\logs"
$install= cmd /c $adbPath pull /sdcard/Android/data/info.nightscout.androidaps/files/ $logFolder '2>&1' | Out-String | Tee-Object -Variable install

write-host $install -foregroundcolor cyan
robocopy "$parentFolder\files\files" "$parentFolder\logs\" /COPY:DAT /NFL /NDL /NJH /NJS /nc /ns /np
remove-item "$parentFolder\files" -force -recurse
# Shutdown ADB server
& $adbPath kill-server
Write-Host "* Shutdown ADB succesfully *"
}