#!/bin/bash

# Activate the Python virtual environment 
if [ -d "venv/bin" ]; then
  source venv/bin/activate
else
  echo "Virtual environment not found. Please set it up using the setup script."
  exit 1
fi

# Run the FastAPI application, host and port will be managed by app.py
python app/app.py

# Keep the terminal open to view logs (optional, depends on your terminal behavior)
read -p "Press [Enter] to exit..."