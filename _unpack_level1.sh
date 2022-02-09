#!/usr/bin/sudo sh

if [ -d level1 ]
then
    echo "Deleting existing level1"
    rm -rf level1 && mkdir level1
else
    mkdir level1
fi

if [ ! -d in ]
then
    echo "Can't find /in folder"
    echo "Creating /in folder"
    mkdir in
else
	count_file=$(ls -1 in/*.img 2>/dev/null | wc -l)
	if [ "$count_file" = 0 ]; then
		echo "No files found in /in"
	elif [ "$count_file" -ne 1 ]; then
		echo "Too many files found"
	else
		bin/linux/AmlImagePack -d in/*.img level1
		echo "Done."
	fi
fi
