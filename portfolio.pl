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

####################################
# Application logic/Data gathering #
####################################

my $action = param('act');
my $run = param('run');
my $portID = param('portID');
my $error;

my $start = param('start');
if (!defined($start)) {
    $start = "01/01/1970";
}

my $end = param('end');
if (!defined($end)) {
    $end = "today";
}



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


my @stockCOVs = split("//", `./get_cov.pl --from='$start' --end='$end' $stockArgList`);
#my $covdebug = `./get_cov.pl $stockArgList`;
my %stockCOVDict = ();

# mapping stock cov's (coef of variance) to stock names
foreach my $cov (@stockCOVs) {
    my ($key, $val) = split("/", $cov);
    $stockCOVDict{$key} = $val;
}


my $doCorrCoeff = param('docorrcoeff');

if (!defined($doCorrCoeff)) {
    $doCorrCoeff = 0;
}

my @covarMatrixLines;
my $covarMatrixCookieOut;
my $covarMatrixCookieIn = cookie($covarMatrixCookieName);
my ($oldStart, $oldEnd, $oldDoCorrCoeff, $oldPortID, $oldMatrix);

if (defined($covarMatrixCookieIn)) {
    ($oldStart, $oldEnd, $oldDoCorrCoeff, $oldPortID, $oldMatrix) = split("::", $covarMatrixCookieIn);
}

if (defined($covarMatrixCookieIn) and $portID == $oldPortID and $start eq $oldStart and $end eq $oldEnd and $doCorrCoeff == $oldDoCorrCoeff) {
    $covarMatrixCookieOut = cookie(-name=>$covarMatrixCookieName,
            -value=>$covarMatrixCookieIn);
    @covarMatrixLines = split("//", $oldMatrix);
} else {
    if ($doCorrCoeff == 1) {
        @covarMatrixLines = split("\n", `./get_covar.pl --from='$start' --to='$end' --corrcoeff $stockArgList`); 
    } else {
        @covarMatrixLines = split("\n", `./get_covar.pl --from='$start' --to='$end'  $stockArgList`); 
    }
    my $data = join("::", $start, $end, $doCorrCoeff, $portID, join("//", @covarMatrixLines));
    $covarMatrixCookieOut = cookie(-name=>$covarMatrixCookieName,
            -value=>$data);
}

push(@cookies, $covarMatrixCookieOut);



my @portfolioInfo; # declare up here because i want to display portfolio value before listing of stocks

eval {
    @portfolioInfo = ExecSQL($dbuser, $dbpasswd, "SELECT name, cashAccount FROM $netID.portfolios where id = ?", "ROW", $portID);
};


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


my @betas = split("\n", `./get_beta.pl --from='$start', --to='$end' $stockArgList`);

my %stockBetaDict = ();

foreach my $cov (@betas) {
    my ($key, $val) = split(" ", $cov);
    $stockBetaDict{$key} = $val;
}

########################
# Form action handling #
########################

if (defined($action) and defined($run) and $run) {

    my $resetCovar = 0;
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
        $resetCovar = 1;
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
    my @outCookies = refreshCookies();
    push(@outCookies, cookie(-name=>$covarMatrixCookieName, -expires=>'-1h', -value=>'0')) if $resetCovar;
    print redirect(-uri=>"portfolio.pl?portID=$portID", -cookie=>\@outCookies);
}

########################
# HTTP/HTML generation #
########################

print   header(-cookies=>\@cookies, -expires=>"now"),
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


$error = $@;
print $error if $error;

#
# container div start used to be here, moved below the variable declarations
#
print   "<div class='container'>";

# Start of sidebar div
print "<div class='sidebar'>";

