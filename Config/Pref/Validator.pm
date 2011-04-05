#!/usr/bin/perl -w

use strict;

=head1 DESCRIPTION

Config::Pref::Validator - validate config files using other config files.

=head1 VALIDATION FILE FORMAT

    # only allow known sections
    strict = 1

    # section parameters
    [section "mysection"]
    strict = "0"
    required = "1"

    # check values within a section using RE
    [values "server"]
    port = "\\d+"

=cut

package Config::Pref::Validator;
use Carp;

use base "Config::Pref";

=head2 load ()

Load is modified to test validator itself.

=cut

sub load {
	my $self = shift;
	# $self can be bareword, but load() returns an object.
	$self = $self->SUPER::load(@_); 
	$self->selfvalidator->validate($self);
	return $self;
};

=head2 validate($config)

Check if $config matches spec stored in the current one.

=cut

sub validate {
	my ($self, $other) = @_;
	my $opt = $self->global;

	# if strict: 
	# check nonlisted sections
	if ($opt->{strict}) {
		my %known = (global=>1);
		$known{$_} = 1 for (
			$self->list("section"), $self->list("values")
		);
		my @unknown = grep { !$known{$_} } $other->list;
		croak __PACKAGE__.": Unknown section(s) ".(join ", ", @unknown)
			if @unknown;
	};
	
	# TODO check sections

	# check values
	# A bit clumsy, so here's how it works
	# 
	foreach my $section ($self->list("values")) {
		my $regex = $self->get("values", $section);
		foreach my $name ($other->list($section)) {
			my $hash = $other->get($section, $name);
			foreach (keys %$hash) {
				next unless $regex->{$_};
				next if $hash->{$_} =~ /^$regex->{$_}$/;
				croak sprintf ( 
					"%s: [%s '%s']:%s doesn't match %s", 
					__PACKAGE__ , $section, $name, $_, 
					$regex->{$_},
				);
			};
		};
	}; # end check values
};

=head2 selfvalidator()

Return validator for config validator. 

=cut

# TODO: find a better name
{
my $main; 
sub selfvalidator {
	return $main if $main;

	$main = __PACKAGE__->new();
	$main->SUPER::load(\<<"CF");
	strict = 1
	[section "values"]
	[section "section"]
	strict = 1
	[values "section"]
	strict = "^|0|1"
	required = "^|0|1"
CF

	return $main;
};
};

1;

