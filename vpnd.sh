#!/bin/sh

log=$HOME/vpn.log
pidf=/tmp/vpnd.pid

if [ "$1" != hup ]; then
	nohup sh $0 hup $* >$log 2>&1 &
	exit
fi

shift

echo $$ > $pidf

while [ "$$" == "`cat $pidf`" ]; do 
	# if there's a connection, wait
	echo "If there's a connection, wait..."
	while ifconfig ppp0>/dev/null; do sleep 1; done
	
	echo "*"
	echo "*"   [$$]: Starting VPN connection to $tun. 
	echo "*"	 
	echo "*"   Options: $*
	echo "*"   time: `date +'%d.%m %H:%M:%S'`
	echo "*"
	
	date 
	/usr/sbin/pppd nodetach $*
	sleep 1;
done 

