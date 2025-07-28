# Function to Setup NX Witness Storage
setup_nx_storage() {
    log "INFO" "Searching for unmounted, unformatted drives larger than 500GB..."
    log "INFO" "Searching for unmounted drives larger than 500GB..."
    AVAILABLE_DRIVES=()
    declare -A DRIVE_SIZES
    declare -A DRIVE_SIZES DRIVE_FSTYPES

    # Get the root device to exclude it
    ROOT_DEVICE=$(df / | tail -n 1 | awk '{print $1}' | sed 's/[0-9]*$//')  # e.g., /dev/sda1 -> /dev/sda

    while read -r DRIVE SIZE FSTYPE MOUNTPOINT; do
        FULL_DRIVE="/dev/$DRIVE"
        # Skip if the drive is the root device or mounted
        if [[ "$FULL_DRIVE" == "$ROOT_DEVICE" || -n "$MOUNTPOINT" ]]; then
            log "DEBUG" "Skipping $FULL_DRIVE (in use: root device or mounted at $MOUNTPOINT)"
            continue
        fi
        if [[ -z "$FSTYPE" ]]; then  # Only include unformatted drives
            SIZE_GB=$(echo "$SIZE" | awk '{print $1}' | grep -o '[0-9.]\+')
            UNIT=$(echo "$SIZE" | grep -o '[TG]')
            if [[ "$UNIT" == "T" ]]; then SIZE_GB=$(echo "$SIZE_GB * 1024" | bc); fi
            if (( $(echo "$SIZE_GB >= 500" | bc -l) )); then
                AVAILABLE_DRIVES+=("$FULL_DRIVE")
                DRIVE_SIZES["$FULL_DRIVE"]="$SIZE"
            fi
        SIZE_GB=$(echo "$SIZE" | awk '{print $1}' | grep -o '[0-9.]\+')
        UNIT=$(echo "$SIZE" | grep -o '[TG]')
        if [[ "$UNIT" == "T" ]]; then SIZE_GB=$(echo "$SIZE_GB * 1024" | bc); fi
        if (( $(echo "$SIZE_GB >= 500" | bc -l) )); then
            AVAILABLE_DRIVES+=("$FULL_DRIVE")
            DRIVE_SIZES["$FULL_DRIVE"]="$SIZE"
            DRIVE_FSTYPES["$FULL_DRIVE"]="${FSTYPE:-unformatted}"
        fi
    done < <(lsblk -dn -o NAME,SIZE,FSTYPE,MOUNTPOINT)

    if [[ ${#AVAILABLE_DRIVES[@]} -eq 0 ]]; then
        log "WARN" "No suitable drives found."
        echo "No unmounted, unformatted drives >500GB found."
        echo "No unmounted drives >500GB found."
        return
    fi

    log "INFO" "Found drives:"
    echo "----------------------------------"
    echo "  Available Drives for NX Witness "
    echo "----------------------------------"
    printf "%-5s %-15s %-10s\n" "ID" "Drive" "Size"
    echo -e "\033[34m----------------------------------\033[0m"
    echo -e "\033[34m  Available Drives for NX Witness \033[0m"
    echo -e "\033[34m----------------------------------\033[0m"
    printf "%-5s %-15s %-10s %-15s\n" "ID" "Drive" "Size" "Filesystem"
    for i in "${!AVAILABLE_DRIVES[@]}"; do
        printf "%-5s %-15s %-10s\n" "$((i+1))" "${AVAILABLE_DRIVES[$i]}" "${DRIVE_SIZES[${AVAILABLE_DRIVES[$i]}]}"
        printf "%-5s %-15s %-10s %-15s\n" "$((i+1))" "${AVAILABLE_DRIVES[$i]}" "${DRIVE_SIZES[${AVAILABLE_DRIVES[$i]}]}" "${DRIVE_FSTYPES[${AVAILABLE_DRIVES[$i]}]}"
    done
    echo "----------------------------------"
    echo -e "\033[34m----------------------------------\033[0m"

    echo "Options: 1) Format all drives, 2) Format one by one, 3) Skip"
    echo "Options: 1) Process all drives, 2) Process one by one, 3) Skip"
    read -p "Select an option [1-3]: " format_choice
    case $format_choice in
        1)
            local idx=1
            for DRIVE in "${AVAILABLE_DRIVES[@]}"; do
                format_and_mount_drive "$DRIVE" "$idx"
                process_drive "$DRIVE" "$idx" "${DRIVE_FSTYPES[$DRIVE]}"
                ((idx++))
            done
            ;;
        2)
            local idx=1
            for i in "${!AVAILABLE_DRIVES[@]}"; do
                read -p "Format ${AVAILABLE_DRIVES[$i]} (${DRIVE_SIZES[${AVAILABLE_DRIVES[$i]}]})? (y/n): " confirm
                read -p "Process ${AVAILABLE_DRIVES[$i]} (${DRIVE_SIZES[${AVAILABLE_DRIVES[$i]}]}, ${DRIVE_FSTYPES[${AVAILABLE_DRIVES[$i]}]})? (y/n): " confirm
                if [[ "$confirm" == "y" ]]; then
                    format_and_mount_drive "${AVAILABLE_DRIVES[$i]}" "$idx"
                    process_drive "${AVAILABLE_DRIVES[$i]}" "$idx" "${DRIVE_FSTYPES[${AVAILABLE_DRIVES[$i]}]}"
                    ((idx++))
                fi
            done
@@ -180,14 +166,39 @@ setup_nx_storage() {
    log "INFO" "Storage setup complete!"
}

format_and_mount_drive() {
process_drive() {
    local DRIVE="$1"
    local IDX="$2"
    local MOUNTPOINT="/mnt/nxstorage$IDX"
    local FSTYPE="$3"
    local MOUNTPOINT="/mnt/nx_storage$IDX"

    if [[ "$FSTYPE" == "unformatted" ]]; then
        log "WARN" "Drive $DRIVE is unformatted and requires formatting to use with NX Witness."
        read -p "Format $DRIVE to ext4? (y/n): " format_confirm
        if [[ "$format_confirm" != "y" ]]; then
            log "INFO" "Skipping $DRIVE."
            echo "Skipping $DRIVE."
            return
        fi
        format_and_mount_drive "$DRIVE" "$MOUNTPOINT"
    else
        log "INFO" "Drive $DRIVE is formatted ($FSTYPE)."
        read -p "Mount $DRIVE for NX Witness? (y/n): " mount_confirm
        if [[ "$mount_confirm" != "y" ]]; then
            log "INFO" "Skipping $DRIVE."
            echo "Skipping $DRIVE."
            return
        fi
        mount_formatted_drive "$DRIVE" "$MOUNTPOINT" "$FSTYPE"
    fi
}

format_and_mount_drive() {
    local DRIVE="$1"
    local MOUNTPOINT="$2"

    # Check if drive is mounted
    if mount | grep -q "$DRIVE"; then
        log "WARN" "$DRIVE is currently mounted."
        log "WARN" " $DRIVE is currently mounted."
        echo "$DRIVE is mounted. Unmounting is required to format it."
        read -p "Attempt to unmount $DRIVE? (y/n): " unmount_choice
        if [[ "$unmount_choice" == "y" ]]; then
@@ -226,13 +237,66 @@ format_and_mount_drive() {
    echo "$DRIVE formatted and mounted at $MOUNTPOINT."
}

# Function to Install NX Witness Server
mount_formatted_drive() {
    local DRIVE="$1"
    local MOUNTPOINT="$2"
    local FSTYPE="$3"

    if mount | grep -q "$DRIVE"; then
        log "WARN" "$DRIVE is currently mounted."
        echo "$DRIVE is mounted. Unmounting is required to proceed."
        read -p "Attempt to unmount $DRIVE? (y/n): " unmount_choice
        if [[ "$unmount_choice" == "y" ]]; then
            umount "$DRIVE"* 2>/dev/null || { log "ERROR" "Failed to unmount $DRIVE."; echo "Cannot unmount $DRIVE."; return 1; }
        else
            log "INFO" "Skipping $DRIVE due to mount."
            echo "Skipping $DRIVE."
            return
        fi
    fi

    PARTITIONS=$(lsblk -ln -o NAME | grep "^${DRIVE##*/}[0-9]\+$" || true)
    if [[ -n "$PARTITIONS" ]]; then
        log "INFO" "Found partitions on $DRIVE: $PARTITIONS"
        echo "Partitions found on $DRIVE: $PARTITIONS"
        read -p "Select partition to mount (e.g., ${DRIVE##*/}1) or enter 'none' to skip: " PARTITION
        if [[ "$PARTITION" == "none" ]]; then
            log "INFO" "Skipping $DRIVE."
            echo "Skipping $DRIVE."
            return
        fi
        if ! echo "$PARTITIONS" | grep -q "^${PARTITION}$"; then
            log "ERROR" "Invalid partition selected: $PARTITION"
            echo "Invalid partition selected."
            return 1
        fi
        MOUNT_DEVICE="/dev/$PARTITION"
    else
        log "INFO" "No partitions found on $DRIVE. Will mount the whole drive."
        echo "No partitions found. Mounting $DRIVE directly."
        MOUNT_DEVICE="$DRIVE"
    fi

    log "DEBUG" "Creating mount point: $MOUNTPOINT"
    mkdir -p "$MOUNTPOINT" || { log "ERROR" "Failed to create mount point."; echo "Failed to create $MOUNTPOINT."; return 1; }

    log "DEBUG" "Mounting $MOUNT_DEVICE to $MOUNTPOINT"
    mount "$MOUNT_DEVICE" "$MOUNTPOINT" || { log "ERROR" "Failed to mount $MOUNT_DEVICE."; echo "Failed to mount $MOUNT_DEVICE."; return 1; }

    log "DEBUG" "Adding to /etc/fstab"
    echo "$MOUNT_DEVICE $MOUNTPOINT $FSTYPE defaults 0 2" >> /etc/fstab || { log "ERROR" "Failed to update fstab."; echo "Failed to update /etc/fstab."; return 1; }

    log "DEBUG" "Setting permissions for NX Witness"
    chown networkoptix:networkoptix "$MOUNTPOINT" || { log "ERROR" "Failed to set permissions."; echo "Failed to set permissions on $MOUNTPOINT."; return 1; }
    log "INFO" "$MOUNT_DEVICE mounted successfully."
    echo "$MOUNT_DEVICE mounted at $MOUNTPOINT."
}
