#!/usr/bin/perl -w -p

chomp; 

s/([^a-zA-Z0-9\_\-\/\x80-\xFF])/\\$1/g;

