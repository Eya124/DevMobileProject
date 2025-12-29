#!/bin/bash

# Update package list
echo "Updating package list..."
sudo apt update

# Install MySQL server
echo "Installing MySQL server..."
sudo apt install -y mysql-server

# Install MySQL client (added to script)
echo "Installing MySQL client..."
sudo apt install -y mysql-client

# Install Python 3 and pip for Python 3
echo "Installing Python 3 and pip..."
sudo apt install -y python3 python3-pip

# Install Redis server
echo "Installing Redis server..."
sudo apt install -y redis-server

# Enable Redis to start on boot
echo "Enabling Redis server to start on boot..."
sudo systemctl enable redis-server

# Start Redis server
echo "Starting Redis server..."
sudo systemctl start redis-server

# Install Node.js and npm (latest version)
echo "Installing Node.js and npm..."

# Install prerequisites for Node.js setup
sudo apt install -y curl gnupg2 lsb-release

# Add NodeSource repository for Node.js (LTS version, or use the version you need)
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -

# Install Node.js (which will also install npm)
sudo apt install -y nodejs

# Verify Node.js and npm installation
echo "Verifying Node.js installation..."
node -v

echo "Verifying npm installation..."
npm -v

# Verify MySQL installation
echo "Verifying MySQL installation..."
mysql --version

# Verify MySQL client installation
echo "Verifying MySQL client installation..."
mysql --version

# Verify Python 3 installation
echo "Verifying Python 3 installation..."
python3 --version

# Verify pip installation
echo "Verifying pip installation..."
pip3 --version

# Verify Redis installation
echo "Verifying Redis installation..."
redis-server --version

echo "All services installed successfully!"
