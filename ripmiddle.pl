#!/usr/bin/perl  -w

$first=14;
$last=17;

while (<>) {
	/^(.{0,$first})(.*?)(.{0,$last}\n?)$/s;
	print( $1, 
		(length $2 >3)? '...' : $2,
		$3);	
};

