#!/bin/bash
# MIT License. See LICENSE file.

FILENAME='init.iso'

# if we are in a git repository, name the ISO after the branch, date, and commit hash
IS_GIT=$(git rev-parse --is-inside-work-tree 2> /dev/null)
if [ $IS_GIT ]; then
	GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
	GIT_COMMIT=$(git rev-parse HEAD)
	DATE=$(date -u '+%Y%m%d')
	FILENAME="$(basename $GIT_BRANCH)-init-$DATE.$GIT_COMMIT.iso"
fi

if [ $# -eq 1 ]; then
	FILENAME=$1
	echo "Building image to $FILENAME ..."
elif [ $# -gt 1 ]; then
	echo 'Usage: ./build.sh [filename]'
	exit 1
else
	echo "Building image to $FILENAME ..."
fi

genisoimage -output $FILENAME -volid cidata -joliet -rock user-data meta-data 2>build.log

FILESIZE=$(stat -c %s $FILENAME 2>/dev/null)
COLUMNS=$(tput cols)
if [[ $FILESIZE > 0 ]]; then
	printf '%s (%d bytes) ... done!\n' $FILENAME $FILESIZE
else
	printf 'Something went wrong while trying to make %s\n' $FILENAME
fi

