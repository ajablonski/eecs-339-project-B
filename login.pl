#!/usr/bin/perl -w
#
# The combination of -w and use strict enforces various
# rules that make the script more resilient and easier to run
# as a CGI script.
#
use strict;


# The CGI web generation stuff
# This helps make it easy to generate active HTML content
# from Perl
#
# We'll use the "standard" procedural interface to CGI
# instead of the OO default interface
use CGI qw(:standard);


# The interface to the database.  The interface is essentially
# the same no matter what the backend database is.
#
# DBI is the standard database interface for Perl. Other
# examples of such programatic interfaces are ODBC (C/C++) and JDBC (Java).
#
#
# This will also load DBD::Oracle which is the driver for
# Oracle.
use DBI;
use user;
use common;
require "sql.pl";


#
# The session cookie will contain the user's name and password so that
# he doesn't have to type it again and again.
#
# "RWBSession"=>"user/password"
#
# BOTH ARE UNENCRYPTED AND THE SCRIPT IS ALLOWED TO BE RUN OVER HTTP
# THIS IS FOR ILLUSTRATION PURPOSES.  IN REALITY YOU WOULD ENCRYPT THE COOKIE
# AND CONSIDER SUPPORTING ONLY HTTPS
#
my $loginCookieName="portfolioLogin";

#
# Get the session input cookies, if any
#
my $loginCookieIn = cookie($loginCookieName);

#
# Will be filled in as we process the cookies and parameters
#
my $loginCookieOut = undef;

# added by lizz based on rwb...
my @outCookies = undef;

my $deletecookie=0;

my $loginComplain = 0;
my $registerComplain = 0;


#
# Get whether the user wants us to run the form
#
my $run;
my $action;
if (defined(param("act"))) {
    $action = param("act");
} else {
    $action = "login"
}

if (defined(param("run"))) {
    $run = param("run") == 1;
} else {
    $run = 0;
}

# Begin HTTP/HTML generation. This first section just handles redirection

if ($run and ($action eq "login")) {
    #
    # Login attempt
    #
    # Ignore any input cookie.  Just validate user and
    # generate the right output cookie, if any.
    #
    my $sqlString = '';
    $sqlString .= "SELECT COUNT(*) FROM $netID.users ";
    $sqlString .= " WHERE email = ? ";
    $sqlString .= " AND password = ? ";
    $sqlString .= " AND validation_code IS NULL ";
    my $email = param("email");
    my $passwd = param("password");
    my @sqlResultRow;
    @sqlResultRow = ExecSQL($dbuser, $dbpasswd, $sqlString, 'ROW', $email, $passwd);
    if ($sqlResultRow[0] == 1) {
        # if the user's info is OK, then give him a cookie
        # that contains his username and password
        # the cookie will expire in one hour, forcing him to log in again
        # after one hour of inactivity.
        $loginCookieOut = join("/", $email, $passwd);
        my $cookie = cookie(-name=>$loginCookieName,
                -value=>$loginCookieOut,
                -expires=>'+1h');
        push @outCookies, $cookie;
        print redirect(-uri=>'home.pl', -cookie=>\@outCookies);
    } else {
        # uh oh.  Bogus login attempt.  Make him try again.
        # don't give him a cookie
        $loginComplain = 1;
        $run = 0;
    }
}

# End redirection section. Begin section where user will stay on this page (HTML)

#
# If we are being asked to log out, then if
# we have a cookie, we should delete it.
#
#if ($action eq "logout") {
#  $deletecookie=1;
#  $action = "base";
#  $user = "anon";
#  $password = "anonanon";
#  $run = 1;
#}

print   header,
        start_html('Login to portfolio manager');


if ($run and ($action eq "register")) {
    my $email = param('regEmail');
    my $password = param('regPassword');
    my $key = int(rand(10000000));
    my $sqlString = '';
    $sqlString .= "INSERT INTO $netID.users (email, password, validation_code) ";
    $sqlString .= " VALUES (?, ?, ?) ";
    my $error;
    eval {
	ExecSQL($dbuser, $dbpasswd, $sqlString, undef, 
	    $email, $password, $key);
    };
    $error = $@;
    if (!$error) {
        my $subject = "'Registration for Portfolio Manager'";
        my $content = '';
        $content .= "Follow this link to confirm your registration: \n";
        $content .= "http://murphy.wot.eecs.northwestern.edu/~$netID/portfolio/";
        $content .= "login.pl?act=confirm&key=$key";

        open(MAIL, "| mail -s $subject $email") or die "Can't run mail\n";
        print MAIL $content;
        close(MAIL);

        print "Email successfully sent.", p;
        print   a({href=>"login.pl"}, "Return to login page");
    } else {
        $registerComplain = 1;
        $action = 'login';
        $run = 0;
    }
}


if ($action eq "confirm") {
    my $key = param('key');

    my $sqlString = '';
    $sqlString .= "UPDATE $netID.users SET validation_code=NULL WHERE validation_code = ?";
    local $@;
    my $error = undef;
    eval {
        ExecSQL($dbuser, $dbpasswd, $sqlString, undef, $key);
    };
    $error = $@;

    if ($error) {
        print "Confirmation error.", p;

        print $error;
    } else {
        print "Confirmation successful. You may now log in. ";
        $action = 'login';
        $run = 0;
    }
}


if (!$run and ($action eq 'login')) {

    print   "<div id='login' style='display: block; float: left; padding: 15px 30px;'>",
            h1('Login');

    if ($loginComplain) {
        print "Invalid credentials. Try again.", p;
    }

    print   start_form(-name=>'Login'),
            "Email: ", p, textfield(-name=>'email'), p,
            "Password: ", p, password_field(-name=>'password'), p,
            hidden(-name=>'run', -default=>['1']),
            hidden(-name=>'act', -value=>'login', -override=>1),
            submit,
            end_form,
            "</div> <!-- end login div -->";


    print   "<div id='register' style='display: block; float: left; padding: 15px 30px;'>",
            h1('Register');

    if ($registerComplain) {
        print "Registration failed. Either your email is already in use, ",
            "or your password was not valid.", p;
    }

    print   start_form(-name=>'Register'),
            "Email: ", p, textfield(-name=>'regEmail'), p,
            "Password: ", p, password_field(-name=>'regPassword'), p,
            hidden(-name=>'run', -default=>['1']),
            hidden(-name=>'act', -value=>'register', -override=>1),
            submit,
            end_form,
            "</div> <!-- end register div -->";
}

print   end_html;

