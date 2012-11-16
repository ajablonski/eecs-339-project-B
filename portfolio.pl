#!/usr/bin/perl -w

use strict;

use CGI qw(:standard);

use user;
use common;
use DBI;

use Date::Parse;

require "sql.pl";

redirectIfNotLoggedIn();

my @cookies = refreshCookies();

my $action = param('act');
my $run = param('run');
my $portID = param('portID');
my $error;

if (defined($action) and defined($run) and $run) {
    if ($action eq 'deposit') {
        my $amount = param('amount');
        eval {
            ExecSQL($dbuser, $dbpasswd, "UPDATE $netID.portfolios SET cashAccount = cashAccount + ? WHERE id = ?", undef, $amount, $portID);
        };
        $error = $@;
    } elsif ($action eq 'withdraw') {
        my $amount = param('amount');
        eval {
            ExecSQL($dbuser, $dbpasswd, "UPDATE $netID.portfolios SET cashAccount = cashAccount - ? WHERE id = ?", undef, $amount, $portID);
        };
        $error = $@;
    } elsif ($action eq 'sellStock' or $action eq 'buyStock') {
        my $shares = param('shares');
        my $stock = param('stock');
        my $price = param('price');
        if ($action eq 'sellStock') {$shares = -$shares};
        eval {
            BuySellStock($dbuser, $dbpasswd, $shares, $stock, $price, $portID);
        };
        $error = $@;
    } elsif ($action eq 'addData') {
        my $high = param('high');
        my $low = param('low');
        my $open = param('open');
        my $close = param('close');
        my $volume = param('volume');
        my $stock = param('stock');
        my $date = param('date');
        my $sqlString = "";
        $sqlString .= "INSERT INTO $netID.newstocksdaily (symbol, timestamp, high, low, open, close, volume)";
        $sqlString .= " VALUES (?, ?, ?, ?, ?, ?, ?) ";
        eval {
            ExecSQL($dbuser, $dbpasswd, $sqlString, undef, $stock, str2time($date), $high, $low, $open, $close, $volume);
        };
        $error = $@;
    }
}

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


print $error if $error;
print   div({-class=>'navbar'}, 
            "You are logged in as " . getCurrentUser(), p, "\n",
            a({href=>"home.pl?act=logout"}, "Log out"), p, 
            a({ -class=>"returnToPorts", -href=>"home.pl"}, "Return to list of portfolios")
        ), "\n";

# From work done before page began

my @portfolioInfo; # declare up here because i want to display portfolio value before listing of stocks

eval {
    @portfolioInfo = ExecSQL($dbuser, $dbpasswd, "SELECT name, cashAccount FROM $netID.portfolios where id = ?", "ROW", $portID);
};

$error = $@;
print $error if $error;

#
# container div start used to be here, moved below the variable declarations
#
print   "<div class='container'>";

