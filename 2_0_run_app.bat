@echo off

:: Change to the directory where this batch script is located
cd /d %~dp0

:: Add venv/Scripts to the PATH environment variable temporarily
set PATH=%~dp0venv\Scripts;%PATH%

:: Activate the Python virtual environment
call venv\Scripts\activate

:: Run the FastAPI application
python app/app.py

:: Pause the terminal to view logs after the script ends
pause
