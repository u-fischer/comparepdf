@echo off 
SETLOCAL
set batchpath=%~dp0
texlua %batchpath%comparepdf.lua %1 %2 %3 %4  %5 %6
