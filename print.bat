@echo off
:: Batch script to print ZPL file
echo %1

:: Print ZPL file to the default printer
COPY %1 \\LabelTablet\LoveBao

::Delete ZPL file
del %1

:: End of script
exit
