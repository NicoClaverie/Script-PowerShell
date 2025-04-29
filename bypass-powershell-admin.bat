@echo off
:: Verifie si on est en admin
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Elevation requise. Relancement en administrateur...
    powershell -Command "Start-Process '%~f0' -Verb runAs"
    exit /b
)

:: Lancement PowerShell avec ExecutionPolicy Bypass
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell.exe -ArgumentList '-NoProfile -ExecutionPolicy Bypass' -Verb runAs"
