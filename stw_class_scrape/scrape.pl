#!/usr/bin/perl

use strict;
use warnings;
use LWP::UserAgent;

my $u = new LWP::UserAgent;
my $r = $u->get( 'http://singletrackworld.com/forum/list.php?f=5&menu=16' );


