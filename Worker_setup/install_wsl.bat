@echo off
setlocal enabledelayedexpansion
REM --- Title command ko quotes mein daala gaya hai tak-i error na aaye ---
title "WSL + Ubuntu Auto Installer (Final & Reliable)"
color 0A

echo ======================================
echo     WSL + Ubuntu Auto Installer
echo ======================================
echo.

REM -------------------------------------------------------
REM Step 1 — WSL उपलब्धता की जाँच करें
REM -------------------------------------------------------
echo Checking WSL availability...
wsl.exe --version >nul 2>&1
if %errorlevel% neq 0 (
    echo WSL install nahi hai. WSL install kiya ja raha hai...
    wsl.exe --install
    echo.
    echo ==============================================
    echo  SYSTEM RESTART KARNA ZAROORI HAI
    echo ==============================================
    pause
    exit /b 0
)
echo [OK] WSL feature pehle se install hai.
echo.

REM ---------------------------------------------------------------------
REM Step 2 — UBUNTU DETECTION (Sabse Mazboot Tarika - Temp File ka Upyog)
REM ---------------------------------------------------------------------
echo Ubuntu distribution ki jaanch ki ja rahi hai...

REM --- Ek temporary file ka naam set karein ---
set "tempfile=%TEMP%\wsl_distro_list.txt"

REM --- wsl -l -v ke output ko temporary file mein save karein. Yeh encoding ki samasya ko hal karta hai. ---
wsl.exe -l -v > "%tempfile%" 2>nul

REM --- Ab us temporary file mein "Ubuntu" shabd ko dhoondhein ---
findstr /I "Ubuntu" "%tempfile%" >nul 2>&1

REM --- Kripya safai karein aur temporary file ko delete kar dein ---
del "%tempfile%"

REM --- findstr ke errorlevel ko check karein. 0 matlab mil gaya. ---
if %errorlevel% == 0 (
    echo [OK] Ubuntu distribution pehle se maujood hai.
    goto CHECK_USER
)

echo Ubuntu install nahi hai.
echo Ubuntu install kiya ja raha hai...
echo.
wsl.exe --install -d Ubuntu

echo.
echo ==============================================
echo  SYSTEM RESTART KARNA ZAROORI HAI
echo ==============================================
pause
exit /b 0


:CHECK_USER
echo.
echo Jaanch ki ja rahi hai ki Ubuntu user account bana hai ya nahi...

wsl.exe -d Ubuntu -e bash -c "id -u" >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo *********************************************
    echo Ubuntu install ho gaya hai lekin abhi shuru nahi hua hai.
    echo *********************************************
    echo Kripya ek baar Ubuntu ko manually kholen:
    echo    - Apna username/password banayein
    echo    - Phir Ubuntu ko band kar dein
    echo    - Aur is installer ko dobara chalayein
    echo.
    pause
    exit /b 0
)

echo [OK] Ubuntu user account pehle se set hai.
echo.

echo ======================================
echo  WSL + Ubuntu Installation Complete
echo ======================================
pause
exit /b 0