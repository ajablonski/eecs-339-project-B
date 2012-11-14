#!/usr/bin/perl -w

use strict;

use CGI qw(:standard);

use user;
use common;
use DBI;

require "sql.pl";

redirectIfNotLoggedIn();

my @cookies = refreshCookies();

my $symbol = param("stock");
my $portID = param("portID");

print   header(-cookies=>\@cookies),
        start_html( -title=>"Stock View",
                    -head=>[ Link({ -rel=>"stylesheet",
                                    -href=>"http://twitter.github.com/bootstrap/assets/css/bootstrap-responsive.css"}),
                             Link({ -rel=>"stylesheet",
                                    -href=>"http://twitter.github.com/bootstrap/assets/css/bootstrap.css" })
                            ],
                    -style=>{'src'=>'portfolio.css'}
                            ),
        "\n\n";

print   div({-class=>'navbar'}, 
            "You are logged in as " . getCurrentUser(), p, "\n",
            a({href=>"portfolio.pl?portID=$portID"}, 
                "Return to portfolio view"
            )
        ), "\n";

my $error;
my @stockInfo;

my $sqlString = "";
$sqlString .= "SELECT numShares FROM $netID.holdings ";
$sqlString .= " WHERE portfolioID = ? AND stock = rpad(?, 16) ";

eval {
    @stockInfo = ExecSQL($dbuser, $dbpasswd, $sqlString, 'ROW', $portID, $symbol);
};

$error = $@;
print $error if $error;

print   h1("$symbol");
print   h2("Number of shares: $stockInfo[0]");

print   '<script src="http://twitter.github.com/bootstrap/assets/js/jquery.js" /> </script>', "\n",
        '<script src="http://twitter.github.com/bootstrap/assets/js/bootstrap-collapse.js"> </script>', "\n", 
        '<script src="http://twitter.github.com/bootstrap/assets/js/bootstrap-button.js"> </script>', "\n",
        '<script src="http://twitter.github.com/bootstrap/assets/js/bootstrap-transition.js"> </script>';

print   end_html;
