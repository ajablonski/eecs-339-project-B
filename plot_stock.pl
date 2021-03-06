#!/usr/bin/perl -w


use strict;
use CGI qw(:standard);
use DBI;
use Time::ParseDate;
use Date::Parse;
use Date::Format;
use user;
use File::Copy;

BEGIN {
    $ENV{PORTF_DBMS}="oracle";
    $ENV{PORTF_DB}="cs339";
    $ENV{PORTF_DBUSER}="eab879";
    $ENV{PORTF_DBPASS}="w67iYahH";

    unless ($ENV{BEGIN_BLOCK}) {
        use Cwd;
        $ENV{ORACLE_BASE}="/raid/oracle11g/app/oracle/product/11.2.0.1.0";
        $ENV{ORACLE_HOME}=$ENV{ORACLE_BASE}."/db_1";
        $ENV{ORACLE_SID}="CS339";
        $ENV{LD_LIBRARY_PATH}=$ENV{ORACLE_HOME}."/lib";
        $ENV{BEGIN_BLOCK} = 1;
        $ENV{GDFONTPATH}="/usr/share/fonts/liberation";
        $ENV{GNUPLOT_DEFAULT_GDFONT}="LiberationSans-Regular";
        exec 'env',cwd().'/'.$0,@ARGV;
    }
};

use stock_data_access;

my $type = param('type');
my $symbol = param('symbol');
my $start = param('start');
my $end = param('end');

if (defined(param('start'))) {
    $start = str2time(param('start'));
} else {
    $start = 0;
}

if (defined(param('end'))) {
    $end = str2time(param('end'));
} else {
    $end = time;
}

if (!defined($type)) {
    $type = 'plot';
}

my $sqlString = "";
$sqlString .= "SELECT timestamp, close FROM ".GetStockPrefix()."StocksDaily ";
$sqlString .= " WHERE symbol=rpad(:1,16) AND timestamp BETWEEN :2 AND :3";
$sqlString .= " UNION ";
$sqlString .= "SELECT timestamp, close FROM $netID.newstocksdaily ";
$sqlString .= " WHERE symbol=rpad(:1,16) AND timestamp BETWEEN :2 AND :3";
my @rows;
eval {
    @rows = ExecStockSQL("2D",$sqlString,$symbol, $start, $end);
};
my $error = $@;

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
        print GNUPLOT "set xdata time\n";
        print GNUPLOT "set timefmt \"%s\"\n";
        if ($end - $start > 9000000) {
            print GNUPLOT "set format x \"\%m/\%y\"\n";
        } else {
            print GNUPLOT "set format x \"\%m/\%d/\%y\"\n";
        }
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
                        time2str("%D", $r->[0]),
                        $r->[1]
                    ]),
                ), "\n";
    }
    print "</table>";
    print end_html;
}



