@echo off
REM Change to the directory where this batch script is located
cd /d %~dp0

REM Prepend the embeddable Python folder to PATH
set PATH=%~dp0python_embeddable;%~dp0python_embeddable\Scripts;%PATH%

REM Open a new Command Prompt with the updated environment
cmd
