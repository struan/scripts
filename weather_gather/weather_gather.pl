#!/usr/local/bin/perl5.10.1

use Modern::Perl;
use HTML::TableExtract;
use LWP::Simple;

use Getopt::Long;                                                               
use AppConfig qw( :argcount :expand );                                          
                                                                                
my ( $debug, $save, $time, $summary );                                                                       
                                                                                
my $config_file = _get_conf_file();                                             
                                                                                
my $c = AppConfig->new( { GLOBAL => {                                           
                                ARGCOUNT    =>  ARGCOUNT_ONE,                   
                                EXPAND      =>  EXPAND_ENV                      
                            }                                                   
                        }, qw( uri savefile )                                   
        );                                                                      
                                                                                
$c->file( $config_file );                                                       

my @time = localtime;
my $file = $ENV{ 'HOME' } . '/.weather.dat';                                    
$file = $c->savefile if $c->savefile;
                                                                                
GetOptions( "save" => \$save, "time=s" => \$time, "debug" => \$debug );

my $uri = 'http://www.metoffice.gov.uk/weather/uk/ta/leuchars_latest_weather.html';
my $content = get( $c->uri );

my $t = HTML::TableExtract->new(
            keep_html => 1,
            depth => 0,
            count => 1,
        );

$t->parse( $content );

foreach my $table ( $t->tables ) {
    foreach my $row ( $table->rows ) {
        next unless $row->[1] and $row->[1] =~ /$time/;

        my ( $weather )     = ( $row->[2] =~ /alt="([^"]*)"/ );
        my ( $temp )        = ( $row->[3] =~ /(-?\d+\.\d+)/ );
        my ( $wind_dir )    = ( $row->[4] =~ /(\w+)/ );
        my ( $wind_speed )  = ( $row->[5] =~ /(\d+)/ );
        
        $summary ="weather at $time was $weather, $temp C, $wind_speed mph from $wind_dir\n";
           
        last;
    }
}

if ( $debug ) {
    say $summary;
} elsif ( $save ) {                                                                  
    open( my $fh, ">$file" ) or die "Failed to open file: $!\n";                                               
    print $fh join( '', @time[ 5, 4, 3 ] ) . "\n";
    print $fh $summary;                                                             
    close $fh;                                                                  
} else {                                                                        
    if ( -e $file ) {                                                           
        open( my $fh, "$file" ) or die "Failed to open file: $!\n";                
        my $prev = '';
        my $date = <$fh>;                                                     
        chomp $date;                                                            
        if ( $date eq join( '', @time[ 5, 4, 3 ] ) ) {                          
            $prev = <$fh>;                                                      
        }                                                                       
        close $fh;                                                              
        $summary = $prev . $summary;                                                    
    }                                                                           
    print $summary;                                                                 
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
