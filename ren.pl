#!/usr/bin/perl -w

while (<>) {
    chomp;
    s/"/\\"/g;
    if (/^(\S+).(mp3|ogg)\s+(.*)$/) {
	$ext = $2;
	$num = $1;
	$old = "$num.$ext";
	$name = $3;
	$name =~ s/ /_/g;
	$new = "$num-$name.$ext";
        print "moving \"$old\" --> \"$new\"\n";
        system "mv \"$old\" \"$new\"";
    };
};
