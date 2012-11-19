#!/usr/bin/perl

# From pdinda get_covar

use Getopt::Long;
use Time::ParseDate;
use FileHandle;
use user;
use stock_data_access;


$close=1;

$field1='close';
$field2='close';

&GetOptions( "field1=s" => \$field1,
	     "field2=s" => \$field2,
	     "from=s"   => \$from,
	     "to=s"     => \$to,
             "simple"   => \$simple,
	     "corrcoeff"=>\$docorrcoeff);

if (defined $from) { $from=parsedate($from);}
if (defined $to) { $to=parsedate($to); }


$usage = "usage: get_beta.pl [--field1=field] [--field2=field] [--from=time] [--to=time] [--simple (two symbols only)] [--corrcoeff] SYMBOL SYMBOL+\n";
$#ARGV>=0 or die $usage;


@symbols=@ARGV;

$sql = "SELECT avg($field1), stddev($field1) FROM (SELECT $field1, timestamp, symbol FROM cs339.stocksdaily UNION SELECT $field1, timestamp, symbol FROM $netID.newstocksdaily) WHERE symbol=rpad('DIA', 16)";

($mean, $stddev) = ExecStockSQL("ROW", $sql);

for ($i=0;$i<=$#symbols;$i++) {
    $s1=$symbols[$i];
    
#first, get means and vars for the individual columns that match
    
    $sql = "select count(*),avg($field1),stddev($field1) from ";
    $sql.= "(SELECT $field1 FROM ".GetStockPrefix()."StocksDaily l where symbol='$s1'";
    $sql.= " and l.timestamp>=$from" if $from;
    $sql.= " and l.timestamp<=$to" if $to;
    $sql.= " UNION SELECT $field1 FROM $netID.newstocksdaily r WHERE symbol='$s1'";
    $sql.= " and r.timestamp>=$from" if $from;
    $sql.= " and r.timestamp<=$to" if $to;
    $sql.= " )";
   
    ($count, $mean_f1,$std_f1 ) = ExecStockSQL("ROW",$sql);
    
    #skip this stock if there isn't enough data
    if ($count<30) { # not enough data
        $covar{$s1}='NODAT';
        $corrcoeff{$s1}='NODAT';
    } else {
      
      #otherwise get the covariance

        $sql = "select avg((l.$field1 - $mean_f1)*(r.$field1 - $mean)) from ".GetStockPrefix()."StocksDaily l join ";
        $sql.= " (SELECT $field1, timestamp FROM ".GetStockPrefix()."StocksDaily WHERE symbol=rpad('DIA', 16)";
        $sql.= " UNION SELECT $field1, timestamp FROM $netID.newstocksdaily WHERE symbol='DIA')";
        $sql.= " r on  l.timestamp=r.timestamp where l.symbol='$s1'";
        $sql.= " and l.timestamp>= $from" if $from;
        $sql.= " and l.timestamp<= $to" if $to;
        
        my @rows = ExecStockSQL("ROW", $sql);
        ($covar{$s1}) = $rows[0]/($stddev*$stddev);
    }
}

if ($simple && $#symbols==1) {
    $s1=$symbols[0];
    print $covar{$s1} eq "NODAT" ? "NODAT" : sprintf('%3.6f',$covar{$s1});
    print "\n";
} else {

    for ($i=0;$i<=$#symbols;$i++) {
    $s1=$symbols[$i];
    print $s1;
    print "\t", $covar{$s1} eq "NODAT" ? "NODAT" : sprintf('%3.6f',$covar{$s1});
    print "\n";
    }
}


