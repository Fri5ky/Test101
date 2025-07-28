#!/bin/bash

# ===== SETUP =====
PASSWORD='admin12345'
export DEBIAN_FRONTEND=noninteractive

# Detect the real logged-in user (not root)
LOGGED_IN_USER=$(logname)
USER_HOME=$(eval echo "~$LOGGED_IN_USER")

# Accept EULA for Nx Witness Server
echo "nxwitness-server nxwitness-server/accept-eula boolean true" | sudo debconf-set-selections

# ===== CREATE DOWNLOADS DIRECTORY =====
mkdir -p downloads

# ===== TEAMVIEWER INSTALL =====
TEAMVIEWER_DEB="downloads/teamviewer_amd64.deb"
if [ ! -f "$TEAMVIEWER_DEB" ]; then
    wget -O "$TEAMVIEWER_DEB" https://download.teamviewer.com/download/linux/teamviewer_amd64.deb
fi
sudo apt install -y ./"$TEAMVIEWER_DEB" && rm -f "$TEAMVIEWER_DEB"

# ===== NX WITNESS CLIENT INSTALL =====
NX_CLIENT_DEB="downloads/nxwitness-client-6.0.5.41290-linux_x64.deb"
if [ ! -f "$NX_CLIENT_DEB" ]; then
    wget -O "$NX_CLIENT_DEB" https://updates.networkoptix.com/default/41290/linux/nxwitness-client-6.0.5.41290-linux_x64.deb
fi
sudo apt install -y ./"$NX_CLIENT_DEB" && rm -f "$NX_CLIENT_DEB"

# ===== NX WITNESS SERVER INSTALL =====
NX_SERVER_DEB="downloads/nxwitness-server-6.0.5.41290-linux_x64.deb"
if [ ! -f "$NX_SERVER_DEB" ]; then
    wget -O "$NX_SERVER_DEB" https://updates.networkoptix.com/default/41290/linux/nxwitness-server-6.0.5.41290-linux_x64.deb
fi
sudo apt install -y ./"$NX_SERVER_DEB" && rm -f "$NX_SERVER_DEB"

# ===== SYSTEM SETUP =====
echo "$PASSWORD" | sudo -S apt-get update
echo "$PASSWORD" | sudo -S apt-get upgrade -y
echo "$PASSWORD" | sudo -S ubuntu-drivers autoinstall

# Install required packages
echo "$PASSWORD" | sudo -S apt install -y dbus-x11 dconf-cli gsettings-desktop-schemas gnome-settings-daemon gnome-software cmatrix

# ===== DISPLAY SERVER CONFIG =====
echo "$PASSWORD" | sudo -S sed -i 's/^#\s*WaylandEnable=false/WaylandEnable=false/' /etc/gdm3/custom.conf
grep '^WaylandEnable=' /etc/gdm3/custom.conf

# ===== SET POWER PROFILE TO HIGH PERFORMANCE =====
if command -v powerprofilesctl &> /dev/null; then
    powerprofilesctl set performance
fi

# ===== POWER SETTINGS =====
gsettings set org.gnome.settings-daemon.plugins.power idle-dim false
gsettings set org.gnome.settings-daemon.plugins.power idle-brightness 100
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout 3600
gsettings set org.gnome.settings-daemon.plugins.power lid-close-ac-action 'nothing'
gsettings set org.gnome.settings-daemon.plugins.power lid-close-battery-action 'nothing'

# Disable any action on physical power button press
gsettings set org.gnome.settings-daemon.plugins.power power-button-action 'nothing'

# ===== GNOME UX TWEAKS =====
gsettings set org.gnome.desktop.notifications show-banners false
gsettings set org.gnome.desktop.notifications show-in-lock-screen false
gsettings set org.gnome.desktop.session idle-delay 0
gsettings set org.gnome.desktop.screensaver lock-enabled false
gsettings set org.gnome.desktop.screensaver idle-activation-enabled false
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'
gsettings set org.gnome.desktop.screensaver lock-delay 0
gsettings set org.gnome.desktop.lockdown disable-lock-screen true
gsettings set org.gnome.desktop.lockdown disable-user-switching true
gsettings set org.gnome.desktop.privacy report-technical-problems false
gsettings set org.gnome.desktop.privacy remember-recent-files false
gsettings set org.gnome.desktop.privacy send-software-usage-stats false
gsettings set org.gnome.desktop.privacy old-files-age 0
gsettings set org.gnome.desktop.privacy recent-files-max-age 0

# ===== DISABLE AUTO UPDATES =====
echo "$PASSWORD" | sudo -S sed -i 's/APT::Periodic::Update-Package-Lists "1";/APT::Periodic::Update-Package-Lists "0";/' /etc/apt/apt.conf.d/20auto-upgrades
echo "$PASSWORD" | sudo -S sed -i 's/APT::Periodic::Download-Upgradeable-Packages "1";/APT::Periodic::Download-Upgradeable-Packages "0";/' /etc/apt/apt.conf.d/20auto-upgrades
echo "$PASSWORD" | sudo -S sed -i 's/APT::Periodic::AutocleanInterval "1";/APT::Periodic::AutocleanInterval "0";/' /etc/apt/apt.conf.d/10periodic

echo "$PASSWORD" | sudo -S systemctl stop unattended-upgrades
echo "$PASSWORD" | sudo -S systemctl disable unattended-upgrades

# ===== RUN CMATRIX EFFECT =====
if command -v cmatrix &> /dev/null; then
    echo "Launching Matrix effect! Press Ctrl+C to exit."
    cmatrix
else
    echo "cmatrix is not installed."
fi

# ===== REBOOT =====
echo "✅ Matrix completed successfully."
echo "Rebooting in 10 seconds... Press Ctrl+C to cancel."
sleep 10
sudo reboot
