#!/bin/sh

#
#  This shell script ejects CD if mounted, mounts otherwise
#
#  (c) Lodin [Konstantin Uvarin] 2004 khedin@dragons.ru
#

device="/dev/cdrom";

# if [ -n "`grep --max-count 1 $device /proc/mounts`" ] || ! mount $device ; then
#    eject $device 
#fi

eject -t $device && mount $device || eject $device

