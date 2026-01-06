@echo off 
SETLOCAL
IF "%1"=="-p" (
FOR %%i IN (*.lvt) DO comparepdf -p -elvt -r2 %2 %%~ni 2>>comparepdf.log 
FOR %%i IN (*.pvt) DO comparepdf -p -epvt -r2 %2 %%~ni 2>>comparepdf.log 
) else (
FOR %%i IN (*.lvt) DO comparepdf -elvt -r2 %1 %%~ni 2>>comparepdf.log 
FOR %%i IN (*.pvt) DO comparepdf -epvt -r2 %1 %%~ni 2>>comparepdf.log 
)
