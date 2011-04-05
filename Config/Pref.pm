use warnings;
use strict;

=head1 NAME

Config::Pref - Yet another configuration format module. 

=head1 VERSION

Version 0.05

=head1 DESCRIPTION

The ultimate goal of this project is to access reasonably 
complex configuration files using as few keystrokes as possible. 

A configuration is made of sections, and a section is made of 
param=values pairs. 

Several named versions of a section may exist, with the unnamed one 
being treated as the default. 

When a section/name pair is requested, a hash is returned 
that contains all named instance's parameters, plus default
values that were not overridden. 

The assumptions are as follows:

=over

=item * Configuration is global accross one application most
of the time, but not always

=item * Getting a group of values as a hash is more natural then 
getting all values one by one

=item * Config file should be editable by human with no 
programming experience

=back

=head1 SYNOPSIS

=head2 Simple interface 

For the most time, only one config object per application is needed, 
so a C<cf()> function is exported to keep extra typing away. It returns a 
lazyli initialized default instance of C<Config::Pref>. 

    use Config::Pref;
    cf->load ("file");

    my $hsh = cf->get ("server", "localhost");
    print "port is ", $hsh->{port}, "\n";

    cf->set ("server", undef, "port", 5509);

    my $users = cf->section("user");
    # $users is now a hash with a parameter set for each known user

    foreach (cf->getsections()) {
	# ...
    };

=head2 OO interface

However, inside Config::Perl there are just objects, plain and simple. 
You can create them on a whim! 

    my $mycf = Config::Pref->new();
    $mycf->load('another/file');
    $mycf->get('section');
    # ...

=head1 DEFAULT FILE FORMAT

Writing parsers for other/existing formats is encouraged (especially 
a sensible XML scheme). 

The default parser is heavily inspired by Config::Gitlike.
A formal specification is still pending. 

Generally, a config looks like follows: 

	# this is a comment 
	# comments should take a whole line
	
	# We can include other config files
	%include "/etc/main.config"

	# local/config will be appended to current file's dirname
	%include "local/config"

	# a section begins with a '['section_type ['"'section_name'"']']'
	# inside a section, param = value pairs reside
	# values that are numbers or valid IDs ([a-z_][a-z_0-9]*) 
	# need not be quoted

	# defaults for section server
	[server]
	port = 12345
	docroot = "/usr/local/www"

	# specific values	
	[server "mydomain.org"]
	docroot = "/var/www"
	OS=linux

	# lists of values are allowed
	mailto = ["one@here.com", "two@there.com"]

	continue = "A line ending in \
	 is concatinated with the next line"
	continue_list = ["A", "list",
	"continued"]

	# dictionaries, or maps, or hashes are welcome:
	userports = { Fred: 8081, Barney: 8082 }

	# dictionaries and lists may not be nested.

=head1 EXPORT

=head2 cf()

Default config instance that will be created on demand. 

=head1 METHODS 

=cut

package Config::Pref;

require 5.6.0;

use Carp;
use Exporter;
use FindBin;

use Config::Pref::Parser;
use Config::Pref::Writer;

#############################
#  OO methods -- the core

=head2 new([$copyof])

Constructor. 

Config::Pref->new() will just create an empty config. 

Config::Pref->new($config) will create a copy of $config. 
$config->new() does the same (using ref $config as package). 

=cut

sub new {
	my ($class, $orig) = @_;
	if (ref $class) {
		$orig ||= $class;
		$class = ref $class;
	};
	# verbatim copy of $orig or empty
	my $self = $orig ? _cphash ($orig) : {sections => {},};
	bless $self, $class;
	return $self;
};

=head2 parser()

Return a new instance of config format parser. 

=cut

# TODO: add %options for XML or autodie or whatever
sub parser {
	my $copy = (ref shift)->new();
	return Config::Pref::Parser->new($copy);
};

=head2 reset()

Remove everything from config. 

=cut

sub reset {shift->{sections} = {}};

=head2 load($filename)

Parse a file using the default parser (Config::Pref::Parser). 
Subsequent loads will overwrite individual values, not the whole config.
Returns the config it was called on.

If the file is invalid, an exception prefixed with Config::Pref is thrown,
and the config is left intact.

=cut

sub load {
	my ($self, $file) = @_;
	$self = $self->new() unless ref $self;

	eval {
		# make sure we don't mess with existing values if 
		# the file is borked
		my $copy = (ref $self)->new ();
		my $parser = Config::Pref::Parser->new($copy);
		$parser->run ($file);
		$self->merge($copy);
	};
	if ($@) {
		chomp $@;
		croak "Config::Pref: $@";
	};

	return $self;
};

=head2 save($file)

Save config to a file, in format acceptable by load(). 

If a filename (i.e. scalar) is given, write to that file. A scalar ref
would mean writing into the scalar. Everything else is assumed to be a 
file handle (aka \*STDOUT). 

=cut

sub save {
	my ($self, $file) = @_;
	my $wr = Config::Pref::Writer->new();
	$wr->file($file);
	$wr->save($self);
};

=head2 lookup($project_name) 

Will look for a config file in several locations. Will load the 
existing files, overriding the former with the latter.

=cut

sub lookup {
	my ($self, $project) = @_;
	my @location = (
		"$FindBin::Bin/../etc/$project.cf",
		"$FindBin::Bin/../etc/$project/config",
		"$ENV{HOME}/.$project/config",
		"$ENV{HOME}/.$project.cf",
	);
	-f $_ and $self->load($_) for @location;
};

=head2 merge ($other_config)

Copy all values from another config. Return self.

=cut

sub merge {
	my ($self, $other) = @_;
	
	foreach my $section ($other->list()) {
		foreach my $name ($other->list ($section)) {
			$self->add ($section, $name, $other->_get($section, $name));
		};
	};
	return $self;
};

