#!/bin/sh

# This script installs portable Git, Python, Pip and sets up Venv with additional dependencies installed (e.g. poetry).
# Target is only Windows platform. Run this script with busybox.exe. See setup.bat for details.

# Exit the script on any error
set -e

# Load environment variables from .env file if available
if [ -f "$PWD/.env" ]; then
    echo "Loading environment variables from .env..."
    . "$PWD/.env" || true
fi

# Set default versions for Python and Git if not provided in the environment
PYTHON_VERSION="${PYTHON_VERSION:-3.11.5}"
GIT_VERSION="${GIT_VERSION:-2.45.0}"

# Set default file paths
PIP_REQUIREMENTS_FILE="${PIP_REQUIREMENTS_FILE:-requirements.txt}"
POETRY_TOML_FILE="${POETRY_TOML_FILE:-pyproject.toml}"

# Define URLs for downloading Python and Git binaries
PYTHON_EMBED_URL="https://www.python.org/ftp/python/${PYTHON_VERSION}/python-${PYTHON_VERSION}-embed-amd64.zip"
PIP_URL="https://bootstrap.pypa.io/get-pip.py"
GIT_WINDOWS_URL="https://github.com/git-for-windows/git/releases/download/v${GIT_VERSION}.windows.1/MinGit-${GIT_VERSION}-64-bit.zip"

# Define directories for Python and Git installation
PYTHON_DIR="python_embeddable"
GIT_DIR="git_embeddable"
VENV_DIR="venv"

# Function to download and extract an archive
download_and_extract() {
    url=$1
    dest_dir=$2
    archive_name=$(basename "$url")

    echo "Downloading $url..."
    curl -L -o "$archive_name" "$url"

    echo "Extracting $archive_name to $dest_dir..."
    unzip -d "$dest_dir" "$archive_name"

    # Clean up the archive file
    rm "$archive_name"
}

# Create directories for Python and Git
mkdir -p "$PYTHON_DIR" "$GIT_DIR"

# Set up Python if not already configured
PYTHON_EXECUTABLE="$PYTHON_DIR/python.exe"
if [ ! -f "$PYTHON_EXECUTABLE" ]; then
    echo "Setting up embeddable Python..."
    download_and_extract "$PYTHON_EMBED_URL" "$PYTHON_DIR"

    # Update the .pth file to include necessary directories
    PYTHON_MAJOR_MINOR=$(echo "$PYTHON_VERSION" | awk -F. '{print $1$2}')
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
    echo "Python is already set up."
fi

# Install pip if not already installed
if ! "$PYTHON_EXECUTABLE" -m pip --version >/dev/null 2>&1; then
    echo "Installing pip..."
    curl -L -o get-pip.py "$PIP_URL"
    "$PYTHON_EXECUTABLE" get-pip.py
    rm get-pip.py
else
    echo "pip is already installed."
fi

# Set up Git if not already configured
if [ ! -f "$GIT_DIR/cmd/git.exe" ]; then
    echo "Setting up portable Git..."
    download_and_extract "$GIT_WINDOWS_URL" "$GIT_DIR"
fi

# Add Python and Git to the PATH environment variable
export PATH="$(pwd)/$PYTHON_DIR;$(pwd)/$PYTHON_DIR/Scripts;$(pwd)/$GIT_DIR/cmd;$PATH"

# Create a virtual environment if not already created
if [ ! -d "$VENV_DIR" ]; then
    echo "Creating a virtual environment using pip..."
    "$PYTHON_EXECUTABLE" -m pip install --user virtualenv
    "$PYTHON_EXECUTABLE" -m virtualenv "$VENV_DIR"
    echo "Virtual environment created at $VENV_DIR"
else
    echo "Virtual environment already exists at $VENV_DIR"
fi

# Activate the virtual environment
. "$VENV_DIR/Scripts/activate"

# Verify the setup
python --version
pip --version

# Install dependencies if requirements files are present
if [ -f "$PIP_REQUIREMENTS_FILE" ]; then
    echo "Installing dependencies from $PIP_REQUIREMENTS_FILE..."
    pip install -r "$PIP_REQUIREMENTS_FILE"
else
    echo "No $PIP_REQUIREMENTS_FILE found. Skipping installation of requirements."
fi

if [ -f "$POETRY_TOML_FILE" ]; then
    echo "Installing dependencies from $POETRY_TOML_FILE using Poetry..."
    pip install poetry
    poetry install
else
    echo "No $POETRY_TOML_FILE found. Skipping Poetry installation."
fi

# Deactivate the virtual environment
deactivate

echo "Setup complete."
