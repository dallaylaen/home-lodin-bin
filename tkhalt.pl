#!/usr/bin/perl -w

use Tk;

my $main_window = MainWindow->new(
	-background=>"cyan"
);

$main_window->configure(
	-background=>'#e0e0e0', 
	-foreground=>'#000040',
	
);

$main_window->title("Halting computer...");

$main_window->Button(
	-background=>"red",
	-text=>"Halt",
	-command=>sub{
		exec "halt" ;
	}
)->pack(
	-side=>'left',
	#-fill=>'x'
);

$main_window->Button(
	-background=>"red",
	-text=>"Restart",
	-command=>sub{
		exec "shutdown -r now" ;
	}
)->pack(
	-side=>'left',
	#-fill=>'x'
);

$main_window->Button(
#	-background=>"red",
	-text=>"Cancel",
	-command=>sub{
		$main_window->destroy() ;
	}
)->pack(
	-side=>'left',
	#-fill=>'x'
);

$main_window->minsize(qw(200 30));
$main_window->maxsize(qw(200 30));

MainLoop;
