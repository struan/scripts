use strict;
use warnings;

use Git;

chdir '/c/Documents and Settings/struan.donald/My Documents/docs/git/' ;

my ( $category, $prev_line, @indent_titles, %msg, %titles_out, $todo );

$todo = '';

open TODO, 'TODO.txt' or die "Failed to open TODO.txt: $!\n";
while ( <TODO> ) {
    chomp;
    if ( /^[A-Z0-9 ]+$/ ) {
        $category = $_;
        @indent_titles = ();
        next;
    }

    if ( $prev_line and /^\s+/ ) {
        my ( $indent ) = m/^(\s+)\S/;
        my ( $prev_indent ) = ( $prev_line =~ m/^(\s+)\S/ );

        my $d = length( $indent ) - length( $prev_indent );

        if ( $d > 0 ) {
            push @indent_titles, $prev_line;
        } elsif ( $d < 0 ) {
            pop @indent_titles;
        }
    }

    if ( /^\s+X/ ) {
        my $title = $indent_titles[ -1 ] if ( @indent_titles );
        
        unless( exists ( $msg{ $category } ) ) {
           $msg{ $category } = []; 
        }

        if ( $title and not exists $titles_out{ join( ':', @indent_titles ) } ) {
            push( @{ $msg{ $category } }, $title );
            $titles_out{ join( ':', @indent_titles ) }++;
        }
        push( @{ $msg{ $category } }, $_ );
    }

    $prev_line = $_;

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

