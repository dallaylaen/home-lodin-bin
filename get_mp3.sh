#!/bin/sh

MASK="mp3,ogg"
URL=$1
if [ "x$URL" = "x" ]; then
cat << USAGE 
Usage: $0 <url>

This will (w)get all mp3s reachable from the page
USAGE
exit
fi

wget -c -r -l1 -A "$MASK" -H --follow-ftp --limit-rate 20K $*


