@echo off

:: Capture the directory where this batch script is located
set PARENT_DIR=%~dp0

:: Change to the Scripts directory inside the virtual environment
cd /d %PARENT_DIR%venv\Scripts

:: Activate the Python virtual environment
call activate

:: Run the FastAPI application using the parent directory path
python %PARENT_DIR%app/app.py

:: Pause the terminal to view logs after the script ends
pause
