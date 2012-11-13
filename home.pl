#!/usr/bin/perl -w

use strict;

use CGI qw(:standard);

use user;
use common;
use DBI;

require "sql.pl";


redirectIfNotLoggedIn();

my $currentUser = getCurrentUser();

print   header,
        start_html('Home'),
        h1('Home');

print "Hello, " . $currentUser, p;

my @table;

eval {
    @table = ExecSQL($dbuser, $dbpasswd, "SELECT name, cashAccount FROM $netID.portfolios WHERE owner = ?",
        undef, $currentUser);
};

my $error = $@;

print   "<table>"; 
print   Tr(
            th(['Portfolio name', 'Cash amount'])
        );
foreach my $row (@table)
{
    print "<tr>";
    foreach my $datum (@$row)
    {
        print td($datum);
    }
    print "</tr>";
}


print   "</table>"; 
print   a({-href=>"portfolio.pl"}, "Portfolio view template"), p,
        a({-href=>"stockView.html"}, "Stock view template");

print   end_html;

