#!/usr/bin/perl -w

use strict;

use CGI qw(:standard);

use DBI;

require "sql.pl";

my $dbuser="amj650";
my $dbpasswd="z40wkjgIK";

my $run;
my $action;
my $registerComplain;

if (defined(param("act"))) {
    $action = param("act");
} else {
    $action = "register";
}



if (defined(param("run"))) {
    $run = param("run") == 1;
} else {
    $run = 0;
}

print   header,
        start_html('Register'),
        h1('Register');

if ($action eq "register") {
    if ($run) {
        my $email = param('email');
        my $password = param('password');
        my $key = int(rand(10000000));
        my $sqlString = '';
        $sqlString .= "INSERT INTO amj650.users (email, password, validation_code) ";
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
            $content .= "http://murphy.wot.eecs.northwestern.edu/~amj650/portfolio/";
            $content .= "register.pl?act=confirm&key=$key";

            open(MAIL, "| mail -s $subject $email") or die "Can't run mail\n";
            print MAIL $content;
            close(MAIL);

            print "Email successfully sent.", p;
            print   a({href=>"login.pl"}, "Return to login page");
        } else {
            $registerComplain = 1;
            $run = 0;
        }
    }

    if (!$run)  {
        if ($registerComplain) {
            print "Registration failed. Either your email is already in use, ",
                "or your password was not valid.", p;
        }
        print   start_form(-name=>'Register'),
                "Email: ", p, textfield(-name=>'email'), p,
                "Password: ", p, password_field(-name=>'password'), p,
                hidden(-name=>'run', -default=>['1']),
                submit,
                end_form;
    }
} elsif ($action eq "confirm") {
    my $key = param('key');

    my $sqlString = '';
    $sqlString .= "UPDATE amj650.users SET validation_code=NULL WHERE validation_code = ?";
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
        print "Confirmation successful. Go to ";

        print a({href=>'login.pl'}, "login");
    }
}


print   end_html;
