@echo off

set /p PRINTER=<printer_name.txt

:: Batch script to print ZPL file
echo %1

:: Print ZPL file to the default printer
COPY %1 \\%COMPUTERNAME%\%PRINTER%

::Delete ZPL file
del %1

:: End of script
exit
