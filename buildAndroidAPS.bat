Powershell -ExecutionPolicy Bypass -Command "ls -Recurse .\scripts\*.ps1 | Unblock-File"
Powershell -ExecutionPolicy Bypass -Command Start-Process "$PSHome\PowerShell.exe" -ArgumentList ' -ExecutionPolicy Bypass -file ".\scripts\buildAndroidAPS.ps1"'


