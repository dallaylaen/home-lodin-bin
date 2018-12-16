#!/usr/bin/env perl

use strict;
use warnings;
my $mod = shift;

die "Usage: $0 <Module::Name>\n"
    unless defined $mod;

$mod =~ s@::@/@g;
$mod =~ s@(\.pm)?$@.pm@;

foreach (@INC) {
    -f "$_/$mod" or next;
    print "$_/$mod\n";
    exit 0;
};

die "Can't locate $mod in \@INC( @INC )";
