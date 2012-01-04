#!/usr/bin/perl -w

use strict;
use utf8;
binmode STDIN, ":utf8";
binmode STDOUT, ":utf8";

my $lat   = 'qwertyuiop'.'asdfghjkl'.'zxcvbnm';
my $lat_p = '@#$%^&*_+'.'`[]\\;\',./'.'~{}|:"<>?';
my $rus   = 'йцукенгшщз'.'фывапролд'.'ячсмить';
my $rus_p = '"№;%:?*_+'.'ёхъ\\жэбю.' .'ЁХЪ/ЖЭБЮ,';

$lat .= $lat_p. uc $lat;
$rus .= $rus_p. uc $rus;

eval "sub conv { /[а-яё]/i ? y($rus)($lat) : y($lat)($rus) for \@_; \@_; }";
die $@ if $@;

while (<>) {
	print join "", conv(split /(\s+)/, $_);
};

