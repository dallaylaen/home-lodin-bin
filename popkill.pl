#!/usr/bin/perl -w

use Net::POP3;

$pop = Net::POP3->new("mail.dragons.ru");

$pop->login('khedin.drg', 'oitWooco');

$pop->delete(1);

$pop->quit();

