#!/usr/bin/sudo bash

# Resign to AOSP keys
echo "Resigning to AOSP keys"

dir=$(pwd)
security=$dir/ROM_resigner/AOSP_security

# Check if custom keys directory exists, use it as security directory if available
if [ -d "$dir/custom_keys" ]; then
  security=$dir/custom_keys
fi

# List of partitions to process
partitions=(
  system_a system_ext_a vendor_a product_a odm_a
  system system_ext vendor product odm
)

# Loop through system partitions
for part in "${partitions[@]}"; do
  if [ -d "$dir/level2/$part" ]; then
    echo "Signing apks/jar in $part partition"
    if [[ "$part" == "system_a" || "$part" == "system" ]] && [ -d "$dir/level2/$part/system" ]; then
      python3 "$dir/ROM_resigner/resign.py" "$dir/level2/$part/system" "$security"
    else
      python3 "$dir/ROM_resigner/resign.py" "$dir/level2/$part" "$security"
    fi
  fi
done

# Run write_perm.sh script
./write_perm.sh
