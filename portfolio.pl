#!/usr/bin/perl -w

use strict;

use CGI qw(:standard);

use user;
use common;
use DBI;

require "sql.pl";

redirectIfNotLoggedIn();

print   header,
        start_html( -title=>'Home',
                    -head=>[ Link({ -rel=>"stylesheet",
                                    -href=>"http://twitter.github.com/bootstrap/assets/css/bootstrap-responsive.css"}),
                             Link({ -rel=>"stylesheet",
                                    -href=>"http://twitter.github.com/bootstrap/assets/css/bootstrap.css" })
                            ],
                    -style=>{'src'=>'style.css'}
                            ),
        "\n\n";


print   div({-class=>'navbar'}, "You are logged in as " . getCurrentUser()), "\n",

        div({-class=>'portfolio-actions sidebar'}, "\n",
            h2("Estimated present market value of the portfolio: "),
            h2("Total amount of cash / cash account: "),
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
                "Which stocks
                how many
                for what price
                submit",
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




        );


print   '<script src="http://twitter.github.com/bootstrap/assets/js/jquery.js" /> </script>',
        '<script src="http://twitter.github.com/bootstrap/assets/js/bootstrap-collapse.js"> </script>',
        '<script src="http://twitter.github.com/bootstrap/assets/js/bootstrap-button.js"> </script>',
        '<script src="http://twitter.github.com/bootstrap/assets/js/bootstrap-transition.js"> </script>';



print   end_html;

