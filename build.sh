#!/bin/sh
# MIT License. See LICENSE file.

FILENAME='init.iso'

# if we are in a git repository, name the ISO after the branch, date, and short commit hash
if [ -n "$GITLAB_CI" ] && [ -n "$CI_COMMIT_REF_SLUG" ]; then
	echo "We are in a GitLab CI/build environment."
	FILENAME="$CI_COMMIT_REF_SLUG-init-$(date -u '+%Y%m%d').$CI_COMMIT_SHORT_SHA.iso"
elif [ "$(git rev-parse --is-inside-work-tree 2> /dev/null)" = "true" ]; then
	GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2> /dev/null)
	GIT_COMMIT=$(git rev-parse --short HEAD 2> /dev/null)
	DATE=$(date -u '+%Y%m%d')
	if [ -n "$GIT_BRANCH" ] && [ -n "$GIT_COMMIT" ]; then
		FILENAME="$(basename "$GIT_BRANCH")-init-$DATE.$GIT_COMMIT.iso"
	fi
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

# test executable so we can use xorrisofs, mkisofs, or genisoimage as appropriate
TOOL=xorrisofs
if command -v xorrisofs > /dev/null 2>&1; then
	echo "Using xorrisofs ..."
elif command -v mkisofs > /dev/null 2>&1; then
	TOOL=mkisofs
	echo "xorrisofs not available; using mkisofs ..."
elif command -v genisoimage > /dev/null 2>&1; then
	TOOL=genisoimage
	echo "xorrisofs not available; falling back to genisoimage ..."
else
	echo "You must install xorriso, mkisofs, or genisoimage to run this script."
	exit 1
fi

# remove any previous output so a failed build is never mistaken for success
rm -f -- "$FILENAME"

if ! "$TOOL" -output "$FILENAME" -volid cidata -joliet -rock user-data meta-data 2>build.log; then
	printf 'Something went wrong while trying to make %s; see build.log\n' "$FILENAME"
	exit 1
fi

FILESIZE=$(wc -c < "$FILENAME" 2>/dev/null | tr -d ' ')
if [ "${FILESIZE:-0}" -gt 0 ]; then
	printf '%s (%d bytes) ... done!\n' "$FILENAME" "$FILESIZE"
else
	printf 'Something went wrong while trying to make %s; see build.log\n' "$FILENAME"
	exit 1
fi
