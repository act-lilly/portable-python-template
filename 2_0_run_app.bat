@echo off

REM Capture the directory where this batch script is located
set PARENT_DIR=%~dp0

REM Prepend the embeddable Python folder to PATH
set PATH=%PARENT_DIR%python_embeddable;%PARENT_DIR%python_embeddable\Scripts;%PATH%

REM Run the FastAPI (or other) application 
python %PARENT_DIR%app\app.py

REM Pause the terminal to view logs after the script ends
pause
