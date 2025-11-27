#!/bin/bash

# Kanata homerow mods installation script

set -e

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

echo "Installing kanata homerow mods configuration..."

# Install kanata if not already installed
if ! command -v kanata &> /dev/null; then
    echo "Installing kanata..."
    yay -S kanata
else
    echo "Kanata is already installed"
fi

# Check if user is in input group (needed to read input devices)
if ! groups | grep -q "\binput\b"; then
    echo "Adding $USER to input group for device access..."
    sudo usermod -aG input "$USER"
    NEEDS_RELOGIN=true
fi

# Setup udev rule for uinput
# We use the 'input' group because the user is already in it for reading devices
UDEV_RULE='KERNEL=="uinput", MODE="0660", GROUP="input", OPTIONS+="static_node=uinput"'
UDEV_FILE="/etc/udev/rules.d/99-kanata-uinput.rules"

echo "Configuring udev rules for /dev/uinput..."
echo "$UDEV_RULE" | sudo tee "$UDEV_FILE" > /dev/null

echo "Reloading udev rules and uinput device..."
sudo udevadm control --reload-rules
sudo modprobe -r uinput 2>/dev/null || true
sudo modprobe uinput
sudo udevadm trigger

# Verify permissions
echo "Verifying /dev/uinput permissions..."
ls -l /dev/uinput

if [ "$NEEDS_RELOGIN" = true ]; then
    echo "IMPORTANT: You need to log out and back in for input group changes to take effect!"
    
    if gum confirm "Reboot now to apply group changes?"; then
        sudo reboot
    fi
    
    echo "Please reboot manually to finish installation."
    exit 0
fi

# Create config directory
mkdir -p "$HOME/.config/kanata"

# Copy kbd file to config location
echo "Copying kanata configuration..."
cp "$SCRIPT_DIR/kanata-homerow-mods.kbd" "$HOME/.config/kanata/homerow-mods.kbd"

# Create systemd user directory
mkdir -p "$HOME/.config/systemd/user"

# Generate systemd service file
echo "Creating systemd user service..."
cat > "$HOME/.config/systemd/user/kanata.service" << EOF
[Unit]
Description=Kanata keyboard remapper
Documentation=https://github.com/jtroo/kanata
After=graphical-session.target

[Service]
Type=simple
Environment=DISPLAY=:0
ExecStart=$(command -v kanata) -c %h/.config/kanata/homerow-mods.kbd
Restart=always
RestartSec=3
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

echo "Restarting kanata service..."
systemctl --user restart kanata.service

# Check service status
echo ""
echo "Checking service status..."
systemctl --user status kanata.service --no-pager

echo ""
echo "Installation complete!"
echo "Kanata configuration: $HOME/.config/kanata/homerow-mods.kbd"
echo "Service file: $HOME/.config/systemd/user/kanata.service"
