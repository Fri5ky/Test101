#!/bin/bash
# VER.2 - Combined System Setup and Drive Configuration Script

# ===== SETUP =====
PASSWORD='admin12345'
export DEBIAN_FRONTEND=noninteractive

# Updated user detection method
LOGGED_IN_USER=$(whoami)
USER_ID=$(id -u "$LOGGED_IN_USER")
USER_HOME=$(eval echo "~$LOGGED_IN_USER")

if [ -z "$LOGGED_IN_USER" ]; then
    echo "ERROR: Could not determine logged-in user"
    exit 1
fi


# Accept EULA for Nx Witness Server
echo "nxwitness-server nxwitness-server/accept-eula boolean true" | sudo debconf-set-selections

# ===== SYSTEM SETUP =====
echo "$PASSWORD" | sudo -S apt-get update
echo "$PASSWORD" | sudo -S apt-get upgrade -y
echo "$PASSWORD" | sudo -S ubuntu-drivers autoinstall

# Install required packages
echo "$PASSWORD" | sudo -S apt install -y dbus-x11 dconf-cli gsettings-desktop-schemas gnome-settings-daemon gnome-software cmatrix

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

# ===== DISPLAY SERVER CONFIG =====
echo "$PASSWORD" | sudo -S sed -i 's/^#\s*WaylandEnable=false/WaylandEnable=false/' /etc/gdm3/custom.conf
grep '^WaylandEnable=' /etc/gdm3/custom.conf

# ===== SET POWER PROFILE TO HIGH PERFORMANCE =====
if command -v powerprofilesctl &> /dev/null; then
    powerprofilesctl set performance
fi

# ===== POWER SETTINGS =====
sudo -u "$LOGGED_IN_USER" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$USER_ID/bus" \
gsettings set org.gnome.settings-daemon.plugins.power idle-dim false
sudo -u "$LOGGED_IN_USER" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$USER_ID/bus" \
gsettings set org.gnome.settings-daemon.plugins.power idle-brightness 100
sudo -u "$LOGGED_IN_USER" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$USER_ID/bus" \
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'
sudo -u "$LOGGED_IN_USER" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$USER_ID/bus" \
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout 3600
sudo -u "$LOGGED_IN_USER" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$USER_ID/bus" \
gsettings set org.gnome.settings-daemon.plugins.power lid-close-ac-action 'nothing'
sudo -u "$LOGGED_IN_USER" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$USER_ID/bus" \
gsettings set org.gnome.settings-daemon.plugins.power lid-close-battery-action 'nothing'
sudo -u "$LOGGED_IN_USER" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$USER_ID/bus" \
gsettings set org.gnome.settings-daemon.plugins.power power-button-action 'nothing'

# ===== GNOME UX TWEAKS =====
sudo -u "$LOGGED_IN_USER" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$USER_ID/bus" \
gsettings set org.gnome.desktop.notifications show-banners false
sudo -u "$LOGGED_IN_USER" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$USER_ID/bus" \
gsettings set org.gnome.desktop.notifications show-in-lock-screen false
sudo -u "$LOGGED_IN_USER" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$USER_ID/bus" \
gsettings set org.gnome.desktop.session idle-delay 0
sudo -u "$LOGGED_IN_USER" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$USER_ID/bus" \
gsettings set org.gnome.desktop.screensaver lock-enabled false
sudo -u "$LOGGED_IN_USER" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$USER_ID/bus" \
gsettings set org.gnome.desktop.screensaver idle-activation-enabled false
sudo -u "$LOGGED_IN_USER" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$USER_ID/bus" \
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
sudo -u "$LOGGED_IN_USER" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$USER_ID/bus" \
gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'
sudo -u "$LOGGED_IN_USER" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$USER_ID/bus" \
gsettings set org.gnome.desktop.screensaver lock-delay 0
sudo -u "$LOGGED_IN_USER" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$USER_ID/bus" \
gsettings set org.gnome.desktop.lockdown disable-lock-screen true
sudo -u "$LOGGED_IN_USER" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$USER_ID/bus" \
gsettings set org.gnome.desktop.lockdown disable-user-switching true
sudo -u "$LOGGED_IN_USER" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$USER_ID/bus" \
gsettings set org.gnome.desktop.privacy report-technical-problems false
sudo -u "$LOGGED_IN_USER" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$USER_ID/bus" \
gsettings set org.gnome.desktop.privacy remember-recent-files false
sudo -u "$LOGGED_IN_USER" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$USER_ID/bus" \
gsettings set org.gnome.desktop.privacy send-software-usage-stats false
sudo -u "$LOGGED_IN_USER" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$USER_ID/bus" \
gsettings set org.gnome.desktop.privacy old-files-age 0
sudo -u "$LOGGED_IN_USER" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$USER_ID/bus" \
gsettings set org.gnome.desktop.privacy recent-files-max-age 0

