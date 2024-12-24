#!/bin/sh

# This script installs portable Git, Python, Pip and optionally Poetry + any dependencies,
# *without* creating a dedicated virtual environment. Everything is installed directly into
# the embeddable Python’s site-packages. Target is Windows. Run via busybox.exe.

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

# (Optional) local directory if you want to store any local wheels, logs, etc.
CACHE_DIR="$(pwd)/python_cache"

##############################################################################
# 3. Environment for isolation & no cache
##############################################################################
export PIP_CONFIG_FILE=NUL        # ignore any global pip config
export PIP_NO_CACHE_DIR=1         # fully disable pip caching

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
# 6. Ensure pip is installed in embeddable Python
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
# 8. Upgrade pip/setuptools/wheel in the embeddable Python
##############################################################################
echo "Upgrading pip/setuptools/wheel..."
if "$PYTHON_EXE" -m ensurepip --help >/dev/null 2>&1; then
    "$PYTHON_EXE" -m ensurepip --upgrade
else
    "$PYTHON_EXE" -m pip install --upgrade pip setuptools wheel
fi

echo "Current pip version:"
"$PYTHON_EXE" -m pip --version

##############################################################################
# 9. Install dependencies if present (requirements.txt)
##############################################################################
if [ -f "$PIP_REQUIREMENTS_FILE" ]; then
    echo "Installing dependencies from $PIP_REQUIREMENTS_FILE..."
    "$PYTHON_EXE" -m pip install -r "$PIP_REQUIREMENTS_FILE"
else
    echo "No $PIP_REQUIREMENTS_FILE found. Skipping dependencies."
fi

##############################################################################
# 10. (Optional) Install Poetry if pyproject.toml is present
##############################################################################
export POETRY_HOME="$(pwd)/.poetry_home"
export POETRY_CACHE_DIR="$(pwd)/.poetry_cache"
# We’ll let Poetry install into the global (embeddable) environment instead of creating its own venv.
export POETRY_VIRTUALENVS_CREATE=false

if [ -f "$POETRY_TOML_FILE" ]; then
    echo "Installing Poetry & installing dependencies from $POETRY_TOML_FILE..."
    "$PYTHON_EXE" -m pip install poetry
    poetry config virtualenvs.create false
    poetry config cache-dir "$POETRY_CACHE_DIR"
    poetry install
else
    echo "No $POETRY_TOML_FILE found. Skipping Poetry."
fi

##############################################################################
# 11. Done
##############################################################################
echo "Setup complete! You can now use Python via: $PYTHON_EXE"
echo "Packages are installed directly in the embeddable Python environment."