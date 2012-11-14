#!/usr/bin/perl -w

use strict;

use CGI qw(:standard);

use user;
use common;
use DBI;

require "sql.pl";


redirectIfNotLoggedIn();

checkLogout();

my @cookies = refreshCookies();

my $currentUser = getCurrentUser();

print   header(-cookies=>\@cookies),
        start_html( -title=>"Home",
                    -head=>[ Link({ -rel=>"stylesheet",
                                    -href=>"http://twitter.github.com/bootstrap/assets/css/bootstrap-responsive.css"}),
                             Link({ -rel=>"stylesheet",
                                    -href=>"http://twitter.github.com/bootstrap/assets/css/bootstrap.css" })
                            ],
                    -style=>{'src'=>'portfolio.css'}
        ),
        "\n\n";
        h1('Home');

print   div({-class=>'navbar'}, 
            "You are logged in as " . getCurrentUser(), p, "\n",
            a({href=>"home.pl?act=logout"}, "Log out")
        ), "\n";

my @portTable;

eval {
    @portTable = ExecSQL($dbuser, $dbpasswd, "SELECT id, name, cashAccount FROM $netID.portfolios WHERE owner = ?",
        undef, $currentUser);
};

my $error = $@;

# Print portfolio table
print   h1("Portfolios");
print   "<table border=\"1\">"; 
print   Tr(
            th(['Portfolio name', 'Cash amount'])
        );
foreach my $row (@portTable)
{
    my $portID = @$row[0];
    print   Tr(
                td([
                    a({href=>"portfolio.pl?portID=$portID"},
                        @$row[1]
                    ),
                    sprintf("\$%10.2f", @$row[2])
                ])
            );
}

print   "</table>"; 


print   
        a({-href=>"stockView.html"}, "Stock view template");

print   end_html;