# ===== WALLPAPER CONFIGURATION =====
echo "Configuring wallpaper and profile picture..."

# Create Pictures directory if it doesn't exist
mkdir -p "$USER_HOME/Pictures"

# Download the wallpaper (force overwrite if exists)
wget -O "$USER_HOME/Pictures/w.png" http://10.247.43.131/w.png

# Set as GNOME wallpaper
sudo -u "$LOGGED_IN_USER" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$USER_ID/bus" \
gsettings set org.gnome.desktop.background picture-uri "file://$USER_HOME/Pictures/w.png"
sudo -u "$LOGGED_IN_USER" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$USER_ID/bus" \
gsettings set org.gnome.desktop.background picture-uri-dark "file://$USER_HOME/Pictures/w.png"

# Set as user profile picture
sudo mkdir -p /var/lib/AccountsService/icons/
sudo cp "$USER_HOME/Pictures/w.png" "/var/lib/AccountsService/icons/$LOGGED_IN_USER"
sudo chmod 644 "/var/lib/AccountsService/icons/$LOGGED_IN_USER"

# Update AccountsService config
USER_FILE="/var/lib/AccountsService/users/$LOGGED_IN_USER"
sudo mkdir -p /var/lib/AccountsService/users/
if [ -f "$USER_FILE" ]; then
    sudo grep -q "^Icon=" "$USER_FILE" && \
    sudo sed -i "s|^Icon=.*|Icon=/var/lib/AccountsService/icons/$LOGGED_IN_USER|" "$USER_FILE" || \
    echo "Icon=/var/lib/AccountsService/icons/$LOGGED_IN_USER" | sudo tee -a "$USER_FILE" >/dev/null
else
    echo "[User]" | sudo tee "$USER_FILE" >/dev/null
    echo "Icon=/var/lib/AccountsService/icons/$LOGGED_IN_USER" | sudo tee -a "$USER_FILE" >/dev/null
fi

# Restart services to apply changes
sudo systemctl restart accounts-daemon

# ===== SET FAVORITE APPS =====
echo "Configuring favorite apps..."

FAVORITE_APPS=(
    'org.gnome.Nautilus.desktop'
    'org.gnome.Terminal.desktop'
    'com.teamviewer.TeamViewer.desktop'
    'nxwitness.desktop'
)

# Prepare the favorites array in correct format
FAVORITES_STRING="["
for app in "${FAVORITE_APPS[@]}"; do
    # Check if application exists in standard locations
    if [ -f "/usr/share/applications/$app" ] || [ -L "/usr/share/applications/$app" ]; then
        FAVORITES_STRING+="'$app', "
        echo "Adding to favorites: $app"
    else
        echo "Warning: $app not found in standard locations"
    fi
done
FAVORITES_STRING="${FAVORITES_STRING%, }]"

# Set the favorites using the proper environment
sudo -H -u "$LOGGED_IN_USER" bash -c "
    export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$USER_ID/bus
    gsettings set org.gnome.shell favorite-apps \"$FAVORITES_STRING\"
"

# Verify the result
echo -e "\nCurrent favorites:"
sudo -H -u "$LOGGED_IN_USER" bash -c "
    export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$USER_ID/bus
    gsettings get org.gnome.shell favorite-apps
"

# ===== DISABLE AUTO UPDATES =====
echo "$PASSWORD" | sudo -S sed -i 's/APT::Periodic::Update-Package-Lists "1";/APT::Periodic::Update-Package-Lists "0";/' /etc/apt/apt.conf.d/20auto-upgrades
echo "$PASSWORD" | sudo -S sed -i 's/APT::Periodic::Download-Upgradeable-Packages "1";/APT::Periodic::Download-Upgradeable-Packages "0";/' /etc/apt/apt.conf.d/20auto-upgrades
echo "$PASSWORD" | sudo -S sed -i 's/APT::Periodic::AutocleanInterval "1";/APT::Periodic::AutocleanInterval "0";/' /etc/apt/apt.conf.d/10periodic

