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
        ExecSQL($dbuser, $dbpasswd, "INSERT INTO $netID.portfolios (name, owner, cashAccount) VALUES (?, ?, 0) ", undef, $name, $currentUser);
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
                    -style=>{'src'=>'portfolio.css'}
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

print   "<div class='container'>";

print   "<div class='sidebar'>";

print   h2("Project Documents");
print   "<ul>",
        "<li> 1a) <a href='project-docs/Site_storyboard.pdf' target='_blank'>",
                    "Storyboard  </a> </li>",
        "<li> 1b) <a href='project-docs/Site_flowchart.pdf' target='_blank'>",
                    "Flowchart  </a> </li>",
        "<li> &nbsp; 2) <a href='project-docs/ER_Diagram.pdf' target='_blank'>",
                    "ER diagram  </a> </li>",
        "<li> &nbsp; 3) <a href='project-docs/Relations.pdf' target='_blank'>",
                    "Relational design  </a> </li>",
        "<li> &nbsp; 4) <a href='project-docs/SQL_DDL.pdf' target='_blank'>",
                    "SQL DDL  </a> </li>",
        "<li> &nbsp; 5) <a href='project-docs/SQL_DML-DQL.pdf' target='_blank'>",
                    "SQL DML & DQL  </a> </li>",
        "</ul>";

print   "</div> <!-- end sidebar -->";


# Print portfolio table
print   "<div class='main'>";
print   h1("Portfolios");
print   "<table border='1'>"; 
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
            textfield(-name=>"name", -class=>"addPortfolio", -placeholder=>"Name your portfolio"),
            hidden(-name=>"act", -value=>"newPort", -override=>1),p,
            submit(-class=>"btn btn-primary", -value=>"Add new portfolio"),
        end_form;

#print   a({-href=>"stockView.html"}, "Stock view template");

print "</div> <!-- end main -->";
print "</div> <!-- end container -->";

print   end_html;

