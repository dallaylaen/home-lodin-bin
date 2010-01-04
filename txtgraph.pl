#!/usr/bin/perl -w

use strict;

my ($max, $min) = (0,0);

my @data;
while (<STDIN>) {
	/^(-?\d+)/ and push @data, $1;
	($1 > $max) and $max = $1;
	($1 < $min) and $min = $1;
};


#my @out;
#for (my $i = @data-1; $i-->1; ) {
#	$out[$i] = $data[$i] + ($data[$i-1] + $data[$i+1]) /2; 
#}; 

for (my $h = $max+1; $h-->$min -1; ) { 
	foreach my $i (@data) { 
	    print ($i > $h? "#":" "); 
	}; 
	print "\n"; 
}; 


