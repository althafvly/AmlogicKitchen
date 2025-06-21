#!/usr/bin/sudo bash

echo "Cleaning up build directories..."

for dir in level1 level2 level3 tmp; do
  if [ -d "$dir" ]; then
    echo "Removing $dir..."
    rm -rf "$dir"
  else
    echo "$dir does not exist, skipping..."
  fi
done

echo "Cleanup complete."
