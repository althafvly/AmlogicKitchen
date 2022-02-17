#!/usr/bin/sudo sh

if [ -d level1 ]
then
    echo "Deleting existing level1"
    rm -rf level1 && mkdir level1
else
    mkdir level1
fi

echo "....................."
echo "Amlogic Kitchen"
echo "....................."
if [ ! -d in ]; then
    echo "Can't find /in folder"
    echo "Creating /in folder"
    mkdir in
fi
count_file=$(ls -1 in/*.img 2>/dev/null | wc -l)
if [ "$count_file" = 0 ]; then
    echo "No files found in /in"
    exit 0
fi
echo "Files in input dir (*.img)"
count=0
for entry in `ls in/*.img`; do
    count=$(($count + 1))
    name=$(basename in/$entry .img)
    echo $count - $name
done
echo "....................."
echo "Enter a file name :"
read projectname
echo $projectname> level1/projectname.txt

if [ ! -f in/$projectname.img ]
then
    echo "Can't find the file"
    exit 0
fi

filename=$(cat level1/projectname.txt)
bin/linux/AmlImagePack -d in/$filename.img level1
echo "Done."
