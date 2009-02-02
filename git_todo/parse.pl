#!/usr/bin/perl

use strict;
use warnings;
use 5.010;

my ( $category, $prev_line, @indent_titles, %msg, %titles_out );

while ( <> ) {
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

for my $cat ( keys( %msg ) ) {
    say $cat;
    say $_ for @{ $msg{ $cat } };

    say ' ';
}
