#!/usr/bin/perl -w

use strict;

use CGI qw(:standard);

use user;
use common;
use DBI;
use Date::Format;
require "sql.pl";

redirectIfNotLoggedIn();

my @cookies = refreshCookies();

my $symbol = param("stock");
my $portID = param("portID");
my $start = param('start');
my $end = param('end');
my $futureSteps = param('futureSteps');
my $tradecost = param('tradecost');
my $initialcash = param('initialcash');

if (!$start) {
    $start = time2str("%Y-%m-%d", 0);
} 

if (!$end) {
    $end = time2str("%Y-%m-%d", time);
} 

if (!$futureSteps) {
    $futureSteps = 7;
} 

if (!$tradecost) {
    $tradecost = 3;
} 

if (!$initialcash) {
    $initialcash = 1000;
} 

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
            a({href=>"home.pl?act=logout"}, "Log out"),
            a({-class=>"returnToPorts", -href=>"portfolio.pl?portID=$portID"}, 
                "Return to portfolio view"
            ),
	    a({ -class=>"returnToPorts", -href=>"home.pl"}, "Return to list of portfolios"),
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

# print   "<div class='container'>";


print   "<div class='sidebar'>";

print   h2("Automated Strategy: &nbsp;Shannon Ratchet");

print   start_form({-class=>"form-inline"}),
           hidden(-name=>"type", -value=>"plot", -override=>1),
           hidden(-name=>"portID", -value=>$portID, -override=>1),
           hidden(-name=>"stock", -value=>$symbol, -override=>1),
	   "Start date: ", '<input type="date" name="start" class="portDate">', 
           "&nbsp; &nbsp; &nbsp; End date: ", '<input type="date" name="end" class="portDate">',
	   "&nbsp; &nbsp; &nbsp;", br,
           "<i>Leave start date empty for earliest date for which data is available", br,
           "Leave end date empty for today</i>", br

         #  "Start date", '<input type="date" name="start">', br,
         #  "Leave empty for earliest date for which data is available", br,
         #  "End date", '<input type="date" name="end">', br,
         #  "Leave empty for today", br,
           "Initial Cash \$", '<input type="int" name="initialcash" class="priceField"> ', #br,
           "<i>Leave empty for \$1000</i>", br,
           "Trade Cost \$", '<input type="int" name="tradecost" class="priceField">', #br,
           "<i>Leave empty for \$3</i>", br,
           submit,
        end_form;

print	h3("Shannon Ratchet Prediction");
print  "<iframe id='ratchet' src='shannon_ratchet.pl?symbol=$symbol&initialcash=$initialcash&tradecost=$tradecost&start=$start&end=$end'";
print 	"style='width=250px height=250px'></iframe>";

#print   iframe({src=>"plot_stock.pl?symbol=$symbol&type=text&start=$start&end=$end",
 #           width=>"250 px" #height=>"100%"    
  #      });
print	"<br/><br/><br/>";

print	h3("Historic data table");
print 	"<iframe id='datalist' src='plot_stock.pl?symbol=$symbol&type=text&start=$start&end=$end'";
print	"style='width=250px height=100px'> </iframe>";
print 	"</div>";


print 	"<div class='main'>";

print   h1("$symbol");
print   h2("Number of shares: $stockInfo[0]");

print   hr;
print   h3("Historic data plot");
print   img({src=>"plot_stock.pl?symbol=$symbol&type=plot&start=$start&end=$end"});
print   start_form({-class=>"form-inline"}),
           hidden(-name=>"portID", -value=>$portID, -override=>1),
           hidden(-name=>"stock", -value=>$symbol, -override=>1),
          # "Start date", '<input type="date" name="start">', br,
          # "Leave empty for earliest date for which data is available", br,
          # "End date", '<input type="date" name="end">', br,
          # "Leave empty for today", br,
           "Start date: ", '<input type="date" name="start" class="portDate">', 
           "&nbsp; &nbsp; &nbsp; End date: ", '<input type="date" name="end" class="portDate">', 

           "&nbsp; &nbsp; &nbsp;", submit, br,

           "<i>Leave start date empty for earliest date for which data is available", br,
           "Leave end date empty for today</i>", br
           #submit,
        end_form;

print   hr;

print   h3("Estimated Future Price");
print   img({src=>"plot_future_price.pl?symbol=$symbol&type=plot&futureSteps=$futureSteps"});
print   start_form({-class=>"form-inline"}),
           hidden(-name=>"portID", -value=>$portID, -override=>1),
           hidden(-name=>"stock", -value=>$symbol, -override=>1),
           "Number of Future Steps (days): ", '<input type="number" name="futureSteps" min=1 step=1>', #br,
	   "&nbsp; &nbsp; &nbsp;", submit, br,          
	   "<i>Leave empty for 7 days</i>", br,
        end_form;
print   "</div>";



# print 	"</div> <!-- end container -->";



print   '<script src="http://twitter.github.com/bootstrap/assets/js/jquery.js" /> </script>', "\n",
        '<script src="http://twitter.github.com/bootstrap/assets/js/bootstrap-collapse.js"> </script>', "\n", 
        '<script src="http://twitter.github.com/bootstrap/assets/js/bootstrap-button.js"> </script>', "\n",
        '<script src="http://twitter.github.com/bootstrap/assets/js/bootstrap-transition.js"> </script>';

print   end_html;
