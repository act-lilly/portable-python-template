@echo off
REM Change to the directory where this batch script is located
cd /d %~dp0

REM Change to the Scripts directory inside the virtual environment
cd venv\Scripts

REM Activate the virtual environment
call activate

REM Open a new Command Prompt
cmd