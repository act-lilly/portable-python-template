@echo off

:: Change to the directory where this batch script is located
cd /d %~dp0

:: Change to the Scripts directory inside the virtual environment
cd venv\Scripts

:: Activate the Python virtual environment
call activate

:: Navigate back to the base directory where the app is located
cd ../..

:: Run the FastAPI application, host and port will be managed by app.py
python app/app.py

:: Pause the terminal to view logs after the script ends
pause