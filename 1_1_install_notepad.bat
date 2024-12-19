@echo off

:: Define variables
set "NPP_URL=https://github.com/notepad-plus-plus/notepad-plus-plus/releases/download/v8.7/npp.8.7.portable.x64.zip"
set "NPP_ZIP=npp.portable.zip"
set "NPP_FOLDER=notepad"
set "NPP_EXE=notepad++.exe"
set "LINK_NAME=Launch_Notepad++"
set "LINK_PATH=%~dp0%LINK_NAME%.lnk"

:: Step 1: Download Notepad++ portable ZIP file
echo Downloading Notepad++ portable...
curl -L -o "%NPP_ZIP%" "%NPP_URL%"
if not exist "%NPP_ZIP%" (
    echo ERROR: Failed to download Notepad++ portable. Exiting.
    pause
    exit /b
)
echo Successfully downloaded Notepad++ portable.

:: Step 2: Create a folder for extraction
echo Extracting Notepad++ portable...
mkdir "%NPP_FOLDER%"
tar -xf "%NPP_ZIP%" -C "%NPP_FOLDER%"
if %errorlevel% neq 0 (
    echo ERROR: Failed to extract Notepad++ portable. Exiting.
    pause
    exit /b
)
echo Successfully extracted Notepad++ portable.

:: Step 3: Create symbolic link
echo Creating symbolic link...
mklink "%LINK_PATH%" "%~dp0%NPP_FOLDER%\%NPP_EXE%"
if %errorlevel% neq 0 (
    echo ERROR: Failed to create symbolic link. Exiting.
    pause
    exit /b
)
echo Symbolic link created successfully: %LINK_PATH%.

:: Step 4: Clean up
echo Cleaning up...
del "%NPP_ZIP%"
echo Done! Use the symbolic link '%LINK_NAME%' to launch Notepad++.
pause
