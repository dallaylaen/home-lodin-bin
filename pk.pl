#!/usr/bin/perl -w

use Net::POP3;

defined $ARGV[0] 
    and $n=int $ARGV[0]
     or $n = 1;

$pop = Net::POP3->new("mail.dragons.ru");

$pop->login('khedin.drg', 'oitWooco');

print "deleting $n messages...\n";

while ($n--) {
    $pop->delete($n) 
	and print " $n"
	or print " WTF? $n NOT deleted!\n";    
};

$pop->quit();

