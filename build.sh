#!/bin/bash
FILENAME='init.iso'

if [ $# -eq 1 ]; then
	FILENAME=$1
	echo "Building image to $FILENAME ..."
elif [ $# -gt 1 ]; then
	echo 'Usage: ./build.sh [filename]'
	exit 1
else
	echo "Building image to init.iso ..."
fi

genisoimage -output $FILENAME -volid cidata -joliet -rock user-data meta-data 2>build.log

FILESIZE=$(stat -c %s $FILENAME 2>/dev/null)
COLUMNS=$(tput cols)
if [[ $FILESIZE > 0 ]]; then
	printf '%s (%d bytes) ... done!\n' $FILENAME $FILESIZE
else
	printf 'Something went wrong while trying to make %s\n' $FILENAME
fi

