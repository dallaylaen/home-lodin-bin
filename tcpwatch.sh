#!/bin/sh

/usr/sbin/tcpdump -i ppp0 \
'tcp[tcpflags] & (tcp-syn|tcp-fin) != 0 and not src and dst net 127'

