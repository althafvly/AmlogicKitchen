#!/bin/bash

USE_SPARSE=false
USE_RESIZE=false
ARGS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        -s) USE_SPARSE=true ;;  # Enable sparse image (-s flag)
        -r) USE_RESIZE=true ;;  # Enable resize2fs (-r flag)
        *)  ARGS+=("$1") ;;
    esac
    shift
done

PART=${ARGS[0]}
SIZE=${ARGS[1]}
FOLDERNAME=${ARGS[2]}
OUTPUT_IMG=${ARGS[3]}

FS="level2/config/${PART}_fs_config"
FC="level2/config/${PART}_file_contexts"

# Create a temporary file in the same directory as OUTPUT_IMG
TEMP_IMG="$(dirname "$OUTPUT_IMG")/temp_$(basename "$OUTPUT_IMG")"

# Check filesystem type
if [ "$(bin/gettype -i "$OUTPUT_IMG")" = "erofs" ]; then
    bin/mkfs.erofs -zlz4hc --mount-point "/$PART" --fs-config-file "$FS" --file-contexts "$FC" "$TEMP_IMG" "level2/$PART"
else
    if $USE_SPARSE; then
        bin/make_ext4fs -s -J -L "$PART" -T -1 -S "$FC" -C "$FS" -l "$SIZE" -a "$PART" "$TEMP_IMG" "level2/$PART"
    else
        bin/make_ext4fs -J -L "$PART" -T -1 -S "$FC" -C "$FS" -l "$SIZE" -a "$PART" "$TEMP_IMG" "level2/$PART"
    fi

    # Run resize2fs only if -r flag is set
    if $USE_RESIZE; then
        bin/resize2fs -M "$TEMP_IMG"
    fi
fi

# Move the temp file to final output
mv -f "$TEMP_IMG" "$OUTPUT_IMG"
