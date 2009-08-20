#!/bin/sh

DIR=~/.lasttimediff/

mkdir -p "$DIR"

OLD="$DIR"/`echo -n "$*" | perl -pe 's/[\0- ]/_/g; s/([^a-z0-9_ \-\.\,\:])/"%".unpack("H2", $1) /ige'`

# echo "$OLD"
# exit

NEW=`mktemp "$TMP/lasttimediff-XXXXXXXX"`
cat >"$NEW"

if diff -Nur "$OLD" "$NEW"; then
	rm $NEW
	touch $OLD
else
	mv "$NEW" "$OLD" 
fi

