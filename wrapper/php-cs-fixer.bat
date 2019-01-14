@echo off

setlocal DISABLEDELAYEDEXPANSION

%WINDIR%\System32\bash.exe -c "php %*"
