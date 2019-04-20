#!/usr/bin/env perl

use strict;
use warnings;
use POSIX qw(strftime);

-d ".git" and -f "Makefile.PL" or die "Not a CPAN module repository";

my $status = `git status --porcelain`;
die "Unmerged changes present, stash or commit them:\n$status"
    if $status;
die "git command failed" if $?;

my @tags = `git tag`;

@tags = map { /^v\.(\d+\.\d+)$/ ? $1 : () } map { s/_//g; $_ } @tags;

my $lasttag = [sort { $b <=> $a } @tags]->[0];

print "Latest release = $lasttag\n";

$lasttag =~ /^(\d+\.\d\d)(\d\d)?$/ or die "Unsupported version format";

my $ver = $1 . '_' . sprintf "%02u", ($2 || 0) + 1;

cmd( "perl Makefile.PL" );

cmd( "make test" );

print "Assuming trial version $ver\n";

cmd( "git checkout -b ".strftime( "%Y%m-$ver", localtime ) );
my $sed = q{s/^\(our *$VERSION *= *\).*;$/\1'\''}.$ver.q{'\'';/};
cmd( qq{find lib -name \*.pm | xargs sed -i '$sed' } );
cmd( "git diff" );
cmd( "git commit -a -m '^_^ Version $ver released NOCODE'" );
cmd( "git tag v.$ver -m 'Experimental release'" );

cmd( "perl Makefile.PL" );
unlink "MANIFEST" or die "Failed to delete MANIFEST"
    if -f "MANIFEST";
cmd( "make manifest" );
cmd( "make dist" );

cmd( "git checkout -" );

sub cmd {
    system @_;
    $? and die "Command failed: @_";
};


