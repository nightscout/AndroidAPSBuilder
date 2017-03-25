(get-host).ui.rawui.backgroundcolor = "black"
(get-host).ui.rawui.foregroundcolor = "green"

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

function copyApk {
Get-ChildItem $apkFolder -Filter *.apk | Foreach-Object {
		$fullname = $_.FullName
		write-host "======================================================" 
		write-host "copy $_ to`r`n$parentFolder\apk\" -foregroundcolor yellow
		write-host "======================================================`r`n"
		Copy-Item "$fullname" -Destination (New-Item "$parentFolder\apk\" -Type container -Force) -Force
		}
}

$scriptroot = Get-ScriptDirectory
$parentFolder = (get-item $scriptroot ).parent.FullName
$aapsFolder = "$parentFolder\AndroidAPS"
$apkFolder = "$aapsFolder\app\build\outputs\apk" 
$androidSDK = "$Env:ANDROID_HOME"
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
		return
		} else {
		$verify = cmd /c $buildtools\apksigner.bat verify -v $parentFolder\apk\$signedName.apk '2>&1' | Out-String | Tee-Object -Variable verify
		write-host -nonewline $verify
		write-host "Signing of $signedName.apk complete"  -foregroundcolor magenta
		write-host ""}
	}
	if ($signer -like "*password was incorrect*") {return}

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
		return
		} else {
		$verify = cmd /c $buildtools\apksigner.bat verify -v $parentFolder\apk\$signedName.apk '2>&1' | Out-String | Tee-Object -Variable verify
		write-host -nonewline $verify
		write-host "Signing of $signedName.apk complete"  -foregroundcolor magenta
		write-host ""}
	}
	if ($signer -like "*password was incorrect*") {return}
	
Get-ChildItem $parentFolder\apk\ -Filter *debug.apk | Remove-Item
Get-ChildItem $parentFolder\apk\ -Filter *aligned.apk | Remove-Item
Get-ChildItem $parentFolder\apk\ -Filter *unsigned.apk | Remove-Item
