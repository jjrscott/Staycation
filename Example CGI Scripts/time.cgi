#!/usr/bin/perl

use strict;

use CGI qw/:standard *TR *table *td *div *ul *ol *li/;           # load standard CGI routines
# use CGI::Carp 'fatalsToBrowser';
use Data::Dumper;

print header(-type => "text/html", -charset => "utf-8");

my $time = localtime();

print start_html(-head=>meta({-http_equiv => 'Refresh', -content=> 1}),-title=>$time);

print div({-style=>'text-align: center; font-size: 20pt; margin: 50px auto'},"The time is ",div({-style=>'font-size: 50pt; margin: 20px auto'},$time));
print end_html();