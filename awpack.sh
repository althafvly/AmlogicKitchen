#!/usr/bin/sudo bash

set -e

echo "....................."
echo "AllWinner Kitchen"
echo "....................."
read -p "Select level 1, 2, 3 or q/Q to exit: " level

case "$level" in
  1)
    if [[ ! -d level1 ]]; then
      echo "Can't find level1 folder"
      exit 1
    fi

    [[ -d out ]] || { echo "Created out folder"; mkdir out; }

    file_name=$(<level1/projectname.txt)

    # Check for 32-bit support
    if ldd bin/imgrepacker 2>&1 | grep -q "not found"; then
      bin/OpenixCard -p "level1/$file_name.img.dump"
      mv "level1/$file_name.img.dump/$file_name.img" "out/$file_name.img"
    else
      setarch i386 bin/imgrepacker "level1/$file_name.img"
      mv "level1/$file_name.img" "out/$file_name.img"
    fi

    echo "Done."
    ;;

  2)
    if [[ ! -d level2 ]]; then
      echo "Unpack level 2 first"
      exit 1
    fi

    foldername=$(<level1/projectname.txt).img.dump

    if [[ ! -f level1/$foldername/super.fex ]]; then
      for part in system system_ext vendor product odm oem oem_a; do
        [[ -d level2/$part ]] || continue
        echo "Creating $part image"
        size=$(<level2/config/${part}_size.txt)
        [[ -n "$size" ]] && ./common/make_image.sh -s "$part" "$size" level2/$part/ "level1/$foldername/$part.fex"
        echo "Done."
      done
    fi

    for part in oem_a odm_ext_a odm_ext_b; do
      [[ -d level2/$part ]] || continue
      echo "Creating $part image"
      size=$(<level2/config/${part}_size.txt)
      [[ -n "$size" ]] && ./common/make_image.sh -s "$part" "$size" level2/$part/ "level1/$foldername/$part.fex"
      echo "Done."
    done

    ./common/make_super.sh "level1/$foldername/super.fex" allwinner
    rm -f level2/*.txt
    ;;

  3)
    if [[ ! -d level3 ]]; then
      echo "Unpack level 3 first"
      exit 1
    fi

    foldername=$(<level1/projectname.txt).img.dump

    ./common/pack_boot.sh

    if [[ -d "level3/boot-resource" ]]; then
      echo "Packing boot-resource.fex"
      (
        cd level3
        ../bin/fsbuild ../bin/boot-resource.ini "../level1/$foldername/split_xxxx.fex"
        mv boot-resource.fex "../level1/$foldername/boot-resource.fex"
      )
    fi

    echo "Done."
    ;;

  q|Q)
    exit 0
    ;;

  *)
    echo "Invalid selection."
    exit 1
    ;;
esac

# Final post-processing
while true; do
  ./common/write_perm.sh && ./awpack.sh && break
done