#############################
#  Basic access: get, set, add, sections, names

=head2 list([$section])

When called without arguments, will list all sections. "global" section
is always guaranteed to be present, and comes first. 

When called with section name as argumens, lists names of all instance
of the section. If no such sections exists, an empty list is returned. 
Otherwise an empty string ("the default values") is guaranteed to come first. 

=cut

sub list {
	my ($self, $name) = @_;
	unless (defined $name) {
		return (
			"global", grep { $_ ne "global" } 
			keys %{ $self->{sections} }
		);
	};

	return () unless (exists $self->{sections}->{$name});

	return ('', grep {$_ ne ''} keys %{ $self->{sections}->{$name} });
};

=head2 get($section, [$name])

Returns a set of config values from section $section. If no name 
is specified, default values are returned. Otherwise default values
are overridden by specific value.

=cut

sub get {
	my ($self, $section, $name) = @_;
	$name = '' unless defined $name;
	
	my $def = $self->{sections}->{$section}->{''} || {};
	my $spec = (
		length $name && $self->{sections}->{$section}->{$name} 
	) || {}; 

	# join hashes, last values override previous occurance
	my $hash = _cphash($def, $spec);

	return $hash;
};

sub _get {
	my ($self, $section, $name) = @_;
	$name = '' unless defined $name;
	
	my $spec = $self->{sections}->{$section}->{$name};

	# join hashes, last values override previous occurance
	my $hash = _cphash($spec);

	return $hash;
};

=head2 global([$var_name]) 

The special section "global" represents, well, global settings. 


=cut

sub global {
	my ($self, $name) = @_;
	my $ret = $self->get("global");
	return defined $name ? $ret->{$name} : $ret;
};

=head2 set($section, $name, $hash) 

Reset section to the values in hash. Note: name undef or "" must be
specified explicitly, just omitting is not enough (yet). 

=cut

##############################
#  we do a $%->%->$% here
#  to prevent storing real outer references in config
sub set {
	my ($self, $section, $name, $hash) = @_;
	$name = '' unless defined $name;

	$self->{sections}->{$section}->{''} ||= {};
	$self->{sections}->{$section}->{$name} = 
		_cphash ($hash);
	return $self;
};

=head2 add($section, $name, $hash) 

Update specified section by the values in hash. Note: name undef or "" must be
specified explicitly for the default, just omitting is not enough (yet). 

=cut

############################
#  merge new values into existing config
sub add {
	my ($self, $section, $name, $hash) = @_;
	$name = '' unless defined $name;
	my $old = $self->{sections}->{$section}->{$name} || {};

	$self->{sections}->{$section}->{''} ||= {};
	$self->{sections}->{$section}->{$name} = 
		_cphash( $old, $hash );
	return $self;
};

##################################
#  Access helpers

=head2 getSection ($section)

Get all section instances as one big hash, the default values will be 
automatically substituted into each instance.

=cut

sub getSection {
	my ($self, $section) = @_;
	my $ret = {};
	return undef unless defined $section;
	foreach my $name ($self->list($section)) {
		$ret->{$name} = $self->get($section, $name);
	};
	return $ret;
};

#############################
#  Here is a global instance of __PACKAGE__
#  *Just in case* the user won't need multiple configs over
#  a single application. 
#  It's initialized lazily
{
my $config;
sub cf (;$) {
	unless ($config) {
		$config = new (__PACKAGE__);
	};
	return $config;
};
};

#############################
#  begin
BEGIN {
	our $VERSION = 0.05;
	our @ISA = qw/Exporter/;
	our @EXPORT = qw/cf/;
};

#############################
#  Utility functions

#############################
#  This one merges several hashes, latter overriding the former, 
#  and replaces hash/array references with a copy thereof
sub _cphash {
	my %hsh = map { %$_ } @_;
	# ^^^^ foreach my $hsh (@_) { push @tmp, %$hsh }; %hsh = @tmp;
	foreach my $val (values %hsh) {
		$val = _deepcopy($val) if ref $val;
	};
	return \%hsh;
};

#############################
#  This is our own deepcopy with unicorns and princesses. 
#  It won't descent anything except plain hashes and arrays. 
#  Blessed references are copied as is. 

sub _deepcopy {
	my ($item) = @_;
	if (ref $item eq 'ARRAY') {
		return [map { _deepcopy($_) } @$item];
	};
	if (ref $item eq 'HASH') {
		return {
			map { $_ => _deepcopy($item->{$_}) } keys %$item,
		};
	};
	# refs, blessed vars, undefs, and scalars are returned as is.
	return $item;	
};

1;

=head1 BUGS

Probably lots of them, especially in the parser. 
The API is not stable yet. 

What if user defined sub cf {}? 

=head1 TODO

=head2 Add %ENV support

It should be possible to use ${HOME} or ${USER} in the config files. 

=head2 Using semicolon as separator

Can we somehow use semicolons instead of \\n's? Probably. 
Just not "miss;something"

=head2 Part-line comments

Writing comments after a definition or whatever should be possible.

=head2 XML config variant 

Add equivalent XML format and parser for that. E.g: 

	<config section="sect_name" id="instance_name">
	<item name="param">value</item>

=head2 Inheritance and linkage between sections

This is for 2.0, probably. 

Make a section instance named "Fred" inherit 
from "Sally" before resorting to defaults. We'll need to check loops there!

Make a parameter in a section address another section as a whole. Like 
C<defaultserver = %server "mydomain.com">
This would make arbitrarily complex configs possible.

=head1 AUTHOR

Konstantin S. Uvarin, C<< <khedin at gmail.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2010-2011 Konstantin S. Uvarin, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

