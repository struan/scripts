#!/usr/local/bin/perl

use strict;
use warnings;
use URI;
use Web::Scraper;
use WWW::Mechanize;
use WWW::Shorten 'TinyURL';
use HTML::TableExtract;
use XML::Feed;
use XML::Atom::Feed;
use XML::Atom::Entry;
use Encode;

# the URI changed but as we used it as an id we need to 
# stick to the old one for that to enable the comparison
# stuff to work in rss2mail. This is a kludge :(
use constant BASEHREF => 'http://www.f-kspc.co.uk/';
use constant BASEID => 'http://www.f-kspc.co.uk/propertiesforsale/';
use constant MAXPRICE => 550000;
use constant MINPRICE => 200000;
use constant SAVILS_RSS => 'http://search.savills.com/rss/property-for-sale/scotland/fife/ky16/gbp';
use constant PM_URI => 'http://www.primelocation.com/for-sale/property/fife/st-andrews/newest/?page_size=50';

our $DEBUG = 0;

my $f = XML::Atom::Feed->new;
$f->title( 'Houses for Colva and Stru' );

my $m = WWW::Mechanize->new();

my $r = $m->get( 'http://www.f-kspc.co.uk/property-search.cfm' );

die $r->message unless $m->success();
sleep(1);

print STDERR $r->content if $DEBUG;

$r = $m->submit_form(
    form_number =>  1,
    fields      =>  {
        SL      =>  'S',
        DR      =>  'L',
        PSort   =>  'Price_DESC',
        SArea    =>  'St Andrews',
        Price   =>  'All',
    }
);

die $r->message unless $m->success();

my $html = $r->content;

my $t = HTML::TableExtract->new(
            keep_html => 1,
            depth => 1,
            count => 2,
        );

$t->parse( $html );

foreach my $table ( $t->table_states ) {
    foreach my $row ( $table->rows ) {
        my $href = $row->[0];

        next unless $row->[ 0 ] and $row->[ 0 ] =~ /margin-left: 10p/;

        my $price = $row->[ 3 ];
        $price =~ s/[^0-9]//g;
        $price ||= 0;
        $price = int( $price );

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
        my $id  = BASEID . $href;

        my $r = $m->get( $uri );
        if ( $m->success() ) {
            my $house_details = $r->content;
            $text .= ' (Under Offer)' if $house_details =~ /under\s*offer/i;
            $text .= ' (Sold)' if $house_details =~ /sold.gif/;
        }
        # lets not hammer the server eh?
        sleep( 1 );

        my $e = XML::Atom::Entry->new;
        $e->title( $text );
        $e->id( $id );
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

my $s = XML::Feed->parse( URI->new( SAVILS_RSS ) );
if ( $s && $s->can( 'entries' ) ) {
    foreach my $entry ( $s->entries ) {
            my ( $price, $text ) = ( $entry->content->body =~ /^([^.]*)\.(.*)$/ );
            my $orig_price = $price;

            $price =~ s/&#\d+;//;
            $price =~ s/[^0-9]//g;
            $price ||= 0;
            $price = int( $price );

            next if ( $price >= MAXPRICE or $price <= MINPRICE );

            $text =~ s/[\r\n]//g;
            $text =~ s/<[^>]+>//g;
            $text = "$text : $orig_price";

            my $uri = $entry->link;
            my $id  = $entry->link;

            my $r = $m->get( $uri );
            if ( $m->success() ) {
                my $house_details = $r->content;
                $text .= ' (Under Offer)' if $house_details =~ /under\s*offer/i;
                $text .= ' (Sold)' if $house_details =~ /sold.gif/;
            }
            # lets not hammer the server eh?
            sleep( 1 );

            my $e = XML::Atom::Entry->new;
            $e->title( $entry->title . " : $price" );
            $e->id( $id );
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

my $houses = scraper {
    process "ul.listing-results > li", "houses[]" => scraper {
        process "a.pl-list-res-address", address => 'TEXT',
        process "strong.pl-list-res-attr", details => 'TEXT',
        process "a.pl-list-res-address", uri => '@href',
        process "a.pl-list-res-price", price => 'TEXT',
    }
};

my $res = $houses->scrape( URI->new( PM_URI) );

for my $house ( @{$res->{houses}} ) {
    my $orig_price = $house->{price};
    my $price = $orig_price;

    $price =~ s/&#\d+;//;
    $price =~ s/[^0-9]//g;
    $price ||= 0;
    $price = int( $price );

    next if ( $price >= MAXPRICE or $price <= MINPRICE );

    my $text = sprintf( "%s, %s: %s", $house->{address}, $house->{details}, $orig_price );
    my $uri = $house->{uri}->as_string;

    my $e = XML::Atom::Entry->new;
    $e->title( $house->{address} . " : $price" );
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

print $f->as_xml;
