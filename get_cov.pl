#!/usr/bin/perl

# based on get_info from pdinda

use Getopt::Long;
use Time::ParseDate;
use FileHandle;
use user;

use stock_data_access;

$close=1;

$field='close';

&GetOptions("field=s" => \$field,
	    "from=s" => \$from,
	    "to=s" => \$to);

if (defined $from) { $from=parsedate($from);}
if (defined $to) { $to=parsedate($to); }

my $cov;

$#ARGV>=0 or die "usage: get_info.pl [--field=field] [--from=time] [--to=time] SYMBOL+\n";

#print join("\t","symbol","field","num","mean","std","min","max","cov"),"\n";

while ($symbol=shift) {
    $sql  = "SELECT stddev($field) / avg($field) FROM ";
    $sql .= " (SELECT $field FROM ".GetStockPrefix()."StocksDaily WHERE symbol='$symbol'";
    $sql .= "   AND timestamp>=$from" if $from;
    $sql .= "   AND timestamp<=$to" if $to;
    $sql .= " UNION ";
    $sql .= " SELECT $field FROM $netID.newstocksdaily WHERE symbol='$symbol'";
    $sql .= "   AND timestamp>=$from" if $from;
    $sql .= "   AND timestamp<=$to" if $to;
    $sql .= " )";

    ($cov) = ExecStockSQL("ROW", $sql);

    print $symbol, "/", sprintf("%.4f", $cov), "//";
}
