@echo on
:: Setup script using BusyBox for portability

:: Define URLs and filenames
set BUSYBOX_URL=https://frippery.org/files/busybox/busybox.exe
set BUSYBOX_EXE=busybox.exe
set SCRIPT_NAME=1_0_setup.sh

echo --------------------------------------------
echo Checking for BusyBox...
echo --------------------------------------------

:: Check if BusyBox is present
if not exist %BUSYBOX_EXE% (
    echo BusyBox not found. Downloading BusyBox...
    curl -L -o %BUSYBOX_EXE% %BUSYBOX_URL%
    if %errorlevel% neq 0 (
        echo Failed to download BusyBox. Please check your internet connection and try again.
        pause
        exit /b 1
    )
    echo BusyBox downloaded successfully.
) else (
    echo BusyBox is already present.
)

:: Ensure the shell script exists
if not exist %SCRIPT_NAME% (
    echo Shell script "%SCRIPT_NAME%" not found. Please ensure it is in the same directory.
    pause
    exit /b 1
)

echo --------------------------------------------
echo Executing the shell script with BusyBox...
echo --------------------------------------------

:: Execute the shell script using BusyBox
%BUSYBOX_EXE% sh %SCRIPT_NAME%

:: Check for errors during execution
if %errorlevel% neq 0 (
    echo Shell script execution failed. Exiting...
    pause
    exit /b 1
)

echo --------------------------------------------
echo Shell script executed successfully!
echo --------------------------------------------

pause
