#!/usr/bin/perl -w

use strict;

my $reply;

my @d = localtime;
my $log = "$ENV{HOME}/.whatwant/$d[6]/$d[5]/$d[4]/$d[3]$d[2]";
system "mkdir", "-p", "$log";

my $LOG;
open ($LOG, ">>", "$log/log");

my @q = (
	"Кто ты?\n",
	"Чего ты хочешь?\n"
);

my $i = 0; 
while (1) {
	print $q[$i % @q];
	last unless defined ($_=<>);
	print $LOG $q[$i % @q], $_;
	$i ++;
};

END{
    print "iterations: ", $i/@q, "\n";
    print "saved log: $log/log\n"
};