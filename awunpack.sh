#!/usr/bin/sudo bash

set -e

echo "....................."
echo "AllWinner Kitchen"
echo "....................."
read -p "Select level 1, 2, 3 or q/Q to exit: " level

prepare_dir() {
  local dir=$1
  if [ -d "$dir" ]; then
    echo "Deleting existing $dir"
    rm -rf "$dir"
  fi
  mkdir -p "$dir"
}

run_level1() {
  prepare_dir level1

  echo "....................."
  echo "AllWinner Kitchen"
  echo "....................."

  [ -d in ] || { echo "Creating /in folder"; mkdir in; }

  local img_files=()
  while IFS= read -r -d '' f; do img_files+=("$f"); done < <(find in/ -maxdepth 1 -name "*.img" -print0)

  if [ ${#img_files[@]} -eq 0 ]; then
    echo "No .img files found in /in"
    exit 0
  fi

  rename 's/ /_/g' in/*.img

  echo "Files in input dir:"
  local count=1
  for f in "${img_files[@]}"; do
    name=$(basename "$f" .img)
    echo "$count - $name"
    ((count++))
  done

  echo "....................."
  read -p "Enter a file name: " projectname
  echo "$projectname" > level1/projectname.txt

  if [ ! -f "in/$projectname.img" ]; then
    echo "Can't find the file: in/$projectname.img"
    exit 1
  fi

  cp "in/$projectname.img" "level1/$projectname.img"

  if ldd bin/imgrepacker 2>&1 | grep -q "not found"; then
    bin/OpenixCard -uc "level1/$projectname.img"
  else
    setarch i386 bin/imgrepacker "level1/$projectname.img"
  fi

  rm "level1/$projectname.img"
  echo "Done."
}

run_level2() {
  [ -d level1 ] || { echo "Unpack level 1 first"; exit 1; }

  prepare_dir level2/config

  foldername=$(<level1/projectname.txt).img.dump
  ./common/extract_images.sh "level1/$foldername" "level2"

  if [ -f "level1/$foldername/super.fex" ]; then
    ./common/extract_super.sh "level1/$foldername/super.fex" level2/
  fi

  echo "Done."
}

run_level3() {
  [ -d level1 ] || { echo "Unpack level 1 first"; exit 1; }

  prepare_dir level3

  foldername=$(<level1/projectname.txt).img.dump
  ./common/unpack_boot.sh

  if [ -f "level1/$foldername/boot-resource.fex" ]; then
    echo "Extracting boot-resource in level3"
    tmp_mount_dir=$(mktemp -d)
    mount -o loop -t vfat "level1/$foldername/boot-resource.fex" "$tmp_mount_dir"
    cp -a "$tmp_mount_dir"/. "level3/boot-resource/"
    umount "$tmp_mount_dir"
    rmdir "$tmp_mount_dir"
    rm -f "level3/boot-resource/magic.bin"
  fi

  echo "Done."
}

case "$level" in
  1) run_level1 ;;
  2) run_level2 ;;
  3) run_level3 ;;
  q|Q) exit 0 ;;
  *) echo "Invalid input. Use 1, 2, 3, or q to quit."; exit 1 ;;
esac

# Final step
while true; do
  ./common/write_perm.sh && ./awunpack.sh && break
done
