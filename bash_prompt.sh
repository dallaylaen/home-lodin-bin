#!/bin/sh

# The old one :)
# export PS1='\n\e[0;30;47m[\h] \e[0;32m[\t] \u \w\e[0m\n\s$ '

# some functions
GIT_BRANCH="git rev-parse --abbrev-ref HEAD 2>/dev/null | sed 's/\(.*\)/[\1] /'"
PERL="perl -we '\$^X =~ m#/(?:perl-)?([^/]+)/bin/perl# and print qq{pl=\$1 }'"

NOCOLOR='\[\e[0m\]'
RED='\[\e[0;31m\]'
GREEN='\[\e[0;32m\]'
BLUE='\[\e[0;34m\]'
ON_GREY='\[\e[47m\]'
GREY_RED='\[\e[0;30;47m\]'
#   PS1="${NOCOLOR}\n[\$(date +'%a %H:%M:%S') ${RED}\$(git_branch_color)${NOCOLOR}\\w]\n\\s\\\$ "

LAST_ERROR='$(echo " \[\e[0;37;41m\]\$?=$?\[\e[0m\]" | grep "=[1-9]")'
[ -z "$DISPLAY" ] && WINTITLE='' || WINTITLE='\033]0;\u@\h: \w\007'
# [ -z "`who am i`" ] && SHOW_HOST="$ON_GREY[\\u]$NOCOLOR"\
#     || SHOW_HOST="$GREY_RED[\\u@\\h]$NOCOLOR"
SHOW_HOST="$BLUE$ON_GREY[home]$NOCOLOR"

PS1="$WINTITLE\\n$SHOW_HOST$LAST_ERROR $BLUE[\\D{%a %H:%M:%S}] \$($PERL)$GREEN\$($GIT_BRANCH)$BLUE\w$NOCOLOR\\n\\s\$ "
export PS1
