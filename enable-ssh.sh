#!/bin/bash

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

# Get the file mime type
MIME_TYPE="$(file -b --mime-type $SOURCE_FILE)"

# Check the file type
if [ $MIME_TYPE != "application/zip"  ]; then
	echo "Not a zip file: $SOURCE_FILE"
	exit 1
fi

# Get the source directory
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Make a temp folder
trap 'rm -rf "$TEMP_FOLDER"' EXIT
TEMP_FOLDER="$(sudo -u $SUDO_USER mktemp -d)"|| exit 1

# Unzip the image file
echo "Unzipping $SOURCE_FILE ..."
sudo -u $SUDO_USER unzip -q $SOURCE_FILE -d $TEMP_FOLDER

# Get the path of the image file
IMAGE_FILE=$TEMP_FOLDER/"$(ls $TEMP_FOLDER)"

trap 'rm -rf "$MOUNT_FOLDER"' EXIT

# Make a temp folder
MOUNT_FOLDER="$(sudo -u $SUDO_USER mktemp -d)"|| exit 1

# Get the size
SIZE="$(fdisk -l $IMAGE_FILE | grep img1 | awk '{print $2}')"

# Modify the size
SIZE=$((SIZE * 512))

# Mount the image
echo "Mounting $IMAGE_FILE ..."
sudo mount -o loop,offset=$SIZE $IMAGE_FILE $MOUNT_FOLDER

# Create the ssh file
echo "Creating the ssh file $MOUNT_FOLDER/ssh ..."
touch $MOUNT_FOLDER/ssh

# Unmount
echo "Unmounting the image $MOUNT_FOLDER ..."
sudo umount $MOUNT_FOLDER

# Remove the extension
DEST_FILE="${SOURCE_FILE%.zip}"

# Zip the file
echo "Zipping $IMAGE_FILE ..."
sudo -u $SUDO_USER bash -c "zip -q $DIR/$DEST_FILE-1.zip /$IMAGE_FILE"

# Cleanup
echo "Cleaning up $TEMP_FOLDER ..."
sudo rm -rf $TEMP_FOLDER
