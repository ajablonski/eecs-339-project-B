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
my $action;
my $error;
if (defined(param('act'))) {
    $action = param('act');
}

if ($action eq 'delete') {
    my $portID = param('portID');
    eval {
        ExecSQL($dbuser, $dbpasswd, "DELETE FROM $netID.portfolios WHERE id = ?", undef, $portID);
    };

    $error = $@;
} elsif ($action eq 'newPort') {
    my $name = param('name');
    eval {
        ExecSQL($dbuser, $dbpasswd, "INSERT INTO $netID.portfolios (name, owner) VALUES (?, ?) ", undef, $name, $currentUser);
    };

    $error = $@;
}


print   header(-cookies=>\@cookies),
        start_html( -title=>"Home",
                    -head=>[ Link({ -rel=>"stylesheet",
                                    -href=>"http://twitter.github.com/bootstrap/assets/css/bootstrap-responsive.css"}),
                             Link({ -rel=>"stylesheet",
                                    -href=>"http://twitter.github.com/bootstrap/assets/css/bootstrap.css" })
                            ],
                    -style=>{'src'=>'home.css'}
        ),
        "\n\n";

print $error if $error;

print   div({-class=>'navbar'}, 
            "You are logged in as " . getCurrentUser(), p, "\n",
            a({href=>"home.pl?act=logout"}, "Log out")
        ), "\n";

my @portTable;

eval {
    @portTable = ExecSQL($dbuser, $dbpasswd, "SELECT id, name, cashAccount FROM $netID.portfolios WHERE owner = ?",
        undef, $currentUser);
};
$error = $@;

# Print portfolio table
print   h1("Portfolios");
print   "<table border=\"1\">"; 
print   Tr(
            th(['Portfolio name', 'Cash amount', 'Delete portfolio'])
        );
foreach my $row (@portTable)
{
    my $portID = @$row[0];
    print   Tr(
                td({-align=>'right'},
                    [
                    a({href=>"portfolio.pl?portID=$portID"},
                        @$row[1]
                    ),
                    sprintf("\$%10.2f", @$row[2]),
                    a({href=>"home.pl?portID=$portID&act=delete"},
                        "Delete"
                    )
                ])
            );
}

print   "</table>", br, br, "\n\n"; 

print   h2("Add new portfolio");
print   start_form,
            textfield(-name=>"name"),
            hidden(-name=>"act", -value=>"newPort", -override=>1),p,
            submit("Add new portfolio"),
        end_form;

print   a({-href=>"stockView.html"}, "Stock view template");

print   end_html;

