Powershell -ExecutionPolicy Bypass -Command "ls -Recurse .\scripts\*.ps1 | Unblock-File"
Powershell -ExecutionPolicy Bypass -file ".\scripts\buildAndroidAPS.ps1"


