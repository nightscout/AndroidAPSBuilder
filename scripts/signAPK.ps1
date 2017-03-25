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
		write-host "Signing $_" -foregroundcolor yellow
		write-host "======================================================"
		write-host ""
		$basename = $_.BaseName
		$signedName = $basename.Replace("unsigned","signed")
		& $buildtools\zipalign.exe -p 4 $_.FullName $parentFolder\apk\$basename-aligned.apk
		write-host "---------"
		& $buildtools\apksigner.bat sign --verbose --ks $parentFolder\aaps-release-key.jks --ks-pass pass:$keystorepw --out $parentFolder\apk\$signedName.apk $parentFolder\apk\$basename-aligned.apk 
		<#
		$jar = & jarsigner.exe -verbose -sigalg SHA1withRSA -digestalg SHA1 -keystore "$parentFolder\aaps-release-key.jks" -storepass "$keystorepw" -keypass "$keystorepw" -signedjar "$parentFolder\apk\$signedName.apk" "$parentFolder\apk\$basename-aligned.apk" aaps-key | Tee-Object -Variable jar
		if ($jar -like "*you must enter key password*" -or $jar -like "*jarsigner error*") {
		write-host $jar
		anykey
		MainMenu
		}
		#>
		write-host "---------"
		& $buildtools\apksigner.bat verify -v $parentFolder\apk\$signedName.apk
		write-host "Signing of $signedName.apk complete"  -foregroundcolor magenta
		write-host ""
		write-host ""
	}
	
Get-ChildItem $parentFolder\apk\ -Filter *debug.apk | 
	Foreach-Object {
		write-host "======================================================"
		write-host "Signing $_" -foregroundcolor yellow
		write-host "======================================================"
		write-host ""
		$basename = $_.BaseName
		$signedName = $basename.Replace("debug","debug-release-signed")
		& $buildtools\zipalign.exe -p 4 $_.FullName $parentFolder\apk\$basename-aligned.apk
		write-host "---------"
		& $buildtools\apksigner.bat sign --verbose --ks $parentFolder\aaps-release-key.jks --ks-pass pass:$keystorepw --out $parentFolder\apk\$signedName.apk $parentFolder\apk\$basename-aligned.apk 
		<#
		$jar = & jarsigner.exe -verbose -sigalg SHA1withRSA  -digestalg SHA1 -keystore "$parentFolder\aaps-release-key.jks" -storepass "$keystorepw" -keypass "$keystorepw" -signedjar "$parentFolder\apk\$signedName.apk" "$parentFolder\apk\$basename-aligned.apk" aaps-key | Tee-Object -Variable jar
		if ($jar -like "*you must enter key password*" -or $jar -like "*jarsigner error*") {
		write-host $jar
		anykey
		MainMenu
		}
		#>
		write-host "---------"
		& $buildtools\apksigner.bat verify -v -Werr $parentFolder\apk\$signedName.apk			
		write-host "Signing of $signedName.apk complete"  -foregroundcolor magenta
		write-host ""
		write-host ""
	}
	
Get-ChildItem $parentFolder\apk\ -Filter *debug.apk | Remove-Item
Get-ChildItem $parentFolder\apk\ -Filter *aligned.apk | Remove-Item
Get-ChildItem $parentFolder\apk\ -Filter *unsigned.apk | Remove-Item
