#!/bin/sh

from=$1
to=$2

function copykoi () {
for i in $from/*; do
    ren=`echo "$i" | iconv -f koi8-r -t utf-8`
    if test -d "$i"; then
	mkdir -p "$to/$ren"
	copykoi "$from/$i" "$to/$ren"
	
    else 
	cp "$from/$i" "$to/$ren"
	
    fi
    
done
}

copykoi $1 $2