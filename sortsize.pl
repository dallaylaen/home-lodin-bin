#!/usr/bin/perl 

# use strict;

my %mod = (
	'K', 1024,
	'KB', 1000,
	'M', 1024*1024,
	'MB', 1000*1000,
	'G', 1024*1024*1024,
	'GB', 1000*1000*1000,
);
$anymod = join ('|', keys %mod);

my @a;
while (<>) {
	push (@a, $_);
};

print sort {comparesize ($a, $b)} @a;

sub comparesize {

#	print ("cmp <$_[0]> <=> <$_[1]>\n");
	my ($x, $y) = @_;
#	print ("cmp <$x> <=> <$y>\n");
	
	
	
	$x =~ /(\d+(?:\.\d+)?)($anymod)?/;
#		print "$x => $1 $2; ";
		$xn = $1;
		$xn *= $mod{$2} if defined $mod{$2};
		
	$y =~ /(\d+(?:\.\d+)?)($anymod)?/;
#		print "$y => $1 $2\n";
		$yn = $1;
		$yn *= $mod{$2} if defined $mod{$2};

#	print "\n";	
	return $xn <=> $yn;
}
