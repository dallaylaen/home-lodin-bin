#!/bin/sh

dir=~/.adom.data

while :; do

if [ -f $dir/.adom.prc ]; then
	if ps -A | grep -E "adom\$"  ; then
		 exit;
	fi
	rm $dir/.adom.prc
fi

if [ -f $dir/backup.zip ]; then
	echo -e "\tRestoring from latest backup"
	unzip -uj $dir/backup.zip -d $dir/savedg/
fi

echo -e "\tStarting Adom..."
 adom

echo -e "\tBackup zip"
cp -uf $dir/backup.zip $dir/backup.zip.old

echo -e "\tCreating backup"
zip -uj $dir/backup.zip $dir/savedg/*

echo -e "Press Enter to continue, ^C exits"
read

done