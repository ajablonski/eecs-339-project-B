#!/usr/bin/perl -w
package main;
use strict;
use warnings;
use DBI;
use user;

use CGI qw(:standard);

my $debug=0; # default - will be overriden by a form parameter or cookie
my @sqlinput=();
my @sqloutput=();


sub SQLdebug {
    open (SQLERROR, '>> sqlerror.dat');
    print SQLERROR "\n";
    print SQLERROR @_;
    close(SQLERROR);
}

sub ExecSQL {
    my ($user, $passwd, $querystring, $type, @fill) =@_;
    my $dbh = DBI->connect("DBI:Oracle:",$user,$passwd);
    if (not $dbh) { 
# if the connect failed, record the reason and then die.
        die "Can't connect to database because of ".$DBI::errstr;
    }
    my $sth = $dbh->prepare($querystring);
    if (not $sth) { 
# If prepare failed, then record reason to sqloutput and then die
        my $errstr="Can't prepare $querystring because of ".$DBI::errstr;
        $dbh->disconnect();
        die $errstr;
    }
    if (not $sth->execute(@fill)) { 
# if exec failed, record to sqlout and die.
        my $errstr="Can't execute $querystring with fill (".join(",",map {"'$_'"} @fill).") because of ".$DBI::errstr;
        $dbh->disconnect();
        die $errstr;
    }
# The rest assumes that the data will be forthcoming.
    my @data;
    if (defined $type and $type eq "ROW") { 
        @data=$sth->fetchrow_array();
        $sth->finish();
        if ($debug) {push @sqloutput, MakeTable("debug_sqloutput","ROW",undef,@data);}
        $dbh->disconnect();
        SQLdebug("Row", @data);
        return @data;
    }
    my @ret;
    while (@data=$sth->fetchrow_array()) {
        SQLdebug("undef", @data);
        push @ret, [@data];
    }
    if (defined $type and $type eq "COL") { 
        @data = map {$_->[0]} @ret;
        $sth->finish();
        if ($debug) {push @sqloutput, MakeTable("debug_sqloutput","COL",undef,@data);}
        $dbh->disconnect();
        SQLdebug("COL", @data);
        return @data;
    }
    $sth->finish();
    if ($debug) {push @sqloutput, MakeTable("debug_sql_output","2D",undef,@ret);}
    $dbh->disconnect();
    SQLdebug(@ret);
    return @ret;
}

sub BuySellStock {
    my ($user, $passwd, $shares, $stock, $price, $portID) = @_;
    return if $shares == 0;

    my $error;
    my @existingStockData;

    my $sqlString = "";
    $sqlString .= "SELECT numShares FROM $netID.holdings ";
    $sqlString .= " WHERE portfolioID = ? AND stock = rpad(?, 16)";

    eval {
        @existingStockData = ExecSQL($user, $passwd, $sqlString, 'ROW', $portID, $stock);
    };
    $error = $@;

    die $error if $error;

    # Error case testing for stock sales
    if ($shares < 0) {
        die "Stock holding not found: unable to sell." if (@existingStockData == 0);

        die "You do not own that many shares: unable to sell." if (-$shares > $existingStockData[0]);
    }


    my $dbh = DBI->connect("DBI:Oracle:",$user,$passwd, {AutoCommit => 0 , RaiseError=>1});
    if (not $dbh) { 
        die "Can't connect to database because of ".$DBI::errstr;
    }


    my $deleteStockString = "";
    $deleteStockString = "DELETE FROM $netID.holdings WHERE portfolioID = ? AND stock = ?";
    

    if ($shares < 0) {
        # Sell stocks
        eval {
            if (-$shares == $existingStockData[0]) {
                DeleteShares($dbh, $stock, $portID);
            } else {
                ChangeExistingShares($dbh, $stock, $shares, $portID);
            }
            ManipulateAccount($dbh, -$shares * $price, $portID);
            $dbh->commit;
        };
        # Add money to account (should be no failure)

    }

    if ($shares > 0) {
        eval { 
            ManipulateAccount($dbh, -$shares * $price, $portID); 
            if ($existingStockData[0]) {
                ChangeExistingShares($dbh, $stock, $shares, $portID);
            } else {
                AddNewShares($dbh, $stock, $shares, $portID);
            }
            $dbh->commit;
        };
    }

    if ($@) {
        $error = $@;
        eval { $dbh->rollback };
        $dbh->disconnect();
        die $error;
    };

    $dbh->disconnect();
}


sub ManipulateAccount {
    my ($dbh, $cost, $portID) = @_;
    my $updateSqlString = "UPDATE $netID.portfolios SET cashAccount = cashAccount + ? WHERE id = ?";

    PrepareAndExecute($dbh, $updateSqlString, $cost, $portID);
}


sub DeleteShares {
    my ($dbh, $stock, $portID) = @_;

    my $deleteStockString = "";
    $deleteStockString = "DELETE FROM $netID.holdings WHERE portfolioID = ? AND stock = rpad(?, 16)";

    PrepareAndExecute($dbh, $deleteStockString, $portID, $stock);
}


sub ChangeExistingShares {
    my ($dbh, $stock, $shares, $portID) = @_;
    my $changeStockString = "";
    $changeStockString .= "UPDATE $netID.holdings SET numShares = numShares + ? ";
    $changeStockString .= "   WHERE portfolioID = ? AND stock = rpad(?, 16)";

    PrepareAndExecute($dbh, $changeStockString, $shares, $portID, $stock);
}


sub AddNewShares {
    my ($dbh, $stock, $shares, $portID) = @_;
    my $addStockString = "";
    $addStockString .= "INSERT INTO $netID.holdings (portfolioID, stock, numShares) ";
    $addStockString .= " VALUES (?, ?, ?)";

    PrepareAndExecute($dbh, $addStockString, $portID, $stock, $shares);
}


sub PrepareAndExecute {
    my ($dbh, $sqlString, @fill) = @_;
    my $sth = $dbh->prepare($sqlString);
    if (not $sth) { 
        # If prepare failed, then record reason to sqloutput and then die
        my $errstr="Can't prepare $sqlString because of ".$DBI::errstr;
        die $errstr;
    }
    if (not $sth->execute(@fill)) { 
        # if exec failed, record to sqlout and die.
        my $errstr="Can't execute $sqlString with fill (".join(",",map {"'$_'"} @fill).") because of ".$DBI::errstr;
        die $errstr;
    }

}


BEGIN {
  unless ($ENV{BEGIN_BLOCK}) {
    use Cwd;
    $ENV{ORACLE_BASE}="/raid/oracle11g/app/oracle/product/11.2.0.1.0";
    $ENV{ORACLE_HOME}=$ENV{ORACLE_BASE}."/db_1";
    $ENV{ORACLE_SID}="CS339";
    $ENV{LD_LIBRARY_PATH}=$ENV{ORACLE_HOME}."/lib";
    $ENV{BEGIN_BLOCK} = 1;
    exec 'env',cwd().'/'.$0,@ARGV;
  }
}

1;
