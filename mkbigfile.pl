#!/usr/bin/perl -w

$mb = "0123456789ABCDEF"; # 16
$mb = "$mb$mb$mb$mb"; #64
$mb = "$mb$mb$mb$mb"; #256
$mb = "$mb$mb$mb$mb"; #1024

$mb = "$mb$mb$mb$mb"; # 4k
$mb = "$mb$mb$mb$mb"; # 16k
$mb = "$mb$mb$mb$mb"; # 64 k
$mb = "$mb$mb$mb$mb"; # 256k
$mb = "$mb$mb$mb$mb"; # 1024K


$size = int $ARGV[0] or die ("please specify file's size in MB");

while ($size-->0) {
    print $mb;
};

