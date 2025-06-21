#!/usr/bin/sudo bash

set -e

echo "....................."
echo "Amlogic Dumper"
echo "....................."
echo "Before going any further"
echo "Please connect your Amlogic box in mask ROM mode (USB Burning Tool mode)"
echo "....................."

# Reset directories
for dir in dtb dump; do
  echo "Resetting $dir/"
  rm -rf "$dir"
  mkdir -p "$dir"
done

# Read sizes
read -p "Input bootloader size in bytes (default: 4194304): " blsize
read -p "Input DTB size in bytes (default: 262144): " dtbsize

# Fallback defaults if user left blank
blsize=${blsize:-4194304}
dtbsize=${dtbsize:-262144}

# Dump bootloader and DTB
bin/update mread store bootloader normal "$blsize" dump/bootloader.img
bin/update mread store _aml_dtb normal "$dtbsize" dtb/dtb.img

# Extract DTB if it exists
if [[ -f dtb/dtb.img ]]; then
  echo "Extracting dtb.img..."
  7zz x dtb/dtb.img -y >/dev/null 2>&1 || true

  if [[ -f _aml_dtb ]]; then
    bin/dtbSplit _aml_dtb dtb/
    rm -f _aml_dtb
  fi

  bin/dtbSplit dtb/dtb.img dtb/

  # Convert DTB to DTS
  for dtbfile in dtb/*.dtb; do
    [[ -f "$dtbfile" ]] || continue
    dtsfile="${dtbfile%.dtb}.dts"
    dtc -I dtb -O dts "$dtbfile" -o "$dtsfile"
    rm -f "$dtbfile"
  done

  dtc -I dtb -O dts dtb/dtb.img -o dtb/single.dts
  mv dtb/dtb.img dump/

  echo "Available DTS files:"
  count=0
  for entry in dtb/*.dts; do
    name=$(basename "$entry" .dts)
    count=$((count + 1))
    echo "$count - $name"
  done

  echo "....................."
  read -p "Enter a DTS filename to extract partition info from: " dtsname

  dtsfile="dtb/$dtsname.dts"
  if [[ ! -f "$dtsfile" ]]; then
    echo "Error: $dtsfile not found"
    exit 1
  fi

  echo "Extracting partition names..."
  grep -Po '\tpname = "\K[^"]+' "$dtsfile" | sort -u >dump/partitions.txt

  echo "Dumping partition images..."
  while read -r partname; do
    size=$(awk -v pname="$partname" '
      $0 ~ "pname" && $0 ~ "\"" pname "\"" {
        getline; getline; if ($0 ~ /size/) {
          match($0, /0x00 ([0-9a-fA-F]+)/, arr)
          print arr[1]
        }
      }
    ' "$dtsfile")

    if [[ -n "$size" ]]; then
      echo "Dumping $partname ($size)..."
      bin/update mread store "$partname" normal "$size" "dump/$partname.img"
    else
      echo "Warning: Could not determine size for $partname"
    fi
  done <dump/partitions.txt
fi

# Cleanup
rm -f dump/partitions.txt
rm -rf dtb

./common/write_perm.sh
echo "Done."
exit 0
