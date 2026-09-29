#!/bin/sh
# MIT License. See LICENSE file.

usage() {
	echo 'Usage: ./build.sh [-f|--force|--overwrite] [filename]'
}

# parse command line flags; sets OVERWRITE and OUTPUT_ARG
parse_args() {
	OVERWRITE=0
	OUTPUT_ARG=''
	while [ $# -gt 0 ]; do
		case "$1" in
			-f|--force|--overwrite)
				OVERWRITE=1
				;;
			-h|--help)
				usage
				exit 0
				;;
			--)
				shift
				break
				;;
			-*)
				echo "Unknown option: $1"
				usage
				exit 1
				;;
			*)
				if [ -n "$OUTPUT_ARG" ]; then
					usage
					exit 1
				fi
				OUTPUT_ARG=$1
				;;
		esac
		shift
	done
	# anything after -- is the filename
	if [ $# -gt 0 ]; then
		if [ -n "$OUTPUT_ARG" ] || [ $# -gt 1 ]; then
			usage
			exit 1
		fi
		OUTPUT_ARG=$1
	fi
}

parse_args "$@"

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

if [ -n "$OUTPUT_ARG" ]; then
	FILENAME=$OUTPUT_ARG
fi

if [ -e "$FILENAME" ] || [ -L "$FILENAME" ]; then
	if [ "$OVERWRITE" -ne 1 ]; then
		echo "$FILENAME already exists; not overwriting it."
		echo "Re-run with --overwrite (or -f/--force) to replace it, or choose another filename."
		exit 1
	fi
	if [ ! -f "$FILENAME" ]; then
		echo "$FILENAME exists and is not a regular file; refusing to replace it."
		exit 1
	fi
	echo "$FILENAME already exists and will be overwritten."
fi

echo "Building image to $FILENAME ..."

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

# build into a new temporary file so a failed build never touches an existing ISO
TMPFILE="$FILENAME.partial.$$"
if [ -e "$TMPFILE" ] || [ -L "$TMPFILE" ]; then
	echo "Temporary file $TMPFILE already exists; refusing to overwrite it."
	exit 1
fi

fail() {
	rm -f -- "$TMPFILE"
	printf 'Something went wrong while trying to make %s; see build.log\n' "$FILENAME"
	exit 1
}

"$TOOL" -output "$TMPFILE" -volid cidata -joliet -rock user-data meta-data 2>build.log || fail

FILESIZE=$(wc -c < "$TMPFILE" 2>/dev/null | tr -d ' ')
[ "${FILESIZE:-0}" -gt 0 ] || fail

if [ "$OVERWRITE" -eq 1 ]; then
	mv -f -- "$TMPFILE" "$FILENAME" || fail
else
	# ln refuses to replace an existing file, so nothing that appeared since the check is clobbered
	if ln -- "$TMPFILE" "$FILENAME" 2>/dev/null; then
		rm -f -- "$TMPFILE"
	elif [ -e "$FILENAME" ] || [ -L "$FILENAME" ]; then
		rm -f -- "$TMPFILE"
		echo "$FILENAME now exists; not overwriting it. Re-run with --overwrite to replace it."
		exit 1
	else
		# filesystem without hard link support
		mv -- "$TMPFILE" "$FILENAME" || fail
	fi
fi

printf '%s (%d bytes) ... done!\n' "$FILENAME" "$FILESIZE"
