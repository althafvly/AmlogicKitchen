#!/bin/bash

USE_SPARSE=false
USE_RESIZE=false
ARGS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        -s) USE_SPARSE=true ;;  # Enable sparse image
        -r) USE_RESIZE=true ;;  # Enable resize2fs
        *)  ARGS+=("$1") ;;
    esac
    shift
done

PART=${ARGS[0]}
SIZE=${ARGS[1]}
OUTPUT_IMG=${ARGS[3]}

FS="level2/config/${PART}_fs_config"
FC="level2/config/${PART}_file_contexts"
TEMP_IMG="$(dirname "$OUTPUT_IMG")/temp_$(basename "$OUTPUT_IMG")"

if [ "$(bin/gettype -i "$OUTPUT_IMG")" = "erofs" ]; then
    bin/mkfs.erofs -zlz4hc --mount-point "/$PART" --fs-config-file "$FS" --file-contexts "$FC" "$TEMP_IMG" "level2/$PART"
else
    FLAGS="-J -L $PART -T -1 -S $FC -C $FS -l $SIZE -a $PART"
    [[ $USE_SPARSE == true ]] && FLAGS="-s $FLAGS"
    bin/make_ext4fs $FLAGS "$TEMP_IMG" "level2/$PART"
    
    [[ $USE_RESIZE == true ]] && bin/resize2fs -M "$TEMP_IMG"
fi

mv -f "$TEMP_IMG" "$OUTPUT_IMG"
