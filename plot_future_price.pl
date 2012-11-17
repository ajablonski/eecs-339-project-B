#!/usr/bin/perl -w


use strict;
use CGI qw(:standard);
use DBI;
use Time::ParseDate;
use Date::Parse;
use Date::Format;
use user;
use File::Copy;

my $type = param('type');
my $symbol = param('symbol');
my $steps = param('futureSteps');

if (!defined($steps)) {
      $steps = 7;
}

if (!defined($type)) {
    $type = 'text';
}

if (!defined($symbol)) {
    $symbol = 'AAPL';
}

system "./get_data.pl --notime --close $symbol > _data.in";
system "./time_series_project _data.in $steps AR 16 > _future_data.in 2>/dev/null";

open DATA, "_future_data.in" or die $!;
my @rows;
my $i = 0;
while(<DATA>) {
  chomp;
  my @data = split;
  if(int($data[2]) != 0) {
    $rows[$i][0] = $data[0];
    $rows[$i][1] = $data[2];
    $i += 1;
  }
}

if ($type eq "plot") {
    print header(-type => 'image/png', -expires => '-1h' );
    if (@rows != 0) { 
# This is how to drive gnuplot to produce a plot
# The basic idea is that we are going to send it commands and data
# at stdin, and it will print the graph for us to stdout
#
#
        open(GNUPLOT,"| gnuplot") or die "Cannot run gnuplot";

        print GNUPLOT "set term png\n";           # we want it to produce a PNG
        print GNUPLOT "set output\n";             # output the PNG to stdout
        #print GNUPLOT "set xdata time\n";
        #print GNUPLOT "set timefmt \"%s\"\n";
        #if ($end - $start > 9000000) {
        #    print GNUPLOT "set format x \"\%m/\%y\"\n";
        #} else {
        #    print GNUPLOT "set format x \"\%m/\%d/\%y\"\n";
        #}
        print GNUPLOT "plot '-' using 1:2 with linespoints\n"; # feed it data to plot
        foreach my $r (@rows) {
            print GNUPLOT $r->[0], "\t", $r->[1], "\n";
        }
        print GNUPLOT "e\n"; # end of data

#
# Here gnuplot will print the image content
#

        close(GNUPLOT);
    } else {
        binmode STDOUT;
        copy "./nodata.png", \*STDOUT;
    }
} else {
    print header(-type => 'text/html', -expires => '-1h' );
    print start_html;
    print "<table border=1>";
    print th(["Date", "Price"]);
    foreach my $r (@rows) {
        print   Tr(
                    td([
                        $r->[0],
                        $r->[1]
                    ]),
                ), "\n";
    }
    print "</table>";
    print end_html;
}


















