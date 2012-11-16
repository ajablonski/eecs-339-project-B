#!/usr/bin/perl -w

use Data::Dumper;
use Finance::Quote;
use DBI;
use user;
use Date::Parse;
use Date::Format;
require "sql.pl";

close STDOUT;
open(ERRORLOG, ">>", "quote.errlog") or die "CANNOT OPEN FILE";

my $sqlString = "";
$sqlString .= "SELECT DISTINCT stock FROM $netID.holdings";

my @symbolList;

eval {
    @symbolList = ExecSQL($dbuser, $dbpasswd, $sqlString, "COL");
};

my $error = $@;

print ERRORLOG time2str('%c', time), $error, "\n" if $error;

my $insertSQLstring = "";
$insertSQLstring .= "INSERT INTO $netID.newstocksdaily (symbol, timestamp, high, low, close, open, volume)";
$insertSQLstring .= " VALUES(?, ?, ?, ?, ?, ?, ?)";

if ($#ARGV>=0) {
    @symbols=@ARGV;
} else {
    @symbols=@symbolList;
}

$con=Finance::Quote->new();

$con->timeout(60);

%quotes = $con->fetch("usa",@symbols);


foreach $symbol (@symbols) {
    $symbol =~ s/\s+$//;
    if (!defined($quotes{$symbol,"success"})) { 
    } else {
        eval {
            ExecSQL($dbuser, $dbpasswd, $insertSQLstring, undef, 
                $symbol,
                str2time($quotes{$symbol, "date"}),
                $quotes{$symbol, "high"},
                $quotes{$symbol, "low"},
                $quotes{$symbol, "open"},
                $quotes{$symbol, "close"},
                $quotes{$symbol, "volume"}
            );
        };
        $error = $@;

        print ERRORLOG time2str('%c', time), $error, "\n" if $error;
    }
}

close(ERRORLOG);
