@echo off
setlocal EnableDelayedExpansion
title hekate Builder Menu

rem ---------------------------------------------------------------
rem Interactive build menu for hekate (CTCaer/hekate).
rem Uses the devkitPro MSYS2 environment (C:\devkitPro\msys2).
rem Only devkitARM is needed (arm7tdmi boot code). Build is
rem timestamp-incremental; artifacts live in hekate\build + hekate\output.
rem ---------------------------------------------------------------

set "BASH=C:\devkitPro\msys2\usr\bin\bash.exe"
set "SCRIPT=/c/PROJECTS/switch/switch-cfw/hekate/build.sh"
set "JOBS=2"

if not exist "%BASH%" (
    echo ERROR: devkitPro MSYS2 bash not found at:
    echo   %BASH%
    echo Install devkitPro first: https://devkitpro.org
    pause
    exit /b 1
)

:menu
cls
echo ============================================
echo      hekate Build Menu
echo      Repo: C:\PROJECTS\switch\switch-cfw\hekate
echo      Jobs: %JOBS%
echo ============================================
echo.
echo   1) Build                  (make; produces output\hekate_ctcaer_*.bin, packages _ZIPS_/hekate-release.zip)
echo   2) Dry run                (shows what would build, no compile)
echo   3) Set job count          (currently %JOBS%)
echo   4) Clean                  (rm build\ and output\)
echo.
echo   0) Quit
echo.
set /p CHOICE="Select an option: "

if "%CHOICE%"=="1" ( set "TARGET=all" & goto build )
if "%CHOICE%"=="2" ( set "TARGET=all" & set "DRYRUN=1" & goto build )
if "%CHOICE%"=="3" goto jobs
if "%CHOICE%"=="4" ( set "TARGET=clean" & goto build )
if "%CHOICE%"=="0" exit /b 0
echo Invalid choice. & timeout /t 1 >nul & goto menu

:jobs
echo.
set /p JOBS="Enter job count (parallel make jobs): "
if "%JOBS%"=="" set "JOBS=2"
goto menu

:build
echo.
echo == Building: target=%TARGET% jobs=%JOBS% ==
if defined DRYRUN (
    "%BASH%" -lc "bash '%SCRIPT%' '%TARGET%' '%JOBS%' --dryrun"
) else (
    "%BASH%" -lc "bash '%SCRIPT%' '%TARGET%' '%JOBS%'"
)
echo.
if errorlevel 1 (
    echo == BUILD FAILED - see output above ==
) else (
    echo == DONE ==
)
set "DRYRUN="
pause
goto menu
