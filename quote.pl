#!/usr/bin/perl -w

use Data::Dumper;
use Finance::Quote;

$#ARGV>=0 or die "usage: quote.pl  SYMBOL+\n";

@symbols=@ARGV;

$con=Finance::Quote->new();

$con->timeout(60);

%quotes = $con->fetch("usa",@symbols);

foreach $symbol (@ARGV) {
    if (!defined($quotes{$symbol,"success"})) { 
        print "NODATA";
    } elsif (defined($quotes{$symbol, "close"})) {
        print $symbol."/".$quotes{$symbol,"close"};
    }
    print "//";
}
print "\n";


