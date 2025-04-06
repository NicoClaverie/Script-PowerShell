@echo off
:: === [ Vérifie si on est en admin ] ===
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo [!] Ce script nécessite les droits administrateur.
    echo [~] Relancement avec élévation...
    powershell -Command "Start-Process '%~f0' -Verb runAs"
    exit /b
)

:: === [ Lecture du nom du processus ] ===
set /p PROC=Il faut tuer quoi ? : 

echo.
echo Tentative de fermeture de tous les processus : %PROC%
taskkill /F /IM %PROC% /T

echo.
echo Terminé. Appuie sur une touche pour quitter.
pause >nul
