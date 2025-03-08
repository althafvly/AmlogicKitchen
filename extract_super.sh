#!/bin/bash

ARGS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        *)  ARGS+=("$1") ;;
    esac
    shift
done

IMAGE=${ARGS[0]}
OUTPUT_FOLDER=${ARGS[1]}

bin/simg2img "$IMAGE" level2/super.img
echo $(du -b level2/super.img | cut -f1) >level2/config/super_size.txt
bin/lpunpack -slot=0 level2/super.img $OUTPUT_FOLDER
rm -rf level2/super.img

if [ $(ls -1q level2/*_a.img 2>/dev/null | wc -l) -gt 0 ]; then
  echo "3" >level2/config/super_type.txt
else
  echo "2" >level2/config/super_type.txt
fi

./extract_images.sh "$OUTPUT_FOLDER" "$OUTPUT_FOLDER"
