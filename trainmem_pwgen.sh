#!/bin/bash

STR=`pwgen 8 5`

STIME=`date +%s`
xterm -e "echo '`echo $STR`'; echo Press enter when ready; read"
ETIME=`date +%s`
TIME=$(($ETIME - $STIME))

sleep 20
echo -ne \\07

read ANS || exit 1

PTS=0
for i in $STR; do
	ERR=1
	for j in $ANS; do
		if [ "$i" == "$j" ]; then
			ERR=''
			PTS=$(($PTS + 1))
			break
		fi
	done
	[ -z "$ERR" ] && echo "+OK: $i" || echo "ERR: $i"
done
echo "Time: $TIME, Points: $PTS"
