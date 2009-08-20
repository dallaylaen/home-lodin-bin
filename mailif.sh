#!/bin/sh

if read i; then
	(echo $i; cat )|\
	mail "$@"
fi
