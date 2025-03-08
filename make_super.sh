#!/bin/bash

ARGS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        *)  ARGS+=("$1") ;;
    esac
    shift
done

IMAGE=${ARGS[0]}
PARTITION_NAME=${ARGS[1]}

if [ -f $IMAGE ]; then
  for filename in level2/*.img; do
    part="$(basename "$filename" .img)"
    if [ -d level2/$part ]; then
      msize=$(du -sk level2/$part | cut -f1 | gawk '{$1*=1024;$1=int($1*1.08);printf $1}')
      echo "Creating $part image"
      if [ $msize -lt 1048576 ]; then
        msize=1048576
      fi
      ./make_image.sh -r $part $msize level2/$part level2/${part}.img
      echo "Done."
    fi
  done
fi

if [ -f level2/config/super_type.txt ]; then
  supertype=$(cat level2/config/super_type.txt)
fi

if [ ! -z "$supertype" ] && [ $supertype -eq "3" ]; then
  metadata_size=65536
  metadata_slot=3
  supername="super"
  supersize=$(cat level2/config/super_size.txt)
  superusage1=$(du -cb level2/*.img | grep total | cut -f1)
  command="bin/lpmake --metadata-size $metadata_size --super-name $supername --metadata-slots $metadata_slot"
  command="$command --device $supername:$supersize --group ${PARTITION_NAME}_dynamic_partitions_a:$superusage1"

  for filename in level2/*_a.img; do
    part="$(basename "$filename" .img)"
    if [ -f level2/$part.img ]; then
      asize=$(du -skb level2/$part.img | cut -f1)
      if [ $asize -gt 0 ]; then
        command="$command --partition $part:readonly:$asize:${PARTITION_NAME}_dynamic_partitions_a --image $part=level2/$part.img"
      fi
    fi
  done

  superusage2=$(expr $supersize - $superusage1)
  command="$command --group ${PARTITION_NAME}_dynamic_partitions_b:$superusage2"

  for filename in level2/*_b.img; do
    part="$(basename "$filename" .img)"
    if [ -f level2/$part.img ]; then
      bsize=$(du -skb level2/$part.img | cut -f1)
      if [ $bsize -eq 0 ]; then
        command="$command --partition $part:readonly:$bsize:${PARTITION_NAME}_dynamic_partitions_b"
      fi
    fi
  done

  if [ $superusage2 -ge $supersize ]; then
    echo "Unable to create super image, recreated images are too big."
    echo "Cleanup some files before retrying"
    echo "Needed space: $superusage1"
    echo "Available maximum space: $supersize"
    exit 0
  fi

  command="$command --virtual-ab --sparse --output $IMAGE"
  if [ -f $IMAGE ]; then
    $($command)
  fi

  elif [ ! -z "$supertype" ] && [ $supertype -eq "2" ]; then
  metadata_size=65536
  metadata_slot=2
  supername="super"
  supersize=$(cat level2/config/super_size.txt)
  superusage=$(du -cb level2/*.img | grep total | cut -f1)
  command="bin/lpmake --metadata-size $metadata_size --super-name $supername --metadata-slots $metadata_slot"
  command="$command --device $supername:$supersize --group ${PARTITION_NAME}_dynamic_partitions:$superusage"

  for part in system_ext system odm product vendor; do
    if [ -f level2/$part.img ]; then
      asize=$(du -skb level2/$part.img | cut -f1)
      if [ $asize -gt 0 ]; then
        command="$command --partition $part:readonly:$asize:${PARTITION_NAME}_dynamic_partitions --image $part=level2/$part.img"
      fi
    fi
  done

  if [ $superusage -ge $supersize ]; then
    echo "Unable to create super image, recreated images are too big."
    echo "Cleanup some files before retrying"
    echo "Needed space: $superusage1"
    echo "Available maximum space: $supersize"
    exit 0
  fi

  command="$command --sparse --output $IMAGE"
  if [ -f $IMAGE ]; then
    $($command)
  fi
fi