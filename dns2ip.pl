#!/usr/bin/perl -w

use Socket;

while (<STDIN>) {
	while (s/([a-z0-9\.\-_]+)//i) {
	    unless (fork) {
		$dns = $1;
		$ip = inet_ntoa(inet_aton ($dns) or next);
		print "$ip $dns\n";
	    };
	};
};

