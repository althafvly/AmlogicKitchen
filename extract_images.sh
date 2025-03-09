#!/bin/bash

IMAGE_DIR="$1"
OUTPUT_FOLDER="$2"

for IMAGE in system system_ext vendor vendor_dlkm product odm odm_dlkm oem oem_a system_a system_ext_a vendor_a product_a odm_a; do
  for ext in PARTITION img fex; do
    IMAGE_FILE="$IMAGE_DIR/$IMAGE.$ext"
    [[ -f "$IMAGE_FILE" ]] && break || IMAGE_FILE=""
  done

  [[ -z "$IMAGE_FILE" || ! -f "$IMAGE_FILE" ]] && continue

  SIZE=$(du -b "$IMAGE_FILE" | cut -f1)
  [[ "$SIZE" -lt 1024 ]] && continue

  echo "Extracting $IMAGE"
  TYPE=$(bin/gettype -i "$IMAGE_FILE")

  if [[ "$TYPE" == "erofs" ]]; then
    bin/extract.erofs -i "$IMAGE_FILE" -x -o "$OUTPUT_FOLDER"
    du -b "$IMAGE_FILE" | cut -f1 > "level2/config/${IMAGE}_size.txt"
  elif [[ "$TYPE" == "sparse" ]]; then
    bin/simg2img "$IMAGE_FILE" "level2/${IMAGE}.raw.img"
    python3 bin/imgextractor.py "level2/${IMAGE}.raw.img" "$OUTPUT_FOLDER"
    rm -f "level2/${IMAGE}.raw.img"
  else
    python3 bin/imgextractor.py "$IMAGE_FILE" "$OUTPUT_FOLDER"
  fi

  awk -i inplace '!seen[$0]++' level2/config/${IMAGE}_f*
done
