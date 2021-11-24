#!/bin/sh

INTERVAL=$1
[ -z "$INTERVAL" ] && INTERVAL=120

while sleep "$INTERVAL"; do
    DEVICE=$(pacmd list-sinks | grep -i name: | grep bluez |\
        head -n 1 | sed 's/^.*<//; s/>.*$//')
    [ -z "$DEVICE" ] && continue

    echo "Found device: $DEVICE"

    PULSE_SOURCE="$DEVICE" play -q -n synth 0.1 sin 55 vol 0.0001
    # PULSE_SINK="$DEVICE" rec -t au - trim 0 1 >/dev/null 2>/dev/null
done
