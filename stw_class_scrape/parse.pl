#!/usr/bin/perl

use strict;
use warnings;
use MIME::Lite;
use LWP::UserAgent;

use constant INTABLE => 1;
use constant INROW   => 2;

my $matches = 'cotic|soda|\bti\b|titanium';

my @content;

my $u = new LWP::UserAgent;
my $r = $u->get( 'http://singletrackworld.com/forum/list.php?f=5&menu=16' );

unless ( $r->is_success ) {
    die "Failed to get forum: " . $r->code . ": " . $r->message;
}

@content = split( /\n/, $r->content );

my $status = 0;
my %items;

for ( @content ) {
    if ( $status == INTABLE and /(read.php[^"]*)&PHPSE[^"]*"[^>]*>([^<]*(?:$matches)[^<]*)</i ) {
        $items{ $2 } = $1;
    } elsif ( $status == INTABLE and /<\/table>/ ) {
        last;
    } elsif ( /PhorumListTable/ ) {
        $status = INTABLE;
    }
}

# for ( keys %items ) { print "$_\n"; }

if ( %items ) {
    my $msg;
    
    $msg .= $_ .
            "\n\thttp://singletrackworld.com/forum/" . 
            $items{ $_ } . 
            "\n\n"
            for keys %items;

    my $m = MIME::Lite->new(
        From    =>  'classifieds@spooky.exo.org.uk',
        To      =>  'struan@exo.org.uk',
        Cc      =>  'struan@spooky.exo.org.uk',
        Subject =>  'Classifieds matches',
        Data    =>  $msg,
    )->send;
}
