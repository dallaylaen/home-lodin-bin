use warnings;
use strict;

=head1 NAME

Config::Pref::Parser 

=head1 DESCRIPTION

This is the default parser for Config::Pref. You probably don't want
to use it directly. See C<Config::Pref> instead.

=head1 FILE FORMAT

	[section]
	param = "value"
	param2 = "multiline\
	value"

	[section "name"]
	param = "value"
	# comment
	list = ["item", "item"]
	hash = {key: value, key2:value2}

=cut 

package Config::Pref::Parser;

use File::Basename qw/dirname/;
use IO::Handle;
use Carp;
use Exporter;

BEGIN {
	our $VERSION = 0.05;
	our @ISA = qw/Exporter/;
	our @EXPORT_OK;
	our %EXPORT_TAGS;

	my @regexp = map { '$re_'.$_ } qw/num id bare file qt list hash/;
	push @EXPORT_OK, @regexp;
	$EXPORT_TAGS{regexp} = \@regexp;
};

=head1 Functions 

=head2 new($config)

Create a parser. Changes will be forced into $config. 

C<Config::Pref> takes care to spoil a dummy config in
case of a bad file. Parser does not.

No options are yet supported.

=cut

sub new {
	my ($class, $cfg) = @_;
	my $self = {
		cfg => $cfg,
		state => '',
		section => '',
		name => '',
		param => undef,
		vars => {},
	};
	bless $self, $class;
	return $self;
};

=head2 run($file)

Read config specified by a filename, file handle, arrayref or scalar ref. 

=cut

sub run {
	my ($self, $data) = @_;

	return $self->runArray($data) if ref $data eq 'ARRAY';
	return $self->runArray([split m:$/:, $$data])
		if ref $data eq 'SCALAR';
	return $self->runFile($data);
};

=head2 runFile($filename || \*FH)

Process a file (either a handle, or a file name will do). A given parser 
instance will never touch the same file twice. 

=cut

sub runFile {
	my ($self, $file) = @_;
	# try opening file if not already opened
	# NOTE: $fd will be auto-closed when out of scope
	if (!ref $file) {
		# don't load files already loaded
		return if $self->{prune}->{$file}++;
		open (my $fd, "<", $file) 
			or die "cannot open file '$file': $!\n";
		$self->{fname} = $file;
		$file = $fd;
	};

	my $cont = '';
	$self->setSection("global");
	eval {
		local $_;
		while (<$file>) {
			$_ =~ s/^\s+|\s+$//gs; # chomp on steroid
			$cont .= $_;
			$self->readline($cont) and $cont = '';
		};
		$self->endSection();
	}; # end eval
	if ($@) {
		chomp $@;
		croak (sprintf "%s: %s in `%s':%s",
			__PACKAGE__, $@, $self->{fname} || $file,
			$file->input_line_number
		);
	};
}; # end sub run

=head2 runArray(\@list || @list)

Parse a list of lines as if they were in a file. 

=cut

sub runArray {
	my ($self, $data) = @_;
	
	my $cont = '';
	my $line = 0;
	$self->setSection("global");
	eval {
		foreach (@$data) {
			s/^\s+|\s+$//gs; # chomp on steroid
			$cont .= $_;
			$self->readline($cont) and $cont = '';
			$line++;
		};
		$self->endSection();
	}; # end eval
	if ($@) {
		chomp $@;
		croak (sprintf "%s: %s in list [%s]",
			__PACKAGE__, $@, $line
		);
	};
};

=head2 readline ($line)

Parse a single config line. Based on the content and the parser state, 
it may put a param into the parser, start a new section, or inclue a file.

This is the central routine. 

BUGS: 

Too long. Should be broken down via hash dispatch. 

Should detect continuation and return a "want more" indicator. 

=cut

#######################
#  These global REs are required for readline
#  $re_qt is central here
our $re_num = qr/-?[0-9]*\.?[0-9]+/;
our $re_id =  qr/[A-Za-z_][A-Za-z_0-9]*/;
our $re_bare = qr/$re_id|$re_num/o;
our $re_file = qr/[a-zA-Z0-9_\-\+\.\/]+/;
our $re_quot = qr/'(?:\\\.|[^\"])*'/m;
our $re_quod = qr/"(?:\\\.|[^\"])*"/m;
our $re_qt = qr/$re_bare|$re_quot|$re_quod/o;
our $re_list = _SPC(qr/( $re_qt ( , $re_qt )*)?/);
our $re_hash = _SPC(qr/( $re_qt : $re_qt (, $re_qt : $re_qt )*)?/);

#######################
#  What to do after a backslash (default is just escape the symbol)
my %slash = (
	"n" => "\n",
	"r" => "\r",
	"\n" => '',
);

=head2 readline ($line)

Try to parse a single line of config. 

Returns undef if line has been parsed, or a true value 
if continuation is requested. Dies on errors. 

This is for internal use really. 

