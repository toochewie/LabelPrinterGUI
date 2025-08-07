@echo off

:: Set working directory to "Printing"
cd /d "%~dp0"

set /p PRINTER=<printer_name.txt

:: Batch script to print ZPL file
echo %1

:: Print ZPL file to the default printer
COPY %1 "\\localhost\%PRINTER%"

::Delete ZPL file
del %1

:: End of script
exit
