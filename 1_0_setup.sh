#!/bin/sh

# This script sets up a Python and Git environment for cross-platform usage.
# It detects the platform, downloads required binaries or source code, 
# and configures the environment. 

# Exit the script on any error
set -e

# Safely load environment variables from .env file
if [ -f "$PWD/.env" ]; then
    echo "Loading environment variables from .env..."
    . "$PWD/.env" || true
fi

# Set default versions for Python and Git if not provided in the environment
PYTHON_VERSION="${PYTHON_VERSION:-3.11.5}"
GIT_VERSION="${GIT_VERSION:-2.45.0}"

# Check if the .env variables are set; fallback to defaults if not
PIP_REQUIREMENTS_FILE="${PIP_REQUIREMENTS_FILE:-requirements.txt}"
POETRY_TOML_FILE="${POETRY_TOML_FILE:-pyproject.toml}"

# Define URLs for downloading Python and Git binaries or source code
PYTHON_EMBED_URL="https://www.python.org/ftp/python/${PYTHON_VERSION}/python-${PYTHON_VERSION}-embed-amd64.zip"
PYTHON_TARBALL_URL="https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz"
PIP_URL="https://bootstrap.pypa.io/get-pip.py"
GIT_WINDOWS_URL="https://github.com/git-for-windows/git/releases/download/v${GIT_VERSION}.windows.1/MinGit-${GIT_VERSION}-64-bit.zip"
GIT_TARBALL_URL="https://mirrors.edge.kernel.org/pub/software/scm/git/git-${GIT_VERSION}.tar.gz"

# Define directories for Python and Git installation
PYTHON_DIR="python_embeddable"
GIT_DIR="git_embeddable"
VENV_DIR="venv"
REQUIREMENTS_FILE="requirements.txt"
PYPROJECT_FILE="pyproject.toml"

# Function to detect the operating system platform
# Returns one of: "Linux", "Mac", "Windows", or "Unknown"
detect_platform() {
    uname_out="$(uname -s)"
    case "${uname_out}" in
        Linux*)     platform="Linux";;
        Darwin*)    platform="Mac";;
        MINGW*|MSYS*|CYGWIN*|Windows_NT) platform="Windows";;
        *)          platform="Unknown";;
    esac
    echo "${platform}"
}

# Detect and store the current platform
platform=$(detect_platform)
echo "Detected platform: $platform"

# Define the Python executable path based on the platform
if [ "$platform" = "Windows" ]; then
    PYTHON_EXECUTABLE="$PYTHON_DIR/python.exe"
else
    PYTHON_EXECUTABLE="$PYTHON_DIR/bin/python3"
fi

# Function to download and extract an archive
# Arguments:
#   1. URL of the file to download
#   2. Destination directory for extracted contents
download_and_extract() {
    url=$1
    dest_dir=$2
    archive_name=$(basename "$url")

    echo "Downloading $url..."
    curl -L -o "$archive_name" "$url"

    # Determine the file type and extract accordingly
    if echo "$archive_name" | grep -q ".zip$"; then
        echo "Extracting $archive_name to $dest_dir..."
        busybox unzip -d "$dest_dir" "$archive_name"
    elif echo "$archive_name" | grep -q ".tgz$"; then
        echo "Extracting $archive_name to $dest_dir..."
        tar -xzf "$archive_name" -C "$dest_dir" --strip-components=1
    fi

    # Clean up the archive file
    rm "$archive_name"
}

activate_virtualenv() {
    # Function to activate a Python virtual environment based on the platform
    # Arguments:
    #   $1 - Path to the virtual environment directory (VENV_DIR)
    #   $2 - Platform (e.g., "Windows" for Windows systems, anything else for Unix-based systems)

    local VENV_DIR="$1"   # Virtual environment directory
    local platform="$2"   # Platform identifier

    # Check if both arguments are provided
    if [ -z "$VENV_DIR" ] || [ -z "$platform" ]; then
        echo "Usage: activate_virtualenv <VENV_DIR> <platform>"
        return 1
    fi

    # Activate the virtual environment based on the platform
    if [ "$platform" = "Windows" ]; then
        source "$VENV_DIR/Scripts/activate"  # Windows activation script
    else
        source "$VENV_DIR/bin/activate"      # Unix-based activation script
    fi
}

# Create directories for Python and Git
mkdir -p "$PYTHON_DIR" "$GIT_DIR"

