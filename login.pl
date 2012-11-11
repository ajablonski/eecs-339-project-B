#!/usr/bin/perl -w

use strict;

use CGI qw(:standard);

use DBI;

require "sql.pl";

my $dbuser="amj650";
my $dbpasswd="z40wkjgIK";

my $loginCookieName="portfolioLogin";

my $loginCookieIn = cookie($loginCookieName);

my $loginCookieOut = undef;

my $loginComplain = 0;

my @outCookies = undef;

my $run;

if (defined(param("run"))) {
    $run = param("run") == 1;
} else {
    $run = 0;
}

if ($run) {
    my $sqlString = '';
    $sqlString .= "SELECT COUNT(*) FROM amj650.users ";
    $sqlString .= " WHERE email = ? ";
    $sqlString .= " AND password = ? ";
    my $email = param("email");
    my $passwd = param("password");
    my @sqlResultRow;
    @sqlResultRow = ExecSQL($dbuser, $dbpasswd, $sqlString, 'ROW', $email, $passwd);
    if ($sqlResultRow[0] == 1) {
        $loginCookieOut = join("/", $email, $passwd);
        my $cookie = cookie(-name=>$loginCookieName,
                -value=>$loginCookieOut,
                -expires=>'+1h');
        push @outCookies, $cookie;
        print redirect(-uri=>'home.pl', -cookie=>\@outCookies);
    } else {
        $loginComplain = 1;
        $run = 0;
    }
}

print   header,
        start_html('Login to portfolio manager'),
        h1('Login');

if (!$run) {
    if ($loginComplain) {
        print "Invalid credentials. Try again.", p;
    }

    print   start_form(-name=>'Login'),
            "Email: ", p, textfield(-name=>'email'), p,
            "Password: ", p, password_field(-name=>'password'), p,
            hidden(-name=>'run',-default=>['1']),
            submit,
            end_form;

    print   a({href=>"register.pl"}, "Register for a login");
}


print   end_html;

