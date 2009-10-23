#!/usr/bin/perl

use strict;
use warnings;

#
# Fetches weather from wunderground.com and displays in a format
# suitable for conky
#

use LWP::Simple;

my $station = "KHIO";
my $raw_weather = get("http://api.wunderground.com/auto/wui/geo/WXCurrentObXML/index.xml?query=" . $station);

if ($raw_weather =~ m/full>(.*?)<\/full/) {
  my $val = $1;
  print "$val\n";
}
if ($raw_weather =~ m/temperature_string>(.*?)<\/temperature_string/) {
  my $val = $1;
  $val =~ s/ F/°F/;
  $val =~ s/ C/°C/;
  print "  $val";
}
if ($raw_weather =~ m/weather>(.*?)<\/weather/) {
  my $val = $1;
  print " - $val\n";
}
if ($raw_weather =~ m/wind_string>(.*?)<\/wind_string/) {
  my $val = $1;
  $val =~ s/^From/Wind from/;
  print "  $val\n";
}
if ($raw_weather =~ m/pressure_string>(.*?)<\/pressure_string/) {
  my $val = $1;
  print "  $val\n";
}
if ($raw_weather =~ m/dewpoint_string>(.*?)<\/dewpoint_string/) {
  my $val = $1;
  $val =~ s/ F/°F/;
  $val =~ s/ C/°C/;
  print "  Dew point $val";
}
