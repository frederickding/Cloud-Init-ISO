#!/bin/bash

echo "Building image..."

genisoimage -output init.iso -volid cidata -joliet -rock user-data meta-data 2>build.log

FILESIZE=$(stat -c %s init.iso 2>/dev/null)
COLUMNS=$(tput cols)
if [[ $FILESIZE > 0 ]]; then
	printf 'init.iso (%d bytes) ... done!\n' $FILESIZE
else
	printf 'Something went wrong while trying to make init.iso\n'
fi

