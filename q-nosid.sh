#!/bin/bash
############################################
# NoSiD - no-dashi dialer v0.3             #
# (c)2004 no-dashi, original version       #
# (c)2004 Anthony Ivanoff, current version #
#                                          #
# Released under GPLv2                     #
############################################

upon_connect () 
{
    chat -t 60 -E ABORT BUSY ABORT DIALTONE ABORT ANSWER '' ATM1L1 OK \
'ATDP$PHONE' 'ogin:' '$USNAME' 'word:' '$PASSWD'

    tcpwatch.sh >> ~/.ppplog    
     fetchmail 
        killall -HUP pppd
}


d()
{

    echo starting pppd at `date` > ~/.ppplog
    echo -e \=\> "\033[0;33mRetry #$I\033[0;0m" \<\=
    echo \=\> Dialing...
    pppd /dev/modem defaultroute ipcp-accept-local ipcp-accept-remote nodetach \
    connect upon_connect

    # echo $USNAME $PHONE $PASSWD
    # killall nullmailer-send
    echo Connection terminated at `date` >> ~/.ppplog
    I=$(($I + 1))
}

 I=1
 ACCOUNT=$1

 USNAME=` grep -m 1 "user$ACCOUNT=" ~/.dialrc  | sed s/user$ACCOUNT=//`
 PHONE=`  grep -m 1 "tel$ACCOUNT="  ~/.dialrc  | sed s/tel$ACCOUNT=//`
 PASSWD=` grep -m 1 "pass$ACCOUNT=" ~/.dialrc  | sed s/pass$ACCOUNT=//`

d

exit 0

