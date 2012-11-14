#!/usr/bin/perl -w

use strict;

use CGI qw(:standard);

use user;
use common;
use DBI;

require "sql.pl";

redirectIfNotLoggedIn();

my @cookies = refreshCookies();

print   header(-cookies=>\@cookies),
        start_html( -title=>'Portfolio View',
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
            a({href=>"home.pl"}, "Return to list of portfolios")
        ), "\n";

my $portID = param('portID');
my $error;
my @portfolioInfo;

eval {
    @portfolioInfo = ExecSQL($dbuser, $dbpasswd, "SELECT name, cashAccount FROM $netID.portfolios where id = ?", "ROW", $portID);
};

$error = $@;
print $error if $error;

my @stockInfo;

eval {
    @stockInfo = ExecSQL($dbuser, $dbpasswd, "SELECT stock, numShares FROM $netID.holdings WHERE portfolioID = ?", undef, $portID);
};

$error = $@;
print $error if $error;


print   div({-class=>'portfolio-actions sidebar'}, "\n",
            h2("Estimated present market value of the portfolio: "),
            h2("Total amount of cash / cash account: \$", sprintf("%.2f", $portfolioInfo[1])),
            h3("Actions"), "\n",

            a({ -class=>"btn btn-primary btn-small action-btn accordion-toggle",
                -'data-toggle'=>"collapse", -href=>"#deposit"}, 
                "Deposit cash to the cash account",
                '<i class="icon-chevron-down icon-white" style="float: right"></i>',
            ), "\n",
            
            div({-id=>"deposit", -class=>"collapse"}, "\n",
                start_form({-class=>"form-inline"}), "\n",
                    "Amount to deposit",
                    '<input type="number" id="inputDeposit" min="0.01" step="0.01">',
                    submit({-class=>"btn btn-success"}, "Submit"),
                end_form
            ), "\n\n",

            
            a({ -class=>"btn btn-small action-btn accordion-toggle",
                -'data-toggle'=>"collapse", -href=>"#withdraw"}, 
                "Withdraw cash from cash account",
                '<i class="icon-chevron-down icon-white" style="float: right"></i>',
            ), "\n",

            div({-id=>"withdraw", -class=>"collapse"}, "\n",
                start_form({-class=>"form-inline"}), "\n",
                    "Amount to withdraw",
                    '<input type="number" id="inputWithdraw" min="0.01" step="0.01">',
                    submit({-class=>"btn btn-success"}, "Submit"),
                end_form
            ), "\n\n",

            
            a({ -class=>"btn btn-small action-btn accordion-toggle",
                -'data-toggle'=>"collapse", -href=>"#bought"}, 
                "Record stocks bought.",
                '<i class="icon-chevron-down icon-white" style="float: right"></i>',
            ), "\n",

            div({-id=>"bought", -class=>"collapse"}, "\n",
                start_form({-class=>"form-inline"}), "\n",
                    "Stocks bought",
                    '<input type="text" id="inputStockBought">', br,
                    "# of stocks",
                    '<input type="number" id="inputNumBought">', br,
                    "Buying price",
                    '<input type="number" id="inputPriceBought" min="0.01" step="0.01">', br,
                    submit({-class=>"btn btn-success"}, "Submit"),
                end_form
            ), "\n\n",


            a({ -class=>"btn btn-small action-btn accordion-toggle",
                -'data-toggle'=>"collapse", -href=>"#sold"}, 
                "Record stocks sold.",
                '<i class="icon-chevron-down icon-white" style="float: right"></i>',
            ), "\n",

            div({-id=>"sold", -class=>"collapse"}, "\n",
                start_form({-class=>"form-inline"}), "\n",
                    "Stocks sold",
                    '<input type="text" id="inputStockBought">', br,
                    "# of stocks",
                    '<input type="number" id="inputNumBought">', br,
                    "Selling price",
                    '<input type="number" id="inputPriceBought" min="0.01" step="0.01">', br,
                    submit({-class=>"btn btn-success"}, "Submit"),
                end_form
            ), "\n\n",


            a({ -class=>"btn btn-small action-btn accordion-toggle",
                -'data-toggle'=>"collapse", -href=>"#newDailyInfo"}, 
                "Record new stock data.",
                '<i class="icon-chevron-down icon-white" style="float: right"></i>',
            ), "\n",

            div({-id=>"newDailyInfo", -class=>"collapse"}, "\n",
                start_form({-class=>"form-inline"}), "\n",
                    "Stock, high, low, start, end, ...",
                    submit({-class=>"btn btn-success"}, "Submit"),
                end_form
            ), "\n\n",
        ), "\n\n\n"; # End portfolio actions

print   "<div class=\"container\">",
            h1("Portfolio view: $portfolioInfo[0]"), 
            h2("Portfolio statistics"),
            ul(
                li(u("For all stocks:"),
                    ul(
                        li("Covariance/correlation matrix of the stocks in the portfolio")
                    )
                ),
                li(u("For each stock:"),
                    ul(
                        li("Coefficient of variation of each stock"),
                        li("The Beta of each stock.")
                    )
                ),
                br,
                li("The volatility of the stocks in the portfolio"),
                li("The correlation of the stocks in the portfolio")
            ),
            hr,
            h2("List of Stock Holdings"), "\n",
            "<table border=\"1\">\n",
            Tr(
                th(['Stock Symbol', 'Number of Shares']) 
            ), "\n";

foreach my $row (@stockInfo) {
    print   Tr(
                td([
                    a({href=>"stock.pl?portID=$portID&stock=@$row[0]"},
                        @$row[0]
                    ),
                    @$row[1]
                ]), 
            ), "\n";
}
print       "</table>\n";


print   "</div>\n";
        

print   '<script src="http://twitter.github.com/bootstrap/assets/js/jquery.js" /> </script>', "\n",
        '<script src="http://twitter.github.com/bootstrap/assets/js/bootstrap-collapse.js"> </script>', "\n", 
        '<script src="http://twitter.github.com/bootstrap/assets/js/bootstrap-button.js"> </script>', "\n",
        '<script src="http://twitter.github.com/bootstrap/assets/js/bootstrap-transition.js"> </script>';



print   end_html;

