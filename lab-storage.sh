#! /bin/bash

STORAGE_PATH="./vm"
IMAGES_STORAGE="images"
SETTINGS_FILE="vm.settings"

for DIRECTORY in "$STORAGE_PATH"/*
do
	HDD_SIZE=$(grep -oP '(?<=DISK_SIZE=)\w+' "$DIRECTORY/$SETTINGS_FILE")
	HDD_TYPE=$(grep -oP '(?<=DISK_TYPE=)\w+' "$DIRECTORY/$SETTINGS_FILE")
	HDD_NAME="`basename "$DIRECTORY"`.$HDD_TYPE"
	if [ -n "$HDD_SIZE" ] && [ -n "$HDD_TYPE" ]; then
		printf " ---> Found $SETTINGS_FILE in $DIRECTORY, creating $HDD_SIZE Virtual-HDD $HDD_NAME ...\n"
		if [ ! -d "$DIRECTORY/$IMAGES_STORAGE" ]; then
			mkdir "$DIRECTORY/$IMAGES_STORAGE"
		fi
		qemu-img create -f "$HDD_TYPE" "$DIRECTORY/$IMAGES_STORAGE/$HDD_NAME" "$HDD_SIZE"
	else
		printf " **** Found $SETTINGS_FILE in $DIRECTORY, but something went wrong with the values ... \
		\n - HDD_SIZE=$HDD_SIZE \
		\n - HDD_TYPE=$HDD_TYPE \n"
	fi
done
