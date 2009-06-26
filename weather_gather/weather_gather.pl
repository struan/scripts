#!/usr/local/bin/perl

use strict;
use warnings;
use URI;
use XML::Feed;
use Getopt::Long;
use AppConfig qw( :argcount :expand );

my $save;

my $config_file = _get_conf_file();

my $c = AppConfig->new( { GLOBAL => {
                                ARGCOUNT    =>  ARGCOUNT_ONE,
                                EXPAND      =>  EXPAND_ENV
                            }
                        }, qw( uri savefile )
        );

$c->file( $config_file ); 

GetOptions( "save" => \$save );

my $u = URI->new( $c->uri );

my $f = XML::Feed->parse( $u );
my $e = ($f->entries())[0];

my $title = $e->title;
my $body = $e->content->body;

my $time    = ( $title =~ /(\d+:\d+) (?:GMT|BST)/ )[0];
my $desc    = ( $title =~ /:\W+(\D+)\.\s\d+\x{b0}C/ )[0];
my $temp    = ( $title =~ /(\d+)\x{b0}C/ )[0];
my $wind_d  = ( $body =~ /Wind Direction: (\w+)/ )[0];
my $wind_s  = ( $body =~ /Wind Speed: (\d+)/ )[0];

# sometimes there's no description so indicate this
$desc     ||= 'N/A';

my $msg = "weather at $time was $desc, $temp C, $wind_d at $wind_s mph\n"; 
my $fh;

my @time = localtime;
my $file = $ENV{ 'HOME' } . '/.weather.dat';
$file = $c->savefile if $c->savefile;

if ( $save ) {
    open( $fh, ">$file" ) or die "Failed to open file: $!\n";
    print $fh join( '', @time[ 5, 4, 3 ] ) . "\n";
    print $fh $msg;
    close $fh;
} else {
    if ( -e $file ) {
        open( $fh, "$file" ) or die "Failed to open file: $!\n";
        my $prev = '';
        my $date = <$fh>;
        chomp $date;
        if ( $date eq join( '', @time[ 5, 4, 3 ] ) ) {
            $prev = <$fh>;
        }
        close $fh;
        $msg = $prev . $msg;
    }
    print $msg;
}

sub _get_conf_file {
    my $conf_file = shift;
    my @possible_locs = ( $ENV{HOME} . "/.weathergatherrc",
                          '/etc/weather_gatherrc' );

    unshift @possible_locs, $conf_file if $conf_file;

    for ( @possible_locs ) {
        return $_ if -e $_;
    }

    die "failed to find a configuration file";
}