print	h3("Actions"), "\n",   
	div({-class=>'accordion', -id=>'portfolio-actions'}, "\n",

	    div({ -class=>"accordion-group"},"\n",
            a({ -class=>"btn btn-info btn-small action-btn accordion-toggle",
                -'data-parent'=>"#portfolio-actions", -'data-toggle'=>"collapse", -href=>"#deposit"}, 
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
                    br, submit({-class=>"btn btn-success"}, "Submit"),
                end_form
            )), "\n\n",


            div({ -class=>"accordion-group"},"\n",
            a({ -class=>"btn btn-info btn-small action-btn accordion-toggle",
                -'data-parent'=>"#portfolio-actions", -'data-toggle'=>"collapse", -href=>"#withdraw"}, 
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
                    br, submit({-class=>"btn btn-success"}, "Submit"),
                end_form
            )), "\n\n",


            div({ -class=>"accordion-group"},"\n",
            a({ -class=>"btn btn-info btn-small action-btn accordion-toggle",
                -'data-parent'=>"#portfolio-actions", -'data-toggle'=>"collapse", -href=>"#bought"}, 
                "Record stocks bought.",
                '<i class="icon-chevron-down icon-white" style="float: right"></i>',
            ), "\n",

            div({-id=>"bought", -class=>"collapse"}, "\n",
                start_form({-class=>"form-inline"}), "\n",
                    "Stock bought",
                    '<input type="text" name="stock" id="inputStockBought" class="stockSymbol">', br,
                    "# of shares",
                    '<input type="number" name="shares" id="inputNumBought" min="0">', br,
                    "Buying price",
                    '<input type="number" name="price" id="inputPriceBought" min="0.01" step="0.01">', br,
                    hidden(-name=>'run', -value=>1, -override=>1),
                    hidden(-name=>'act', -value=>'buyStock', -override=>1),
                    hidden(-name=>'portID', -value=>$portID, -override=>1),
                    submit({-class=>"btn btn-success"}, "Submit"),
                end_form
            )), "\n\n",


	    div({ -class=>"accordion-group"},"\n",
            a({ -class=>"btn btn-info btn-small action-btn accordion-toggle",
                -'data-parent'=>"#portfolio-actions", -'data-toggle'=>"collapse", -href=>"#sold"}, 
                "Record stocks sold.",
                '<i class="icon-chevron-down icon-white" style="float: right"></i>',
            ), "\n",

            div({-id=>"sold", -class=>"collapse"}, "\n",
                start_form({-class=>"form-inline"}), "\n",
                    "Stock sold",
                    '<input type="text" name="stock" id="inputStockSold" class="stockSymbol">', br,
                    "# of shares",
                    '<input type="number" name="shares" id="inputNumSold" min="0">', br,
                    "Selling price",
                    '<input type="number" name="price" id="inputPriceSold" min="0.01" step="0.01">', br,
                    hidden(-name=>'run', -value=>1, -override=>1),
                    hidden(-name=>'act', -value=>'sellStock', -override=>1),
                    hidden(-name=>'portID', -value=>$portID, -override=>1),
                    submit({-class=>"btn btn-success"}, "Submit"),
                end_form
            )), "\n\n",


	    div({ -class=>"accordion-group"},"\n",
            a({ -class=>"btn btn-info btn-small action-btn accordion-toggle",
                -'data-parent'=>"#portfolio-actions", -'data-toggle'=>"collapse", -href=>"#newDailyInfo"}, 
                "Record new stock data.",
                '<i class="icon-chevron-down icon-white" style="float: right"></i>',
            ), "\n",

            div({-id=>"newDailyInfo", -class=>"collapse"}, "\n",
                start_form({-class=>"form-inline"}), "\n",
                    "Stock", '<input type="text" name="stock" id="newDataStock" class="stockSymbol">', br,
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
            )), "\n\n",
        ), "\n\n\n"; # End portfolio actions div
		   
print "</div> <!-- end sidebar div -->";

print   "<div class='main'>", 
            h1("Portfolio view: $portfolioInfo[0]"), 
            h2("Total amount of cash (cash account): &nbsp;&nbsp; <font color='green'> \$", sprintf("%.2f", $portfolioInfo[1]),"</font>"),
            h2("Estimated portfolio present market value: <font color='green'> \$", sprintf("\%.2f", $estimatedPortValue + $portfolioInfo[1]),"</font>"),
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
	    h1("Portfolio statistics");

print   start_form({-class=>"form-inline"}),
           hidden(-name=>"portID", -value=>$portID, -override=>1),
           '<input type="radio" name="docorrcoeff" value="0" checked>Covariance Matrix',
           '&nbsp; &nbsp; <input type="radio" name="docorrcoeff" value="1">Correlation Coefficient Matrix <br/><br/> ',
           "Start date: ", '<input type="date" name="start" class="portDate">', 
           "&nbsp; &nbsp; &nbsp; End date: ", '<input type="date" name="end" class="portDate">', 

           "&nbsp; &nbsp; &nbsp;", submit, br,

           "<i>Leave start date empty for earliest date for which data is available", br,
           "Leave end date empty for today</i>", br
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
                    @$row[1],
                    $stockCOVDict{@$row[0]},
                    $stockBetaDict{@$row[0]}
                ]),
            ), "\n";
}
print       "</table>\n";

print       hr, h2("Covariance/correlation coefficient matrix");


print  "<table>";

foreach my $line (@covarMatrixLines) {
    print "<tr>"; 
    foreach my $cell (split(" ", $line)) {
        print "<td>", $cell, "</td>";
    }
    print "</tr>";
}

print "</table>";

print "<br/><br/>"; 
# ----- END List of stock holdings w/statistics -----



print   "</div>\n"; # End main div
print   "</div>"; # end container div

print   '<script src="http://twitter.github.com/bootstrap/assets/js/jquery.js" /> </script>', "\n",
        '<script src="http://twitter.github.com/bootstrap/assets/js/bootstrap-collapse.js"> </script>', "\n", 
        '<script src="http://twitter.github.com/bootstrap/assets/js/bootstrap-button.js"> </script>', "\n",
        '<script src="http://twitter.github.com/bootstrap/assets/js/bootstrap-transition.js"> </script>';

print   end_html;

