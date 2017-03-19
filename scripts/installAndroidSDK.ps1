(get-host).ui.rawui.backgroundcolor = "black"
(get-host).ui.rawui.foregroundcolor = "green"
(get-host).ui.rawui.WindowTitle = "Install Android SDK"

$sdkFolder="$Env:USERPROFILE\AppData\Local\Android\Sdk"
$url = "https://dl.google.com/android/repository/sdk-tools-windows-3773319.zip"
$output = "$sdkFolder\AndroidSDK.zip"
$start_time = Get-Date

if (!(Test-Path $sdkFolder)) {
	new-item $sdkFolder -itemtype directory
}

function Unzip {
    param([string]$zipfile, [string]$outpath)
	write-host "Unzipping $zipfile"
    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)
}

if (!(Test-Path $sdkFolder\tools)) {
	Import-Module BitsTransfer
	Start-BitsTransfer -Source $url -Destination $output
	Write-Output "Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"
	Add-Type -AssemblyName System.IO.Compression.FileSystem
	Unzip $output $sdkFolder
	If (Test-Path $output){			
		Remove-Item $output
	}
}

$AndroidToolPath = "$sdkFolder\tools\bin\sdkmanager.bat"
& $AndroidToolPath 'platform-tools' 'platforms;android-23' 'build-tools;25.0.2' 'extras;google;m2repository' 'extras;android;m2repository' --verbose
Start-Process CMD -ArgumentList "/C setx -m ANDROID_HOME `"$sdkFolder`"" -Verb RunAs