readline() goes as follows: 

    1. Trim spaces. 
    2. Check comment/continuation. 
    3. Try various REs. If matched, alter self and return 0. 
    4. die if none matched. 

=cut

sub readline {
	my ($self, $line) = @_;

	# strip empty space
	$line =~ s/^\s+//;
	$line =~ s/[\s]+$//s;

	# comment or empty => skip 
	return "comment" if ($line =~ /^(\#|$)/);

	# request continuation
	return if ($line =~ /[,\\]$/);

	# param = value
	if ($line =~ m,^\s*($re_qt)\s*=\s*($re_qt)\s*$,) {
		die "Bad file format: no section specified\n" unless $self->{section};
		$self->{param}->{$1} = $self->interpolate($2);
		return "value";
	};
	# param = [ value, value ]
	if ($line =~ m,^\s*($re_qt)\s*=\s*\[\s*($re_list)\s*\]\s*$,) {
		die "Bad file format: no section specified\n" 
			unless $self->{section};

		my $param = $1;
		my $list = $2;
		
		my @values;
		if ($list =~ /\S/) {
			@values = map { 
				$self->interpolate($_) 
			} $list =~ m/\s*($re_qt)\s*(?:,|$)/g;
		};
		$self->{param}->{$param} = \@values;
		return "list";
	};

	# param = { key:value, key:value, ... }
	if ($line =~ m,^\s*($re_qt)\s*=\s*\{\s*($re_hash)\s*\}\s*$,) {
		die "Bad file format: no section specified\n" 
			unless $self->{section};

		my $param = $1;
		my $list = $2;
		my @values;
		if ($list =~ /\S/) {
			@values = map { 
				$self->interpolate($_) 
			} $list =~ m/\s*($re_qt)\s*(?:,|:|$)/g;
		};
	
		die "Odd number of entries in hash" if @values %2;
		$self->{param}->{$param} = {@values};
		return "hash";
	};
	# [section "name"] 
	if ($line =~ m,^\s*\[($re_id)\s*(?:\s+($re_qt)\s*)?\]$,) {
		$self->setSection($1, $self->interpolate($2));
		return "section";
	};

	# %include /path/to/file
	if ($line =~ m,^\%include\s+($re_qt)$,) {
		my $fname = $self->interpolate($1);
		unless ($fname =~ m,^/,) {
			# relative file name -- use dirname
			$fname = $self->getdir() ."/". $fname;
		}
		# do not include a file twice
		my $ofname = $self->{fname};
		$self->run($fname);
		$self->{fname} = $ofname;
		return "include";
	}; 

	die "Bad file format: unknown line type";
}; # end sub readline
# FIXME should it be shorter?

=head2 endSection()

Force changes cached inside parser into config. 

=cut

sub endSection {
	my ($self) = @_;
	if ($self->{section} and $self->{param}) {
		$self->{cfg}->add(
			$self->{section}, 
			$self->{name},
			$self->{param}
		);
	};
	$self->{param} = undef;
	$self->{section} = undef;
	$self->{name} = undef; 
};

=head2 setSection ($sectiuon [, $name])

Start a new section.

=cut 

sub setSection {
	my ($self, $section, $name) = @_;
	$self->endSection();
	$self->{section} = $section;
	$self->{name} = $name;
	$self->{param} = {};
};

=head2 interpolate($string)

Return a bareword "as is", and transform a quoted string 
to what it should mean.

=cut

sub interpolate {
	my ($self, $line) = @_;
	return $line unless $line;
	if ($line =~ /^\s*($re_bare)\s*$/) {
		return $1;
	};
	# quoted string
	# print STDERR "\tinter: quoted: $line\n";
	if ($line =~ /^\s*(['"])((?:\\.|[^\"])*)\1\s*$/) {
		$line = $2; 
		# This is: \n | \x0a | \012
		$line =~ s/\\(?:x([A-Fa-f\d]{2})|([0-3][0-7]{2})|(.))/_slash_subst($1, $2, $3)/ges;
		# TODO add variable interpolation
		return $line;
	};
	die "Bad file format: cannot parse string\n";
}; # end sub interpolate

#######################
#  

sub _slash_subst {
	my ($hex, $oct, $gen) = @_;
	defined $hex and return chr hex $hex;
	defined $oct and return chr oct $oct;
	return defined $slash{$gen} ? $slash{$gen} : $gen;
};

=head2 getdir()

When running a file, returns dirname of the file so that 
%include's work. 

=cut

sub getdir {
	my ($self) = @_;
	return dirname ($self->{fname} || '');
};


#######################
# Regexp transformer. Allows for implied \s* instead of " ".

sub _SPC {
	my $re = shift;
	$re =~ s/\s+/\\s*/gm;
	$re =~ s/\(([^?])/\(?:$1/gm;
	return qr/(?:$re)/m;
};

=head1 BUGS

Probably, lots of them.

A formal spec is still required.  

=head1 AUTHOR

Konstantin S. Uvarin, C<< <khedin at gmail.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2010 Konstantin S. Uvarin, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;

