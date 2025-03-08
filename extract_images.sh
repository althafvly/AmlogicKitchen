#!/bin/bash

ARGS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        *)  ARGS+=("$1") ;;
    esac
    shift
done

IMAGE_DIR=${ARGS[0]}
OUTPUT_FOLDER=${ARGS[1]}

for IMAGE in system system_ext vendor vendor_dlkm product odm odm_dlkm oem oem_a system_a system_ext_a vendor_a product_a odm_a; do
  IMAGE_FILE=""

  for ext in PARTITION img fex; do
    if [ -f "$IMAGE_DIR/$IMAGE.$ext" ]; then
      IMAGE_FILE="$IMAGE_DIR/$IMAGE.$ext"
      break
    fi
  done

  if [ -z "$IMAGE_FILE" ] || [ ! -f "$IMAGE_FILE" ]; then
    continue
  fi
  
  # Check filesystem type
  TYPE=$(bin/gettype -i "$IMAGE_FILE")
  SIZE=$(du -b "$IMAGE_FILE" | cut -f1)

  if [ "$SIZE" -lt 1024 ]; then
    continue
  fi

  echo "Extracting $IMAGE"

  if [ "$TYPE" = "erofs" ]; then
    bin/extract.erofs -i "$IMAGE_FILE" -x -o "$OUTPUT_FOLDER"
    echo $(du -b $IMAGE_FILE | cut -f1) >"level2/config/${IMAGE}_size.txt"
  elif [ "$TYPE" = "sparse" ]; then
    bin/simg2img $IMAGE_FILE "level2/${IMAGE}.raw.img"
    python3 bin/imgextractor.py "level2/${IMAGE}.raw.img" "$OUTPUT_FOLDER"
    rm -rf "level2/${IMAGE}.raw.img"
  else
    python3 bin/imgextractor.py "$IMAGE_FILE" "$OUTPUT_FOLDER"
  fi

  awk -i inplace '!seen[$0]++' level2/config/${IMAGE}_f*
done
