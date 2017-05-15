(get-host).ui.rawui.backgroundcolor = "black"
(get-host).ui.rawui.foregroundcolor = "green"
(get-host).ui.rawui.WindowTitle = "Install Android Studio"

$downloadFolder="$Env:USERPROFILE\Downloads"
$url = "https://dl.google.com/dl/android/studio/install/2.3.2.0/android-studio-bundle-162.3934792-windows.exe"
$output = "$downloadFolder\AndroidStudio.exe"
$start_time = Get-Date

Import-Module BitsTransfer
Start-BitsTransfer -Source $url -Destination $output
Write-Output "Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"
Write-host "Installing Android Studio"
Start-Process $output -ArgumentList "/S" -Verb RunAs -wait
write-host "Install finished"
If (Test-Path $output){			
	Remove-Item $output
}