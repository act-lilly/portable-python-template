@echo off

:: Activate the Python virtual environment
call venv\Scripts\activate

:: Run the FastAPI application, host and port will be managed by app.py
python app/app.py

:: Pause the terminal to view logs after the script ends
pause