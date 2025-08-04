@echo off

:: Get result of pull
git pull https://github.com/Chewie610/LabelPrinterGUI.git > git_output.txt

:: Check if output contains "Already up to date."
findstr /C:"Already up to date." git_output.txt >nul
IF %ERRORLEVEL% EQU 0 (
    echo No update needed.
    del git_output.txt
    exit /b
)

:: Otherwise, restart the app
del git_output.txt

taskkill /f /im mshta.exe >nul 2>&1

start "" mshta.exe "%~dp0LabelPrinterGUI.hta"
exit
