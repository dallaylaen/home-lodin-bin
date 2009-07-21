#!/bin/sh

FDATA=http://www.livejournal.com/misc/fdata.bml?user=
PREFIX=http://www.livejournal.com

DIR=~/.lj/friendof

TO=$USER
ALTMAIL=~/.mailrc-msmtp

# usage: $0 [lj-user]

# default username is $USER
if [ -z "$1" ];then
	LJ=$USER
else
	LJ=$1
fi

if [ \! -z "$2" ] && [ -f "$ALTMAIL" ]; then
	TO=$2
	MAILRC="$ATLMAIL"
	export MAILRC
fi

# friends data storage
mkdir -p $DIR
LIST=$DIR/$LJ

# replace + and - with words
whoadded () {
	sed "s,^\(.\)\(.*\),\1$PREFIX/~\2/profile,; s/^+/added: /; s/^-/removed: /"
}

# send mail unless input is empty
mailif () {
	if read first; then 
		(
			echo "This e-mail was generated automatically at `date`"
			echo "Please do not reply to it"
			echo
			echo $first; cat) | mail "$@"
	else
		return 1
	fi
}

# if list does not exist, initialize and exit
if [ \! -f $LIST ]; then
	echo >&2 "Initiating friendof list as $LIST ..."
	getfof >$LIST && echo >&2 "done" || echo "fail"
	exit $?
fi

# create temporary file
NLIST=`mktemp /tmp/.private/$USER/lj-friendof-XXXXXXXX` || exit 1

# get new data
~/bin/ljcache --fof $LJ >$NLIST || exit 2

# find differences and report them
diff -u $LIST $NLIST | egrep  '^(\+|\-)' | egrep -v '^(\+\+\+|\-\-\-)' |\
	LC_ALL=C sort |\
	whoadded | mailif -s "Friend list changes for user $LJ" "$TO" 

# clean up
mv $NLIST $LIST

