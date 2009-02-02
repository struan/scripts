use strict;
use warnings;

use Git;

chdir '/c/Documents and Settings/struan.donald/My Documents/docs/git/' ;

my ( $category, $prev_line, $indent_level, %msg, $todo );

$todo = '';

open TODO, 'TODO.txt' or die "Failed to open TODO.txt: $!\n";
while ( <TODO> ) {
    chomp;
    if ( /^[A-Z0-9][A-Z0-9 ]+/ ) {
        $category = $_;
        $todo .= "$_\n";
        next;
    }

    if ( /^\s+X/ ) {
        unless( exists ( $msg{ $category } ) ) {
           $msg{ $category } = [];
        }

        push( @{ $msg{ $category } }, $_ );
    } else {
        $todo .= "$_\n";
    }
}
close TODO;

open TODO, '>TODO.txt' or die "Failed to open TODO.txt for writing: $!\n";
print TODO $todo;
close TODO;

my $msg = '';
for my $cat ( keys( %msg ) ) {
    $msg .= "$cat\n";
    $msg .= "$_\n" for @{ $msg{ $cat } };
    $msg .= "\n";
}

my $r = Git->repository( '.' );

print $r->command( 'add', 'TODO.txt' ) ."\n";
my $out = $r->command( 'commit', "-m $msg" );

print $out;

