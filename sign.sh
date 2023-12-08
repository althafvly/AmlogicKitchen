#!/usr/bin/sudo bash

# Resign to AOSP keys
echo "Resigning to AOSP keys"

dir=$(pwd)
security=$(pwd)/ROM_resigner/AOSP_security

# Check if custom keys directory exists, use it as security directory if available
if [ -d "$dir/custom_keys" ]; then
    security=$(pwd)/custom_keys
fi

# List of partitions to process
partitions=(
    system_a system_ext_a vendor_a product_a odm_a
    system system_ext vendor product odm
)

# Function to sign files
sign_files() {
    local partition_path=$1
    local selinux_path=$2
    local security_type=$3

    if [ -d "$partition_path/$selinux_path" ] && compgen -G "$partition_path/$selinux_path/*mac_permissions.xml" > /dev/null; then
        python "$dir/ROM_resigner/resign.py" "$partition_path" "$security" "$security_type"
    fi
}

# Loop through system partitions
for part in "${partitions[@]}"; do
    if [ -d "$dir/level2/$part" ]; then
        echo "Signing apks/jar in $part partition"
        if [[ "$part" == "system_a" || "$part" == "system" ]] && [ -d "$dir/level2/$part/system" ]; then
            sign_files "$dir/level2/$part/system" "etc/selinux" "selinux"
        else
            sign_files "$dir/level2/$part" "etc/selinux" "selinux"
            sign_files "$dir/level2/$part" "etc/security" "security"
        fi
    fi
done

# Run write_perm.sh script
./write_perm.sh
