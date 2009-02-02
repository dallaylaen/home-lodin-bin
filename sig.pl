#!/usr/bin/perl -w

print <<'EOF';
Konstantin S. Uvarin            jabber:lodin@jabber.ru
EOF

open (INPUT, "$ENV{'HOME'}/.cookies") or exit(1);

$j=1;
while (<INPUT>) {
    /^\s*$/s and next;
    int rand $j++ == 0 and $out = $_;
};

$out =~ s/\\n/\n/sg;
print $out;

