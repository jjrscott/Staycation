#!/usr/bin/perl

use strict;

my $text;
BEGIN
{
    $text = join "\n", <STDIN>;
}

use CGI qw/:standard *TR *table *td *div *ul *ol *li/;           # load standard CGI routines
# use CGI::Carp 'fatalsToBrowser';
use Data::Dumper;

print header(-type => "text/plain", -charset => "utf-8");

print Dumper(\%ENV, $text);

