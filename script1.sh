#!/bin/bash

# ===== SETUP =====
# Define password variable
PASSWORD='admin12345'

# Set APT to non-interactive mode (avoid GUI or pink screens)
export DEBIAN_FRONTEND=noninteractive

# Optional: Pre-accept license if required (usually not needed, but safe)
echo "nxwitness-server nxwitness-server/accept-eula boolean true" | sudo debconf-set-selections

# ===== DOWNLOADS =====
# Download TeamViewer
wget https://download.teamviewer.com/download/linux/teamviewer_amd64.deb

# Download Nx Witness Client (v6.0.5.41290)
wget https://updates.networkoptix.com/default/41290/linux/nxwitness-client-6.0.5.41290-linux_x64.deb

# Download Nx Witness Server (v6.0.5.41290)
wget https://updates.networkoptix.com/default/41290/linux/nxwitness-server-6.0.5.41290-linux_x64.deb

# ===== SYSTEM UPDATES =====
# Update package list
echo "$PASSWORD" | sudo -S apt-get update

# Upgrade all packages
echo "$PASSWORD" | sudo -S apt-get upgrade -y

# Install all recommended drivers
echo "$PASSWORD" | sudo -S ubuntu-drivers autoinstall

# ===== INSTALL SOFTWARE =====
# Install TeamViewer
echo "$PASSWORD" | sudo -S apt install -y ./teamviewer_amd64.deb

# Install Nx Witness Client (non-interactive)
echo "$PASSWORD" | sudo -S DEBIAN_FRONTEND=noninteractive apt install -y ./nxwitness-client-6.0.5.41290-linux_x64.deb

# Install Nx Witness Server (non-interactive)
echo "$PASSWORD" | sudo -S DEBIAN_FRONTEND=noninteractive apt install -y ./nxwitness-server-6.0.5.41290-linux_x64.deb

# ===== DISPLAY SERVER CONFIG =====
# Uncomment WaylandEnable in GDM config
echo "$PASSWORD" | sudo -S sed -i 's/^#\s*WaylandEnable=false/WaylandEnable=false/' /etc/gdm3/custom.conf

# Confirm it was applied
grep '^WaylandEnable=' /etc/gdm3/custom.conf

# ===== GNOME UX TWEAKS =====
# Disable notifications
gsettings set org.gnome.desktop.notifications show-banners false
gsettings set org.gnome.desktop.notifications show-in-lock-screen false

# Prevent suspend
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'

# Disable screen blanking / power save
gsettings set org.gnome.desktop.session idle-delay 0
gsettings set org.gnome.desktop.screensaver lock-enabled false
gsettings set org.gnome.desktop.screensaver idle-activation-enabled false

# Enable dark mode
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'

# ===== PRIVACY / SCREEN LOCK =====
# Never lock screen automatically
gsettings set org.gnome.desktop.screensaver lock-delay 0
gsettings set org.gnome.desktop.lockdown disable-lock-screen true
gsettings set org.gnome.desktop.lockdown disable-user-switching true

# Disable screen lock when idle
gsettings set org.gnome.desktop.privacy report-technical-problems false
gsettings set org.gnome.desktop.privacy remember-recent-files false
gsettings set org.gnome.desktop.privacy send-software-usage-stats false
gsettings set org.gnome.desktop.privacy old-files-age 0
gsettings set org.gnome.desktop.privacy recent-files-max-age 0

# ===== DISABLE AUTO UPDATES =====
# Stop APT from checking for updates automatically
echo "$PASSWORD" | sudo -S sed -i 's/APT::Periodic::Update-Package-Lists "1";/APT::Periodic::Update-Package-Lists "0";/' /etc/apt/apt.conf.d/20auto-upgrades
echo "$PASSWORD" | sudo -S sed -i 's/APT::Periodic::Download-Upgradeable-Packages "1";/APT::Periodic::Download-Upgradeable-Packages "0";/' /etc/apt/apt.conf.d/20auto-upgrades
echo "$PASSWORD" | sudo -S sed -i 's/APT::Periodic::AutocleanInterval "1";/APT::Periodic::AutocleanInterval "0";/' /etc/apt/apt.conf.d/10periodic

# Disable unattended-upgrades
echo "$PASSWORD" | sudo -S systemctl stop unattended-upgrades
echo "$PASSWORD" | sudo -S systemctl disable unattended-upgrades

# Disable GNOME Software auto-updates (GUI)
gsettings set org.gnome.software download-updates false
gsettings set org.gnome.software allow-updates false