# Start of sidebar div
print   div({-class=>'portfolio-actions sidebar'}, "\n",
            #h2("Estimated portfolio present market value: ", sprintf("\$%.2f", $estimatedPortValue + $portfolioInfo[1])),
            #h2("Total amount of cash / cash account: ", sprintf("\$%.2f", $portfolioInfo[1])),
            h3("Actions"), "\n",

            a({ -class=>"btn btn-info btn-small action-btn accordion-toggle",
                -'data-toggle'=>"collapse", -href=>"#deposit"}, 
                "Deposit to cash account",
                '<i class="icon-chevron-down icon-white" style="float: right"></i>',
            ), "\n",
            
            div({-id=>"deposit", -class=>"collapse"}, "\n",
                start_form({-class=>"form-inline"}), "\n",
                    "Amount to deposit",
                    '<input type="number" name="amount" id="inputDeposit" min="0.01" step="0.01">',
                    hidden(-name=>'run', -value=>1, -override=>1),
                    hidden(-name=>'act', -value=>'deposit', -override=>1),
                    hidden(-name=>'portID', -value=>$portID, -override=>1),
                    submit({-class=>"btn btn-success"}, "Submit"),
                end_form
            ), "\n\n",

            
            a({ -class=>"btn btn-info btn-small action-btn accordion-toggle",
                -'data-toggle'=>"collapse", -href=>"#withdraw"}, 
                "Withdraw from cash account",
                '<i class="icon-chevron-down icon-white" style="float: right"></i>',
            ), "\n",

            div({-id=>"withdraw", -class=>"collapse"}, "\n",
                start_form({-class=>"form-inline"}), "\n",
                    "Amount to withdraw",
                    '<input type="number" name="amount" id="inputWithdraw" min="0.01" step="0.01">',
                    hidden(-name=>'run', -value=>1, -override=>1),
                    hidden(-name=>'act', -value=>'withdraw', -override=>1),
                    hidden(-name=>'portID', -value=>$portID, -override=>1),
                    submit({-class=>"btn btn-success"}, "Submit"),
                end_form
            ), "\n\n",

            
            a({ -class=>"btn btn-info btn-small action-btn accordion-toggle",
                -'data-toggle'=>"collapse", -href=>"#bought"}, 
                "Record stocks bought.",
                '<i class="icon-chevron-down icon-white" style="float: right"></i>',
            ), "\n",

            div({-id=>"bought", -class=>"collapse"}, "\n",
                start_form({-class=>"form-inline"}), "\n",
                    "Stock bought",
                    '<input type="text" name="stock" id="inputStockBought">', br,
                    "# of shares",
                    '<input type="number" name="shares" id="inputNumBought" min="0">', br,
                    "Buying price",
                    '<input type="number" name="price" id="inputPriceBought" min="0.01" step="0.01">', br,
                    hidden(-name=>'run', -value=>1, -override=>1),
                    hidden(-name=>'act', -value=>'buyStock', -override=>1),
                    hidden(-name=>'portID', -value=>$portID, -override=>1),
                    submit({-class=>"btn btn-success"}, "Submit"),
                end_form
            ), "\n\n",


            a({ -class=>"btn btn-info btn-small action-btn accordion-toggle",
                -'data-toggle'=>"collapse", -href=>"#sold"}, 
                "Record stocks sold.",
                '<i class="icon-chevron-down icon-white" style="float: right"></i>',
            ), "\n",

            div({-id=>"sold", -class=>"collapse"}, "\n",
                start_form({-class=>"form-inline"}), "\n",
                    "Stock sold",
                    '<input type="text" name="stock" id="inputStockSold">', br,
                    "# of shares",
                    '<input type="number" name="shares" id="inputNumSold" min="0">', br,
                    "Selling price",
                    '<input type="number" name="price" id="inputPriceSold" min="0.01" step="0.01">', br,
                    hidden(-name=>'run', -value=>1, -override=>1),
                    hidden(-name=>'act', -value=>'sellStock', -override=>1),
                    hidden(-name=>'portID', -value=>$portID, -override=>1),
                    submit({-class=>"btn btn-success"}, "Submit"),
                end_form
            ), "\n\n",


            a({ -class=>"btn btn-info btn-small action-btn accordion-toggle",
                -'data-toggle'=>"collapse", -href=>"#newDailyInfo"}, 
                "Record new stock data.",
                '<i class="icon-chevron-down icon-white" style="float: right"></i>',
            ), "\n",

            div({-id=>"newDailyInfo", -class=>"collapse"}, "\n",
                start_form({-class=>"form-inline"}), "\n",
                    "Stock", '<input type="text" name="stock" id="newDataStock">', br,
                    "Date", '<input type="date" name="date" id="newDataDate" min="0.01" step="0.01">', br,
                    "Open", '<input type="number" name="open" id="newDataOpen" min="0.01" step="0.01">',
                    "Close", '<input type="number" name="close" id="newDataClose" min="0.01" step="0.01">', br,
                    "High", '<input type="number" name="high" id="newDataHigh" min="0.01" step="0.01">',
                    "Low", '<input type="number" name="low" id="newDataLog" min="0.01" step="0.01">', br,
                    "Volume", '<input type="number" name="volume" id="newDataVolume" min="1">', br,
                    hidden(-name=>'run', -value=>1, -override=>1),
                    hidden(-name=>'act', -value=>'addData', -override=>1),
                    hidden(-name=>'portID', -value=>$portID, -override=>1),
                    submit({-class=>"btn btn-success"}, "Submit"),
                end_form
            ), "\n\n",
        ), "\n\n\n"; # End portfolio actions


my @stockInfo;

eval {
    @stockInfo = ExecSQL($dbuser, $dbpasswd, "SELECT stock, numShares FROM $netID.holdings WHERE portfolioID = ?", undef, $portID);
};

$error = $@;
print $error if $error;
my @stockList;


foreach my $row (@stockInfo) {
    my $stock = @$row[0];
    push(@stockList, $stock);
}

# list of all stocks in current portfolio
my $stockArgList = join(" ", @stockList);

# closing quote prices of all stocks in current portfolio
my @stockQuotes = split("//", `./get_close.pl $stockArgList`);
my %stockQuoteDict = ();