# Platform-specific setup logic
if [ "$platform" = "Windows" ]; then
    echo "Running on Windows using BusyBox..."

    # Extract major and minor version numbers from Python version
    PYTHON_MAJOR_MINOR=$(echo "$PYTHON_VERSION" | awk -F. '{print $1$2}')

    # Set up Python if not already configured
    if [ ! -f "$PYTHON_EXECUTABLE" ]; then
        echo "Setting up embeddable Python..."
        download_and_extract "$PYTHON_EMBED_URL" "$PYTHON_DIR"

        # Update the .pth file to include necessary directories
        PTH_FILE="$PYTHON_DIR/python${PYTHON_MAJOR_MINOR}._pth"
        if [ ! -f "$PTH_FILE" ]; then
            echo "Error: .pth file not found at $PTH_FILE"
            exit 1
        fi

        echo "Lib" >> "$PTH_FILE"
        echo "site-packages" >> "$PTH_FILE"
        echo "import site" >> "$PTH_FILE"
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
    export PATH="$(pwd)/$PYTHON_DIR;$(pwd)/$PYTHON_DIR/Scripts:$(pwd)/$GIT_DIR/cmd:$PATH"

else
    echo "Running on $platform..."

    # Set up Python from source if not already configured
    if [ ! -f "$PYTHON_EXECUTABLE" ]; then
        echo "Setting up Python from source..."
        download_and_extract "$PYTHON_TARBALL_URL" "$PYTHON_DIR"
        cd "$PYTHON_DIR"
        ./configure --prefix="$(pwd)" && make && make install
        cd ..
    fi

    # Install pip if not already installed
    if ! "$PYTHON_EXECUTABLE" -m pip --version >/dev/null 2>&1; then
        echo "Installing pip..."
        curl -L -o get-pip.py "$PIP_URL"
        "$PYTHON_EXECUTABLE" get-pip.py
        rm get-pip.py
    fi

    # Set up Git from source if not already configured
    if [ ! -f "$GIT_DIR/bin/git" ]; then
        echo "Setting up Git from source..."
        download_and_extract "$GIT_TARBALL_URL" "$GIT_DIR"
    fi

    # Add Python and Git to the PATH environment variable
    export PATH="$(pwd)/$PYTHON_DIR/bin:$(pwd)/$GIT_DIR/bin:$PATH"
fi

# Create a virtual environment (common for all platforms) using pip
if [ ! -d "$VENV_DIR" ]; then
    echo "Creating a virtual environment using pip..."
    "$PYTHON_EXECUTABLE" -m pip install --user virtualenv
    "$PYTHON_EXECUTABLE" -m virtualenv "$VENV_DIR"
    echo "Virtual environment created at $VENV_DIR"
else
    echo "Virtual environment already exists at $VENV_DIR"
fi

###############################################
# Verify the virtual environment functionality
echo "Verifying virtual environment..."

# Activate virtual environment and test
activate_virtualenv "$VENV_DIR" "$platform"

# Check Python version
echo "Python version in virtual environment:"
python --version

# Check pip version
echo "pip version in virtual environment:"
pip --version

# Install a test package (e.g., requests) and verify
pip install requests
echo "Installed packages in virtual environment:"
pip list

# Install Poetry
pip install poetry
if [ $? -eq 0 ]; then
    echo "Poetry successfully installed."
else
    echo "Failed to install Poetry."
    exit 1
fi

#Install dependencies. Check for pip and poetry files in env file or with default file names.
if [ -f "$PIP_REQUIREMENTS_FILE" ]; then
    echo "Installing dependencies from $PIP_REQUIREMENTS_FILE..."
    pip install -r "$PIP_REQUIREMENTS_FILE"
else
    echo "No $PIP_REQUIREMENTS_FILE found. Skipping installation of requirements."
fi

# Check if the specified TOML file exists and install its dependencies
if [ -f "$POETRY_TOML_FILE" ]; then
    echo "Installing dependencies from $POETRY_TOML_FILE using Poetry..."
    poetry install
    if [ $? -eq 0 ]; then
        echo "Dependencies successfully installed from $POETRY_TOML_FILE."
    else
        echo "Failed to install dependencies from $POETRY_TOML_FILE."
        exit 1
    fi
else
    echo "No $POETRY_TOML_FILE found. Skipping Poetry installation."
fi

# Deactivate the virtual environment
deactivate

echo "Virtual environment verification complete."