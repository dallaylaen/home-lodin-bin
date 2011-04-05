#!/usr/bin/perl -w

use strict;

=head1 DESCRIPTION

Config::Pref::Writer - saving engine. It MUST be readable by 
config::Pref::Parser.  

=cut

package Config::Pref::Writer;

use Carp;
use Config::Pref::Parser qw/:regexp/;

our $VERSION = 0.02;

=head2 new([$file])

Create a writer. No options yet. See C<file()> for details on argument. 

=cut

sub new {
	my ($class, $file) = @_;
	my $self = {};
	bless $self, $class;
	$self->file($file) if defined $file;
	return $self;
};

=head2 file([$file])

Write configuration to $file. $file can be a file name (scalar), 
a scalar ref (config will be written to the variable), or anything else
(will be treated as a file descriptor). 

=cut

sub file {
	my $self = shift;
	return $self->{_file} unless @_;
	my $file = shift;
	if ((defined $file) and !ref $file or ref $file eq 'SCALAR') {
		open my $fd, ">", $file 
			or croak __PACKAGE__.": cannot save file $file: $!";
		$file = $fd;
	};
	
	$self->{_file} = $file;
	return $self;
};

=head2 save($config, [$file])

Save $config to $file. See C<file()> for $file discussion. 

=cut

sub save {
	my ($self, $conf, $file) = @_;
	$self->file($file) if $file;
	my $fd = $self->file;
	$fd or croak ""; 

	foreach my $section ($conf->list) {
		foreach my $name (sort $conf->list($section)) {
			$self->writeHead($section, $name);
			$self->writePairs($conf->_get($section, $name));
		};
	};
};

=head2 writeHead ($section, [$name])

Internal. Write config section header. 

=cut

sub writeHead {
	my ($self, $section, $name) = @_;
	my $fd = $self->file;

	if (defined $name and $name ne '') {
		printf $fd "[%s %s]\n", escape($section), escape($name);
	} else {
		printf $fd "[%s]\n", escape($section);
	};
};

=head2 writePairs ($hash, [$defaults])

nternal. Print param=value pairs, omitting values that match defaults (to 
kill dupes). 

TODO: add saving of hashes and lists, at least 1 level. 

=cut

sub writePairs {
	my ($self, $hash, $black) = @_;
	my $fd = $self->file;

	$black ||= {};
	foreach (sort keys %$hash) {
		next if defined $black->{$_} and $black->{$_} eq $hash->{$_};
		printf $fd "%s = %s\n", escape($_), escape($hash->{$_});
	};
	print $fd "\n";
};

=head2 escape($str)

Internal. Create a value understandable by Config::Pref::Parser.

=cut

# anti-interpolate
sub escape {
	my $str = shift;
	if (ref $str eq 'ARRAY') {
		return "[".(join ", ", map {escape($_)} @$str)."]";
	} elsif (ref $str eq 'HASH') {
		my @out;
		foreach (sort keys %$str) {
			push @out, sprintf "%s:%s", escape($_), escape($str->{$_});
		};
		return "{".(join ", ", @out)."}";
	} else {
		$str =~ /^$re_bare$/ and return $str;
		$str =~ s/([^\w\d\s])/'\\x' . sprintf "%2x", ord $1/ge;
		$str =~ s/\n/\\n/sg;
		return "\"$str\"";
	};
};

1;
