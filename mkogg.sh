#!/bin/sh


for i in `seq -w 99`; do 
	cdparanoia "$i" - | nice oggenc -q9 -b 128 - > "$i.ogg" || break; 
done

