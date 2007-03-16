#!/usr/bin/perl -w

use strict;

my $time = 1;
defined eval {use Time::HiRes;} or $time = 0;

sub print_t {
	my $t;
	if ($time) {
		my ($sec, $micro) = Time::HiRes::gettimeofday;
		$micro = "000" . int($micro / 1000);
		$micro =~ /(...)$/;
		$t = strftime ("%Y-%m-%d %H:%M:%S.", localtime ($sec)) . $1 . " ";
	} else {
		$t = strftime ("%Y-%m-%d %H:%M:%S ", localtime);
	};
	
	print $t, @_;
};



use IO::Select;
use IO::Socket;

use POSIX qw(strftime);
$|=1;

my $sel = new IO::Select() or die $^E;
my %forward;
my %symbol;

foreach (@ARGV) {
	my ($lport, $host, $rport) = split /:/;
	my $serv = new IO::Socket::INET(Listen => 1, LocalPort => $lport) or die;
	$forward{$serv} = "$lport:$host:$rport";
	$symbol{$serv} = "port $lport -> $host:$rport";
	$sel->add ($serv);
	print_t ("[master] listening on port=$lport, target=$host:$rport\n");
}


my %mirror;
my ($buf, $bytes);
my @ready;

my $uid = 1;

while(@ready = $sel->can_read) {
	print_t ("[select returned]\n");
    foreach my $fh (@ready) {
	print_t ("[$symbol{$fh}] data ready\n");
         if (defined $forward{$fh}) {
                # Create a new socket
                my $sock = $fh->accept;
		my ($lport, $host, $rport) = split /:/, $forward{$fh};

		my $sock2 = new IO::Socket::INET (
			PeerHost=>$host, 
			PeerPort=>$rport,
			Proto => 'tcp',
		);
		unless ($sock2) { 
			print_t ("[master] $^E\n");
			close $sock;
			next;
			
		};

		my $fromhost = $sock->peerhost();
		$symbol{$sock}  = "($uid) $fromhost->$lport->$host:$rport";
		$symbol{$sock2} = "($uid) $host:$rport->$lport->$fromhost";
		print_t ("[$symbol{$fh}] Peer ($uid) joined\n");
		$uid++;

		$mirror{$sock} = $sock2;
		$mirror{$sock2} = $sock;

                $sel->add($sock, $sock2);
         } else {
                # Process socket

		$bytes = sysread ($fh, $buf, 4096);
		unless ($bytes) {
			close_all ($fh, $mirror{$fh});
			next;
		};
		print_t ("[$symbol{$fh}]: read $bytes bytes\n");
		$bytes = syswrite ($mirror{$fh}, $buf);
		print_t ("[$symbol{$mirror{$fh}}]: written $bytes bytes\n");
		printhex (20, $buf);
		unless ($bytes) {
			close_all ($fh, $mirror{$fh});
			next;
		};
         }
        }
    }

END {
	print_t "[main] Stop listening.\n";
}

sub printhex {
	my $n = shift;
	my $x = shift;

	while ($x =~ s/(.{1,$n})//s) {
		my @data = split (//, $1);
		my @out = ();
		for (my $i = $n; $i-->@data; ) {
			$out[$i] = "   ";
		};
		for (my $i = @data; $i-->0; ) {
			$out[$i] = sprintf ("%X%X ", ord($data[$i])/16, ord($data[$i])%16,  );
			$data[$i] =~ s/[^\x20-\x7F]/\./gs;
			$out[$n + $i] = $data[$i];
		};
		print (join '', @out, "\n");
	};
};

sub close_all {
	$sel->remove(@_);
	foreach my $i (@_) {
		close $i;
		# delete $mirror{$i};
		print_t ("[$symbol{$i}] detached\n");
	};
	#foreach my $i (@_) {
	#	delete $mirror{$i};
	#};
};

