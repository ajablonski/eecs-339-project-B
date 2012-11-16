#!/usr/bin/perl -w 

use strict;
use CGI qw(:standard);
use DBI;
use Time::ParseDate;
use Date::Parse;
use Date::Format;
use user;

#$#ARGV==2 or die "usage: shannon_ratchet.pl symbol initialcash tradingcost\n";

#($symbol, $initialcash, $tradecost) = @ARGV;

my $symbol = param('symbol');
my $initialcash = param('initialcash');
my $tradecost = param('tradecost');
my $start = param('start');
my $end = param('end');

my $lastcash=$initialcash;
my $laststock=0;
my $lasttotal=$lastcash;
my $lasttotalaftertradecost=$lasttotal;

open(STOCK, "./get_data.pl --close $symbol --from $start --to $end |");


my $cash=0;
my $stock=0;
my $total=0;
my $totalaftertradecost=0;

my $day=0;



while (<STOCK>) { 
  chomp;
  my @data=split;
  my $stockprice=$data[1];

  my $currenttotal=$lastcash+$laststock*$stockprice;
  if ($currenttotal<=0) {
    exit;
  }
  
  my $fractioncash=$lastcash/$currenttotal;
  my $fractionstock=($laststock*$stockprice)/$currenttotal;
  my $thistradecost=0;
  if ($fractioncash >= 0.5 ) {
    my $redistcash=($fractioncash-0.5)*$currenttotal;
    if ($redistcash>0) {
      $cash=$lastcash-$redistcash;
      $stock=$laststock+$redistcash/$stockprice;
      $thistradecost=$tradecost;
    } else {
      $cash=$lastcash;
      $stock=$laststock;
    } 
  }  else {
    my $redistcash=($fractionstock-0.5)*$currenttotal;
    if ($redistcash>0) {
      $cash=$lastcash+$redistcash;
      $stock=$laststock-$redistcash/$stockprice;
      $thistradecost=$tradecost;
    }
  }
  
  $total=$cash+$stock*$stockprice;
  $totalaftertradecost=($lasttotalaftertradecost-$lasttotal) - $thistradecost + $total; 
  $lastcash=$cash;
  $laststock=$stock;
  $lasttotal=$total;
  $lasttotalaftertradecost=$totalaftertradecost;

  $day++;
  

#  print STDERR "$day\t$stockprice\t$cash\t".($stock*$stockprice)."\t$stock\t$total\t$totalaftertradecost\n";
}

close(STOCK);

my $roi = 100.0*($lasttotal-$initialcash)/$initialcash;
my $roi_annual = $roi/($day/365.0);

my $roi_at = 100.0*($lasttotalaftertradecost-$initialcash)/$initialcash;
my $roi_at_annual = $roi_at/($day/365.0);


#print "$symbol\t$day\t$roi\t$roi_annual\n";

print "Content-type: text/html\n\n";
print "<html><head>Portfolio</head><body>";
print "<p>Invested:                        \t$initialcash\n</p>";
print "<p>Days:                            \t$day\n</p>";
print "<p>Total:                           \t$lasttotal (ROI=$roi % ROI-annual = $roi_annual %)\n</p>";
print "<p>Total-after \$$tradecost/day trade costs: \t$lasttotalaftertradecost (ROI=$roi_at % ROI-annual = $roi_at_annual %)\n</p>";
print "</body></html>";

