#!/bin/sh

while :; do
    echo "***"
    echo "*** Press enter when ready"
    echo "***"
    read y || break

    STOP=
    trap "STOP=1" INT
    
    for i in `seq 60 -1 1`; do
        [ -z "$STOP" ] || break
        echo $i
        sleep 1
    done
    echo "***"
    echo "*** 10 seconds"
    echo "***"
    for i in `seq 10 -1 1`; do
        [ -z "$STOP" ] || break
        echo $i
        sleep 1
    done
    echo "***"
    echo "*** Time is up"
    echo "***"
done
