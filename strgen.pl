#!/usr/bin/perl -w

use strict;

if (not (defined $ARGV[1]) or $ARGV[0] =~ /[^\d\s]/) {
	print STDERR "Usage: $0 <n> <string>\n";
	exit 1;
}

my $i = int shift; 
my $x = (shift) . "\n"; 

# adjust $x length to optimize printing
while (length $x < 1024) { 
	$i & 1 and print $x; 
	$x = $x.$x; 
	$i>>=1; 
};

# print the rest
while ($i-->0) { 
	print $x; 
}
