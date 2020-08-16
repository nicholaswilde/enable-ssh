#!/bin/bash

# Used for xz compression
COMPRESSION_PRESET="-6"

# Check if we're root
if [ "$(id -u)" -ne 0 ]; then
        echo 'This script must be run by root' >&2
	exit 1
fi

# Check if there are enough arguments passed
if [ "$#" -ne 1 ]; then
    	echo "Illegal number of arguments: $#"
    	exit 1
fi

# Get the first argument
SOURCE_FILE=$1

# Get the source directory
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Make a temp folder
trap 'rm -rf "$TEMP_FOLDER"' EXIT
TEMP_FOLDER="$(sudo -u $SUDO_USER mktemp -d)"|| exit 1

# Get the file mime type
MIME_TYPE="$(file -b --mime-type $SOURCE_FILE)"

# Check the file type
if [ $MIME_TYPE == "application/zip" ]; then
	# Unzip the image file
	echo "Unzipping $SOURCE_FILE ..."
	sudo -u $SUDO_USER unzip -q $SOURCE_FILE -d $TEMP_FOLDER
elif [ $MIME_TYPE == "application/x-xz" ]; then
        if ! [ -x "$(which xz)" ]; then
		echo "xz is not installed."
		exit 1	
	fi
	echo "Copying $SOURCE_FILE ..."
        sudo -u $SUDO_USER cp $SOURCE_FILE $TEMP_FOLDER
        BASE_NAME=$(basename $SOURCE_FILE)
        BASE_PATH=$TEMP_FOLDER/$BASE_NAME
	echo "Decompressing $SOURCE_FILE ..."
        sudo -u $SUDO_USER xz --decompress $BASE_PATH
        rm -f $BASE_PATH
else
	echo "Not a zip file: $SOURCE_FILE"
	exit 1
fi

# Get the path of the image file
IMAGE_FILE=$TEMP_FOLDER/"$(ls $TEMP_FOLDER)"

trap 'rm -rf "$MOUNT_FOLDER"' EXIT

# Make a temp folder
MOUNT_FOLDER="$(sudo -u $SUDO_USER mktemp -d)" || exit 1

# Get the offset
OFFSET="$(fdisk -l $IMAGE_FILE | grep img1 | awk '{print $2}')"

# Check if we got an asterisk from the BOOT column
if [[ $OFFSET == "*" ]]; then
	OFFSET="$(fdisk -l $IMAGE_FILE | grep img1 | awk '{print $3}')"
fi

# Check if the size is numberic
re='^[0-9]+$'
if ! [[ $OFFSET =~ $re ]]; then
	echo "Could not get the partition offset of the image file" >&2;
        exit 1
fi

# Modify the size
OFFSET=$((OFFSET * 512))

# Mount the image
echo "Mounting $IMAGE_FILE ..."
sudo mount -o loop,offset=$OFFSET $IMAGE_FILE $MOUNT_FOLDER

# Create the ssh file
echo "Creating file $MOUNT_FOLDER/ssh ..."
touch $MOUNT_FOLDER/ssh

# Unmount
echo "Unmounting $MOUNT_FOLDER ..."
sudo umount $MOUNT_FOLDER

if [ $MIME_TYPE == "application/zip" ]; then
	# Remove the extension
	DEST_FILE="${SOURCE_FILE%.zip}"
    DEST_FILE=$DEST_FILE-1.zip
	# Zip the file
	echo "Zipping $IMAGE_FILE ..."
	sudo -u $SUDO_USER bash -c "zip -q $DIR/$DEST_FILE /$IMAGE_FILE"
elif [ $MIME_TYPE == "application/x-xz" ]; then
	# Remove the extension
	DEST_FILE="${SOURCE_FILE%.xz}"
	DEST_FILE=$DEST_FILE-1.xz
	echo "Compressing $IMAGE_FILE ..."
 	sudo -u $SUDO_USER bash -c "xz -k -z $COMPRESSION_PRESET $IMAGE_FILE"
    echo "Removing $IMAGE_FILE ..."
    rm -f $IMAGE_FILE
	SOURCE_FILE=$TEMP_FOLDER/"$(ls $TEMP_FOLDER)"
    echo "Moving $DEST_FILE-1.xz ..."
    sudo -u $SUDO_USER mv $SOURCE_FILE $DIR/$DEST_FILE
fi

# Cleanup
echo "Cleaning up $TEMP_FOLDER ..."
sudo rm -rf $TEMP_FOLDER
