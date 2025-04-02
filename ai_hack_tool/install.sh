#!/bin/bash
# Define install location
INSTALL_DIR="/opt/wyrmai"
VENV_DIR="$INSTALL_DIR/venv"

# Ensure script is run with sudo
if [ "$(id -u)" -ne 0 ]; then
    echo "Please run as root or use sudo"
    exit 1
fi

# Install Ollama if not installed
if ! command -v ollama &> /dev/null; then
    echo "Ollama not found. Installing..."
    curl -fsSL https://ollama.com/install.sh | sh
else
    echo "Ollama is already installed."
fi

# Install required system dependencies
echo "Installing system dependencies..."
apt update && apt install -y python3 python3-venv python3-pip

# Create installation directory
mkdir -p $INSTALL_DIR
cp -r * $INSTALL_DIR
cd $INSTALL_DIR || exit 1

# Set up virtual environment
python3 -m venv $VENV_DIR
$VENV_DIR/bin/pip install --upgrade pip
$VENV_DIR/bin/pip install -r requirements.txt

# Create system-wide command
cat <<EOF > /usr/local/bin/wyrmai
#!/bin/bash
$VENV_DIR/bin/python3 $INSTALL_DIR/main.py "\$@"
EOF

chmod +x /usr/local/bin/wyrmai

# Finish installation
echo "Installation complete. You can now use 'wyrmai' from anywhere."
