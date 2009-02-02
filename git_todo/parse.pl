#!/usr/bin/perl

use strict;
use warnings;
use 5.010;

my ( $category, $prev_line, $indent_level, %msg );

while ( <> ) {
    chomp;
    if ( /^[A-Z0-9 ]+$/ ) {
        $category = $_;
        next;
    }

    if ( /^\s+X/ ) {
        unless( exists ( $msg{ $category } ) ) {
           $msg{ $category } = []; 
        }

        push( @{ $msg{ $category } }, $_ );
    }
}

for my $cat ( keys( %msg ) ) {
    say $cat;
    say $_ for @{ $msg{ $cat } };

    say ' ';
}
