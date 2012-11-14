#!/usr/bin/perl -w

use strict;

use CGI qw(:standard);

use user;
use common;
use DBI;

require "sql.pl";


redirectIfNotLoggedIn();

my @cookies = refreshCookies();

my $currentUser = getCurrentUser();

print   header(-cookies=>\@cookies),
        start_html('Home'),
        h1('Home');

print "Hello, " . $currentUser, p;

my @portTable;

eval {
    @portTable = ExecSQL($dbuser, $dbpasswd, "SELECT id, name, cashAccount FROM $netID.portfolios WHERE owner = ?",
        undef, $currentUser);
};

my $error = $@;

# Print portfolio table
print   "<table>"; 
print   Tr(
            th(['Portfolio name', 'Cash amount'])
        );
foreach my $row (@portTable)
{
    print "<tr>";
    my $portID = @$row[0];
    foreach my $datum (@$row[1,2])
    {
        print   td(
                    a({href=>"portfolio.pl?portID=$portID"},
                        $datum
                    )
                );
    }
    print "</tr>";
}
print   "</table>"; 


print   a({-href=>"portfolio.pl"}, "Portfolio view template"), p,
        a({-href=>"stockView.html"}, "Stock view template");

print   end_html;

