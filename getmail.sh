#!/bin/sh


~/bin/runall >~/junknet/.dialuplog 2>&1 <<_ALL_FOLKS_
    date
    fetchmail
#    wget -t 1 -O $HOME/junknet/slash.htm "http://slashdot.org/" 
#    wget -t 1 -O $HOME/junknet/devslash.htm "http://developers.slashdot.org/" 
#    wget -t 1 -O $HOME/junknet/askslash.htm "http://ask.slashdot.org/" 
    date
_ALL_FOLKS_


