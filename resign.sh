#!/usr/bin/sudo bash

set -e

echo "....................."
echo "Resigning to AOSP keys"
echo "....................."

# Set working directory and security key path
dir="$(pwd)"
security="$dir/ROM_resigner/AOSP_security"

# Use custom keys if available
if [ -d "$dir/custom_keys" ]; then
  echo "Using custom keys"
  security="$dir/custom_keys"
fi

# Partitions to check and process
partitions=(
  system_a system_ext_a vendor_a product_a odm_a
  system system_ext vendor product odm
)

# Process each partition if directory exists
for part in "${partitions[@]}"; do
  partition_path="$dir/level2/$part"
  if [ -d "$partition_path" ]; then
    echo "Signing APKs/JARs in: $part"

    if [[ "$part" == "system_a" || "$part" == "system" ]] && [ -d "$partition_path/system" ]; then
      python3 "$dir/ROM_resigner/resign.py" "$partition_path/system" "$security"
    else
      python3 "$dir/ROM_resigner/resign.py" "$partition_path" "$security"
    fi
  fi
done

# Set correct permissions post-signing
./common/write_perm.sh
