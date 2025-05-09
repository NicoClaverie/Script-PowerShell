@echo off
net session >nul 2>&1
if %errorLevel% == 0 (
    goto :run
)

echo Demande d'elevation de privileges...
powershell -Command "Start-Process '%~f0' -Verb RunAs"
goto :eof

:run
echo.
echo Import des associations de fichiers par defaut depuis la cle USB...
dism /Online /Import-DefaultAppAssociations:"%~d0\defaultapps.xml"
echo.
echo Operation terminee.
pause
