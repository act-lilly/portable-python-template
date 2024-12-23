# portable-python-template
Windows template for portable python with pip

# Overview

This template can be run from Windows without leaving a trace. Python does not need to be installed. Standard User account type will work; account does not need to be an Administrator.

It's meant for quick iteration and testing of apps or new libraries. This can also be used quickly to set up and run an API layer for any need. My primary use is for quick development of FastAPI applications.

Another benefit is that the parent directory can be shared (zip, etc) with anyone, and all they have to do is extract and run the app.

No installs required, no virtualization, no containerization.

👉 **Just files**.

## How it works
1. Setup Script (.bat & .sh)
   - Run to download and extract embeddable/portable python, portable pip and portable Git
   - Once Python and Pip are configured, it will create a virtual environment (venv)
   - Within the venv, it will install any dependencies.
     - It looks for requirements (pip) and toml files (poetry)
     - These file names can be specified in the .env file
   - Note about setup.bat. It will download busybox.exe and then run setup.sh using busybox.
     - About busybox: https://www.busybox.net/about.html
     - About busybox Windows executable: https://frippery.org/busybox/
  
2. Run App Script (.bat)
   - A simple 'hello world' FastAPI app is provided. These scripts run it. Adjust as needed.
   - app/app.py

3. Config Files
   - .env file
     - set python version, git version and file names (if any) for pip and poetry installs
   - requirements.txt
     - add your pip dependencies
     - fastapi[all] and uvicorn are included as defaults
   - pyproject.toml
     - sample file for poetry dependencies
    
4. Extras
   - activate_virtualenv.bat
     - Open new CMD with venv activated for interactive exploration of the virtual environment
   - install_notepad.bat
     - Have a portable version of Notepad++ ready in a few seconds
     - Useful if using Windows Sandbox feature (temp Windows environment)
       - "Windows Sandbox provides a lightweight desktop environment to safely run applications in isolation. Software installed inside the Windows Sandbox environment remains "sandboxed" and runs separately from the host machine."
       - Read more about Windows Sandbox: https://learn.microsoft.com/en-us/windows/security/application-security/application-isolation/windows-sandbox/windows-sandbox-overview
     - Otherwise, may conflict with any existing install of Notepad++ on your machine
     - Repo: https://github.com/notepad-plus-plus
   - install_winmerge.bat
     - Have a portable version of this popular differencing and merging tool
     - Repo: https://github.com/WinMerge/winmerge
