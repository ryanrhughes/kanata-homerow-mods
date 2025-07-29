#!/bin/bash

# Kanata homerow mods installation script

set -e

echo "Installing kanata homerow mods configuration..."

# Install kanata if not already installed
if ! command -v kanata &> /dev/null; then
    echo "Installing kanata..."
    # For Arch Linux, install from AUR
    if command -v yay &> /dev/null; then
        yay -S kanata
    elif command -v paru &> /dev/null; then
        paru -S kanata
    else
        echo "Please install kanata manually from AUR"
        exit 1
    fi
else
    echo "Kanata is already installed"
fi

# Check if user is in input group
if ! groups | grep -q "\binput\b"; then
    echo "Adding $USER to input group for device access..."
    sudo usermod -aG input "$USER"
    echo "IMPORTANT: You need to log out and back in for group changes to take effect!"
    echo "After logging back in, run this script again."
    exit 0
fi

# Create config directory
mkdir -p "$HOME/.config/kanata"

# Copy kbd file to config location
echo "Copying kanata configuration..."
cp kanata-homerow-mods.kbd "$HOME/.config/kanata/homerow-mods.kbd"

# Create systemd user directory
mkdir -p "$HOME/.config/systemd/user"

# Generate systemd service file with correct paths
echo "Creating systemd service..."
cat > "$HOME/.config/systemd/user/kanata.service" << EOF
[Unit]
Description=Kanata keyboard remapper
Documentation=https://github.com/jtroo/kanata
After=graphical-session.target

[Service]
Type=simple
Environment=DISPLAY=:0
ExecStart=/usr/bin/kanata -c $HOME/.config/kanata/homerow-mods.kbd
Restart=always
RestartSec=3

# Optional: For better performance
Nice=-20

[Install]
WantedBy=default.target
EOF

# Reload systemd daemon
echo "Reloading systemd..."
systemctl --user daemon-reload

# Enable and start the service
echo "Enabling kanata service..."
systemctl --user enable kanata.service

echo "Starting kanata service..."
systemctl --user start kanata.service

# Check service status
echo ""
echo "Checking service status..."
systemctl --user status kanata.service --no-pager

echo ""
echo "Installation complete!"
echo "Kanata configuration: $HOME/.config/kanata/homerow-mods.kbd"
echo "Service file: $HOME/.config/systemd/user/kanata.service"
echo ""
echo "Useful commands:"
echo "  systemctl --user status kanata    # Check status"
echo "  systemctl --user restart kanata   # Restart service"
echo "  systemctl --user stop kanata      # Stop service"
echo "  journalctl --user -u kanata -f    # View logs"