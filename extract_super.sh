#!/bin/bash

IMAGE="$1"
OUTPUT_FOLDER="$2"

bin/simg2img "$IMAGE" level2/super.img
du -b level2/super.img | cut -f1 > level2/config/super_size.txt
bin/lpunpack -slot=0 level2/super.img "$OUTPUT_FOLDER"
rm -f level2/super.img

if ls level2/*_a.img &>/dev/null; then
  echo "3" > level2/config/super_type.txt
else
  echo "2" > level2/config/super_type.txt
fi

./extract_images.sh "$OUTPUT_FOLDER" "$OUTPUT_FOLDER"
