@echo off
cd /d "%~dp0"

:: Pull updates and store output
git pull https://github.com/Chewie610/LabelPrinterGUI.git > git_output.txt

:: Check if up to date
findstr /C:"Already up to date." git_output.txt >nul
IF %ERRORLEVEL% EQU 0 (
    echo NO_UPDATE > update_status.txt
    del git_output.txt
    exit /b
)

:: Otherwise, updates were made
echo UPDATED > update_status.txt
del git_output.txt

:: We can't kill the app here as we need the alert in the app...
::taskkill /f /im mshta.exe >nul 2>&1
::start "" mshta.exe "%~dp0launcher.hta"
exit
