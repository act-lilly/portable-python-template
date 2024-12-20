@echo off

:: Define variables
set "WM_URL=https://github.com/WinMerge/winmerge/releases/download/v2.16.44/winmerge-2.16.44-x64-exe.zip"
set "WM_ZIP=winmerge.portable.zip"
set "WM_FOLDER=winmerge"
set "WM_EXE=WinMerge\\WinMergeU.exe"
set "LINK_NAME=Launch_WinMerge"
set "LINK_PATH=%~dp0%LINK_NAME%.lnk"

:: Step 1: Download WinMerge portable ZIP file
echo Downloading WinMerge portable...
curl -L -o "%WM_ZIP%" "%WM_URL%"
if not exist "%WM_ZIP%" (
    echo ERROR: Failed to download WinMerge portable. Exiting.
    pause
    exit /b
)
echo Successfully downloaded WinMerge portable.

:: Step 2: Create a folder for extraction
echo Extracting WinMerge portable...
mkdir "%WM_FOLDER%"
tar -xf "%WM_ZIP%" -C "%WM_FOLDER%"
if %errorlevel% neq 0 (
    echo ERROR: Failed to extract WinMerge portable. Exiting.
    pause
    exit /b
)
echo Successfully extracted WinMerge portable.

:: Step 3: Create symbolic link
echo Creating symbolic link...
mklink "%LINK_PATH%" "%~dp0%WM_FOLDER%\%WM_EXE%"
if %errorlevel% neq 0 (
    echo ERROR: Failed to create symbolic link. Exiting.
    pause
    exit /b
)
echo Symbolic link created successfully: %LINK_PATH%.

:: Step 4: Clean up
echo Cleaning up...
del "%WM_ZIP%"
echo Done! Use the symbolic link '%LINK_NAME%' to launch WinMerge.
pause
