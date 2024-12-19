@echo off
REM Change to the directory where this batch script is located
cd /d %~dp0

REM Activate the virtual environment
call venv\Scripts\activate

REM Open a new Command Prompt
cmd