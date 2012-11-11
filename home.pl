#!/usr/bin/perl -w

use strict;

use CGI qw(:standard);

use user;
use convenience;
use DBI;

require "sql.pl";

redirectIfNotLoggedIn();

print   header,
        start_html('Home'),
        h1('Home');

print "Hello, " . getCurrentUser();

print   end_html;

