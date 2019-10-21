#!/usr/bin/env perl

use strict;
use warnings;
use POSIX qw(strftime);
use Getopt::Long;

my $want = 3;
GetOptions (
    "major" => sub { $want = 0 },
    "minor" => sub { $want = 1 },
    "patch" => sub { $want = 2 }, 
    "help"  => \&usage,
) or die "Bad options";

sub usage {
    print <<"USAGE"; exit 0;
$0 [options] - create a CPAN release of a git repository.
Options may include:
    --major - increase major version (before dot)
    --minor - increase minor version (1-2 digits after dot)
    --patch - increase patch version (3-4 digits after dot)
    By default, an unindexed version with an underscore is created
    --help  - this message
USAGE
};

-d ".git" and -f "Makefile.PL" or die "Not a CPAN module repository";

my $status = `git status --porcelain`;
die "Unmerged changes present, stash or commit them:\n$status"
    if $status;
die "git command failed" if $?;

my @tags = `git tag`;

@tags = map { /^v\.(\d+\.\d+)$/ ? $1 : () } map { s/_//g; $_ } @tags;

my $lasttag = [sort { $b <=> $a } @tags]->[0];
print "Latest release = $lasttag\n";

my $ver = inc_ver( $lasttag, $want );

cmd( "perl Makefile.PL" );

cmd( "make test" );

print "Creating new version $ver\n";

cmd( "git checkout -b ".strftime( "%Y%m-$ver", localtime ) )
    unless $want < 3;
my $sed = q{s/^\(our *$VERSION *= *\).*;$/\1'\''}.$ver.q{'\'';/};
cmd( qq{find lib -name \*.pm | xargs sed -i '$sed' } );

cmd( "vim -p Changes README.md" )
    if $want < 3;

cmd( "git diff | cat" );
print "Accept these changes for $ver (y/N)? ";
my $re = <STDIN>;
die "Commit aborted"
    unless $re and $re =~ /^y/;

cmd( "git commit -a -m '^_^ Version $ver released NOCODE'" );
cmd( "git tag v.$ver -m 'Experimental release'" );

cmd( "perl Makefile.PL" );
unlink "MANIFEST" or die "Failed to delete MANIFEST"
    if -f "MANIFEST";
cmd( "make manifest" );
cmd( "make dist" );

cmd( "git checkout -" )
    unless $want < 3;

sub cmd {
    system @_;
    $? and die "Command failed: @_";
};

sub inc_ver {
    my ($version, $todo) = @_;

    # TODO support 3-digits, too?
    my @ver = $version =~ /^(\d+)\.(\d\d)(\d\d)?_?(\d\d)?$/
        or die "Unsupported version format";

    die "Version overflow, do something"
        if ++$ver[$todo] >= 100;
    $#ver = $todo;
    $#ver ||= 1; # at least major.minor
    $_ ||= 0 for @ver;

    my $format = "%d.%02d";
    $format .= "%02d" if @ver >=3;
    $format .= "_%02d" if @ver >=4;
    
    return sprintf $format, @ver;
};
