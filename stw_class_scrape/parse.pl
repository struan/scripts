#!/usr/local/bin/perl

use strict;
use warnings;
use Config::Simple;
use MIME::Lite;
use LWP::UserAgent;

use constant INTABLE => 1;
use constant INROW   => 2;
use constant RCFILE  => "$ENV{ HOME }/.stwclassifiedsrc";   

my %conf;

if ( -e RCFILE ) {
    Config::Simple->import_from( RCFILE, \%conf );
} else {
    die "Missing config file: " . RCFILE . "\n";
}

my $matches = $conf{ matches };

my @content;

my $u = new LWP::UserAgent;
my $r = $u->get( 'http://singletrackworld.com/forum/forum.php?id=3' );

unless ( $r->is_success ) {
    die "Failed to get forum: " . $r->code . ": " . $r->message;
}

@content = split( /\n/, $r->content );

my $status = 0;
my %items;

for ( @content ) {
    if ( $status == INTABLE and /(topic.php[^"]*)"[^>]*>([^<]*(?:$matches)[^<]*)</i ) {
        $items{ $2 } = $1;
    } elsif ( $status == INTABLE and /<\/table>/ ) {
        last;
    } elsif ( /table id="latest"/ ) {
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