echo "$PASSWORD" | sudo -S systemctl stop unattended-upgrades
echo "$PASSWORD" | sudo -S systemctl disable unattended-upgrades

# ===== DRIVE CONFIGURATION =====
echo "Starting drive configuration..."

MOUNT_BASE="/mnt"

# Function to format and mount a new drive
format_and_mount_drive() {
    local DRIVE=$1
    local MOUNTPOINT=$2
    local LABEL=$3

    echo "Formatting $DRIVE as ext4..."
    sudo mkfs.ext4 -F -L "$LABEL" "$DRIVE"

    echo "Creating mount point: $MOUNTPOINT"
    sudo mkdir -p "$MOUNTPOINT"

    echo "Mounting $DRIVE to $MOUNTPOINT"
    sudo mount "$DRIVE" "$MOUNTPOINT"

    UUID=$(sudo blkid -s UUID -o value "$DRIVE")
    echo "UUID=$UUID $MOUNTPOINT ext4 defaults,x-gvfs-show 0 2" | sudo tee -a /etc/fstab > /dev/null
    echo "Drive $DRIVE mounted and labeled $LABEL, added to fstab."
}

# Function to mount an already formatted drive and set label
mount_formatted_drive() {
    local DRIVE=$1
    local MOUNTPOINT=$2
    local FSTYPE=$3
    local LABEL=$4

    echo "Creating mount point: $MOUNTPOINT"
    sudo mkdir -p "$MOUNTPOINT"

    echo "Mounting $DRIVE ($FSTYPE) to $MOUNTPOINT"
    sudo mount "$DRIVE" "$MOUNTPOINT"

    if [ "$FSTYPE" == "ext4" ]; then
        echo "Setting label to $LABEL"
        sudo e2label "$DRIVE" "$LABEL"
    fi

    UUID=$(sudo blkid -s UUID -o value "$DRIVE")
    echo "UUID=$UUID $MOUNTPOINT $FSTYPE defaults,x-gvfs-show 0 2" | sudo tee -a /etc/fstab > /dev/null
    echo "Drive $DRIVE mounted and labeled $LABEL, added to fstab."
}

# Updated mount detection loop
INDEX=1
for DRIVE in /dev/sd? /dev/nvme?n?p?; do
    if [ ! -b "$DRIVE" ]; then
        continue
    fi

    # Skip if already mounted
    if mount | grep -q "^$DRIVE"; then
        echo "$DRIVE is already mounted. Skipping."
        continue
    fi

    FSTYPE=$(sudo blkid -o value -s TYPE "$DRIVE")
    MOUNTPOINT="$MOUNT_BASE/disk$INDEX"
    LABEL="data$INDEX"

    if [ -z "$FSTYPE" ]; then
        format_and_mount_drive "$DRIVE" "$MOUNTPOINT" "$LABEL"
    else
        mount_formatted_drive "$DRIVE" "$MOUNTPOINT" "$FSTYPE" "$LABEL"
    fi

    ((INDEX++))
done

#====MSPLUGIN========#

wget https://resource.milesight.com/milesight/security/software/Milesight_Plugin_for_Network_Optix_2.0.12-r2-linux.zip -O plugin.zip && \
unzip plugin.zip && \
cd Milesight_Plugin_for_Network_Optix_2.0.12-r2-linux && \
unzip milesight_analytics_plugin_linux.zip && \
cd milesight_analytics_plugin_linux && \
chmod +x install.sh && \
yes | sudo ./install.sh

# ===== FINAL CLEANUP =====
echo "$PASSWORD" | sudo -S apt-get -y autoremove
echo "$PASSWORD" | sudo -S apt-get -y clean
echo "$PASSWORD" | sudo -S rm -rf /var/lib/apt/lists/*
echo "$PASSWORD" | sudo -S rm -f /var/crash/*
echo "$PASSWORD" | sudo -S systemctl stop apport.service

# ===== RUN CMATRIX EFFECT =====
if command -v cmatrix &> /dev/null; then
    echo "Launching Matrix effect! Press Ctrl+C to exit."
    cmatrix
else
    echo "cmatrix is not installed."
fi

# ===== REBOOT =====
echo "✅ Setup completed successfully."
echo "Rebooting in 10 seconds... Press Ctrl+C to cancel."
sleep 10
sudo reboot
