#!/bin/sh

# This script installs portable Git, Python, Pip and sets up Venv with additional dependencies installed (e.g. pip, poetry).
# Target is only Windows platform. Run this script with busybox.exe. See setup.bat for details.

##############################################################################
# 1. Exit on error, load .env
##############################################################################
set -e

if [ -f "$PWD/.env" ]; then
    echo "Loading environment variables from .env..."
    . "$PWD/.env" || true
fi

##############################################################################
# 2. Default versions / variables
##############################################################################
PYTHON_VERSION="${PYTHON_VERSION:-3.11.5}"
GIT_VERSION="${GIT_VERSION:-2.45.0}"

PIP_REQUIREMENTS_FILE="${PIP_REQUIREMENTS_FILE:-requirements.txt}"
POETRY_TOML_FILE="${POETRY_TOML_FILE:-pyproject.toml}"

PYTHON_EMBED_URL="https://www.python.org/ftp/python/${PYTHON_VERSION}/python-${PYTHON_VERSION}-embed-amd64.zip"
PIP_URL="https://bootstrap.pypa.io/get-pip.py"
GIT_WINDOWS_URL="https://github.com/git-for-windows/git/releases/download/v${GIT_VERSION}.windows.1/MinGit-${GIT_VERSION}-64-bit.zip"

PYTHON_DIR="python_embeddable"
GIT_DIR="git_embeddable"
VENV_DIR="venv"
PYTHON_USER_BASE="$(pwd)/python_user_base"

# (Optional) local directory if you want to store any local wheels, logs, etc.
CACHE_DIR="$(pwd)/venv_cache"

##############################################################################
# 3. Environment for isolation & no cache
##############################################################################
export PIP_CONFIG_FILE=NUL        # ignore any global pip config
export PIP_NO_CACHE_DIR=1         # fully disable pip caching
export PYTHONUSERBASE="$PYTHON_USER_BASE"

# Add Python + Git to PATH for current shell
export PATH="$(pwd)/$PYTHON_DIR;$(pwd)/$PYTHON_DIR/Scripts;$(pwd)/$GIT_DIR/cmd;$PATH"

##############################################################################
# 4. Download + unzip helper
##############################################################################
download_and_extract() {
    local url="$1"
    local dest_dir="$2"
    local archive_name="$(basename "$url")"

    echo "Downloading $url..."
    curl -L -o "$archive_name" "$url"

    echo "Extracting $archive_name to $dest_dir..."
    unzip -d "$dest_dir" "$archive_name"

    rm "$archive_name"
}

##############################################################################
# 5. Setup embeddable Python (if not already)
##############################################################################
mkdir -p "$PYTHON_DIR"
PYTHON_EXE="$PYTHON_DIR/python.exe"

if [ ! -f "$PYTHON_EXE" ]; then
    echo "Setting up embeddable Python in $PYTHON_DIR..."
    download_and_extract "$PYTHON_EMBED_URL" "$PYTHON_DIR"

    PYTHON_MAJOR_MINOR="$(echo "$PYTHON_VERSION" | awk -F. '{print $1$2}')"
    PTH_FILE="$PYTHON_DIR/python${PYTHON_MAJOR_MINOR}._pth"
    if [ -f "$PTH_FILE" ]; then
        echo "Lib" >> "$PTH_FILE"
        echo "site-packages" >> "$PTH_FILE"
        echo "import site" >> "$PTH_FILE"
    else
        echo "Error: .pth file not found at $PTH_FILE"
        exit 1
    fi
else
    echo "Python already configured at $PYTHON_EXE"
fi

##############################################################################
# 6. Ensure pip is installed globally in the embeddable Python
##############################################################################
if ! "$PYTHON_EXE" -m pip --version >/dev/null 2>&1; then
    echo "Installing pip into embeddable Python..."
    curl -L -o get-pip.py "$PIP_URL"
    "$PYTHON_EXE" get-pip.py --no-warn-script-location
    rm get-pip.py
else
    echo "pip is already installed in embeddable Python."
fi

##############################################################################
# 7. Setup portable Git if needed
##############################################################################
mkdir -p "$GIT_DIR"
if [ ! -f "$GIT_DIR/cmd/git.exe" ]; then
    echo "Setting up portable Git..."
    download_and_extract "$GIT_WINDOWS_URL" "$GIT_DIR"
else
    echo "Portable Git is already set up."
fi

##############################################################################
# 8. Install virtualenv (no cache) in embeddable Python
##############################################################################
"$PYTHON_EXE" -m pip install --no-cache-dir --upgrade virtualenv

##############################################################################
# 9. Create venv WITHOUT seeding from AppData
##############################################################################
if [ ! -d "$VENV_DIR" ]; then
    echo "Creating a fresh virtual environment at $VENV_DIR (no-seed)..."
    "$PYTHON_EXE" -m virtualenv --no-seed "$VENV_DIR"
else
    echo "Virtual environment already exists at $VENV_DIR"
fi

##############################################################################
# 10. Activate venv and manually install pip/setuptools/wheel
##############################################################################
. "$VENV_DIR/Scripts/activate"

echo "Verifying Python version in venv..."
python --version || true

echo "Attempting to install pip/setuptools/wheel from scratch..."
# If ensurepip is available, do:
if "$PYTHON_EXE" -m ensurepip --help >/dev/null 2>&1; then
    "$PYTHON_EXE" -m ensurepip --upgrade
else
    # Fallback: manually install pip/setuptools/wheel
    pip install --no-cache-dir --upgrade pip setuptools wheel
fi

echo "Now pip version in venv is:"
pip --version

##############################################################################
# 11. Install dependencies if present
##############################################################################
if [ -f "$PIP_REQUIREMENTS_FILE" ]; then
    echo "Installing dependencies from $PIP_REQUIREMENTS_FILE..."
    pip install --no-cache-dir -r "$PIP_REQUIREMENTS_FILE"
else
    echo "No $PIP_REQUIREMENTS_FILE found. Skipping dependencies."
fi

# --- NEW: Set Poetry environment variables before installing Poetry ---
export POETRY_HOME="$(pwd)/.poetry_home"
export POETRY_CACHE_DIR="$(pwd)/.poetry_cache"
export POETRY_VIRTUALENVS_CREATE=false

if [ -f "$POETRY_TOML_FILE" ]; then
    echo "Installing Poetry & dependencies from $POETRY_TOML_FILE..."
    pip install --no-cache-dir poetry

    poetry config virtualenvs.create false
    poetry config cache-dir "$POETRY_CACHE_DIR"
    poetry install
else
    echo "No $POETRY_TOML_FILE found. Skipping Poetry."
fi

##############################################################################
# 12. Deactivate & done
##############################################################################
deactivate
echo "Setup complete. Venv is located at: $VENV_DIR"