# mapping closing prices to stock names
foreach my $quote (@stockQuotes) {
    my ($key, $val) = split("/", $quote);
    $stockQuoteDict{$key} = $val;
}

my @stockCOVs = split("//", `./get_cov.pl $stockArgList`);
#my $covdebug = `./get_cov.pl $stockArgList`;
my %stockCOVDict = ();

# mapping stock cov's (coef of variance) to stock names
foreach my $cov (@stockCOVs) {
    my ($key, $val) = split("/", $cov);
    $stockCOVDict{$key} = $val;
}

my $estimatedPortValue = 0;

# i realize this loop gets gone through twice in this code,
# (later for displaying the table)
# but i want the estimated value to display at the top of the page
foreach my $row (@stockInfo) {
    @$row[0] =~ s/\s+$//;
    my $stockPrice = $stockQuoteDict{@$row[0]};
    my $stockValue = $stockPrice * @$row[1];
    $estimatedPortValue += $stockValue;
}


print   "<div class='main'>", # changed from "container"
            h1("Portfolio view: $portfolioInfo[0]"), 
	    #h2("Estimated present market value of the portfolio: "),
            h2("Total amount of cash / cash account: &nbsp;&nbsp; <font color='green'> \$", sprintf("%.2f", $portfolioInfo[1]),"</font>"),
	    h2("Estimated portfolio present market value: <font color='green'> \$", sprintf("\$%.2f", $estimatedPortValue + $portfolioInfo[1]),"</font>"),
            #h2("Total amount of cash / cash account: ", sprintf("\$%.2f", $portfolioInfo[1])),
	    hr;


# ----- List of stock holdings -----

print   h2("List of Stock Holdings"), "\n",
        "<table border=\"1\">\n",
        Tr(
            th(['Symbol', '# of Shares', 'Most recent price/share', 'Estimated value']) 
        ), "\n";

#my $estimatedPortValue = 0;

foreach my $row (@stockInfo) {
    @$row[0] =~ s/\s+$//;
    my $stockPrice = $stockQuoteDict{@$row[0]};
    my $stockValue = $stockPrice * @$row[1];
    #$estimatedPortValue += $stockValue;
    print   Tr(
                td([
                    a({href=>"stock.pl?portID=$portID&stock=@$row[0]"},
                        @$row[0]
                    ),
                    @$row[1],
                    sprintf("\$%10.3f", $stockPrice),
                    sprintf("\$%10.2f", $stockValue)
                ]), 
            ), "\n";
}
print       "</table>\n";
# ----- END List of stock holdings -----

print	    hr,
	    h2("Portfolio statistics"),
            ul(
                li(u("For all stocks:"),
                    ul(
                        li("Covariance/correlation matrix of the stocks in the portfolio")
                    )
                ),
                li(u("For each stock:"),
                    ul(
                        li("Coefficient of variation of each stock == The volatility of the stocks in the portfolio"),
                        li("The Beta of each stock. == The correlation of the stocks in the portfolio")
                    )
                ),
                br,
            );

print   start_form({-class=>"form-inline"}),
           hidden(-name=>"portID", -value=>$portID, -override=>1),
           "Start date", '<input type="date" name="start id="portStart">', br,
           "Leave empty for earliest date for which data is available", br,
           "End date", '<input type="date" name="end" id="portEnd">', br,
           "Leave empty for today", br,
           submit,
        end_form;

# ----- List of stock holdings w/ statistics-----
print       h2("List of Stock Holdings w/ Statistics"), "\n",
            "<table border=\"1\">\n",
            Tr(
                th(['Stock Symbol', 'Number<br/>of Shares', 'COV', 'Beta']) 
            ), "\n";



foreach my $row (@stockInfo) {
    print   Tr(
                td([
                    a({href=>"stock.pl?portID=$portID&stock=@$row[0]"},
                        @$row[0]
                    ),
                    @$row[1]
                ]),
		td([$stockCOVDict{@$row[0]}]),
		td(["beta"]),

            ), "\n";
}
print       "</table>\n";
;
# ----- END List of stock holdings w/statistics -----



print   "</div>\n"; # End main div
print   "</div'>"; # end container div






print   '<script src="http://twitter.github.com/bootstrap/assets/js/jquery.js" /> </script>', "\n",
        '<script src="http://twitter.github.com/bootstrap/assets/js/bootstrap-collapse.js"> </script>', "\n", 
        '<script src="http://twitter.github.com/bootstrap/assets/js/bootstrap-button.js"> </script>', "\n",
        '<script src="http://twitter.github.com/bootstrap/assets/js/bootstrap-transition.js"> </script>';



print   end_html;

