#!/usr/bin/perl -w

# Markov algorithm parser
# Rules are read as find->repl (continue) or find-.repl (stop)
 
while (defined($_ = <>)  && chomp && $_ ne ".") {

	if (/(.*?)(-[.>])(.*)/) {
		@find = ($1, @find);
		@flag = ($2, @flag);
		@repl = ($3, @repl);
	};
};

$i = @find;
while ($i--) {
	print($find[$i], $flag[$i], $repl[$i], "\n");
};

while (defined($_ = <>)  && chomp && $_ ne ".") { 
	print ($_, "\n");
	$i=@find;
	while ($i--) {
		if (s/\Q$find[$i]\E/$repl[$i]/) {
			print ($_, "\n");
			if ($flag[$i] eq "-.") {$i=0} else {$i=@find};
		};
	};      	
};

