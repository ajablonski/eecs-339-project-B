#!/usr/bin/perl -w

use strict;

use CGI qw(:standard);

use user;
use common;
use DBI;

require "sql.pl";

redirectIfNotLoggedIn();

print   header,
        start_html('Home'),
        h1('Home');

print "Hello, " . getCurrentUser(), p;

print   a({-href=>"portfolio.pl"}, "Portfolio view template"), p,
        a({-href=>"stockView.html"}, "Stock view template");

print   end_html;

