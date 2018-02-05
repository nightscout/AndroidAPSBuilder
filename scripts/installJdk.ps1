(get-host).ui.rawui.backgroundcolor = "black"
(get-host).ui.rawui.foregroundcolor = "green"
(get-host).ui.rawui.WindowTitle = "Install JDK"

$downloadFolder="$Env:USERPROFILE\Downloads"
$JDK_VER="8u162"
$JDK_FULL_VER="8u162-b12"
$JDK_PATH="1.8.0_162"
$id = "0da788060d494f5095bf8624735fa2f1"
#http://download.oracle.com/otn-pub/java/jdk/8u162-b12/0da788060d494f5095bf8624735fa2f1/jdk-8u162-windows-x64.exe



if (test-path .\preDownloadPackage) {
Start-Process ".\preDownloadPackage\GIT\Git-2.14.1-64-bit.exe" -ArgumentList "/VERYSILENT" -wait -nonewwindow
try {
    Write-Host 'Installing JDK-x64'
    $proc1 = Start-Process -FilePath ".\preDownloadPackage\JDK\jdk-8u144-windows-x64" -ArgumentList "/s REBOOT=ReallySuppress" -Wait -PassThru
    $proc1.waitForExit()
    Write-Host 'Installation Done.'
} catch [exception] {
    write-host '$_ is' $_
    write-host '$_.GetType().FullName is' $_.GetType().FullName
    write-host '$_.Exception is' $_.Exception
    write-host '$_.Exception.GetType().FullName is' $_.Exception.GetType().FullName
    write-host '$_.Exception.Message is' $_.Exception.Message
}
} else { 

$source64 = "http://download.oracle.com/otn-pub/java/jdk/$JDK_FULL_VER/$id/jdk-$JDK_VER-windows-x64.exe"
$destination64 = "$downloadFolder\$JDK_VER-x64.exe"
$client = new-object System.Net.WebClient
$cookie = "oraclelicense=accept-securebackup-cookie"
$client.Headers.Add([System.Net.HttpRequestHeader]::Cookie, $cookie)

Write-Host "Downloading x64 to $destination64"
$client.downloadFile($source64, $destination64)
if (!(Test-Path $destination64)) {
    Write-Host "Downloading $destination64 failed"
    Exit
}

 
try {
    Write-Host 'Installing JDK-x64'
    $proc1 = Start-Process -FilePath "$destination64" -ArgumentList "/s REBOOT=ReallySuppress" -Wait -PassThru
    $proc1.waitForExit()
    Write-Host 'Installation Done.'
} catch [exception] {
    write-host '$_ is' $_
    write-host '$_.GetType().FullName is' $_.GetType().FullName
    write-host '$_.Exception is' $_.Exception
    write-host '$_.Exception.GetType().FullName is' $_.Exception.GetType().FullName
    write-host '$_.Exception.Message is' $_.Exception.Message
}
}
 
if ((Test-Path "c:\Program Files\Java") -Or (Test-Path "c:\Program Files\Java")) {
    Write-Host 'Java installed successfully.'
}

Write-Host 'Setting up Path variables.'
$javaHome = "c:\Program Files\Java\jdk$JDK_PATH"
$path = $Env:Path + ";c:\Program Files\Java\jdk$JDK_PATH\bin"
Start-Process CMD -ArgumentList "/C setx -m JAVA_HOME `"$javaHome`" & setx -m PATH `"$path`"" -Verb RunAs

If (Test-Path $destination64){			
		Remove-Item $destination64
	}
	
Write-Host 'Done. Goodbye.'
