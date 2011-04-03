#!/usr/local/bin/perl

use strict;
use warnings;
use WWW::Mechanize;
use WWW::Shorten 'TinyURL';
use HTML::TableExtract;
use XML::Atom::Feed;
use XML::Atom::Entry;
use Encode;

use constant BASEHREF => 'http://www.f-kspc.co.uk/propertiesforsale/';
use constant MAXPRICE => 550000;
use constant MINPRICE => 200000;

our $DEBUG = 0;

my $f = XML::Atom::Feed->new;
$f->title( 'Houses for Colva and Stru' );

my $m = WWW::Mechanize->new();

my $r = $m->get( 'http://www.f-kspc.co.uk/propertiesforsale/propertysearch.cfm' );

die $r->message unless $m->success();
sleep(1);

print STDERR $r->content if $DEBUG;

$r = $m->submit_form(
    form_number =>  1,
    fields      =>  {
        SL      =>  'S',
        DR      =>  'L',
        PSort   =>  'Price_DESC',
    }
);

die $r->message unless $m->success();
sleep(1);

print STDERR $r->content if $DEBUG;

$r = $m->submit_form(
    form_number =>  1,
    fields      =>  {
        Area    =>  'St Andrews',
        Price   =>  'All',
    }
);

die $r->message unless $m->success();

my $html = $r->content;

my $t = HTML::TableExtract->new(
            keep_html => 1,
            depth => 2,
            count => 6,
        );

$t->parse( $html );

foreach my $table ( $t->table_states ) {
    foreach my $row ( $table->rows ) {
        my $href = $row->[1];

        next unless $row->[ 0 ] and $row->[ 0 ] =~ /bullet/;

        # on rows we care about first cell is empty
        shift @$row;

        my $price = $row->[ 3 ];
        $price =~ s/[^0-9]//g;

        next if ( $price >= MAXPRICE or $price <= MINPRICE );

        my $text = join( ' : ', @$row );
        $text =~ s/[\r\n]//g;
        $text =~ s/<[^>]+>//g;

        # should catch first two rows of table with no relevant data
        next unless $text =~ /[a-z]/;
        next if $text =~ /Type : Beds/;

        ($href) = ( $href =~ /href="([^"]+)/ );
        $href =~ s/ /%20/;

        my $uri = BASEHREF . $href;

        my $r = $m->get( $uri );
        if ( $m->success() ) {
            my $house_details = $r->content;
            warn $house_details;
            $text .= ' (Under Offer)' if $house_details =~ /underoffer/;
        }
        # lets not hammer the server eh?
        sleep( 1 );

        my $e = XML::Atom::Entry->new;
        $e->title( $text );
        $e->id( $uri );
        $e->content( $text );

        my $l = XML::Atom::Link->new();
        $l->href( $uri );

        $l->href( makeashorterlink( $l->href ) );

        $l->type('text/html');
        $l->rel('alternate');

        $e->add_link( $l );
        
        $f->add_entry( $e );
    }
}

print $f->as_xml;
