#!/usr/bin/perl -w
package convenience;
our @ISA = 'Exporter';
our @EXPORT = qw(   $loginCookieName
                    redirectIfNotLoggedIn
                    getCurrentUser
                    );

use strict;

use Exporter;
use CGI qw(:standard);
use DBI;
use user;

require "sql.pl";

our $loginCookieName="portfolioLogin";

sub redirectIfNotLoggedIn {
    my $loginCookieIn = cookie($loginCookieName);

    if (!defined($loginCookieIn)) {
        print redirect('login.pl');
    } else {
        # check cookie data against database
        my ($email, $password) = split(/\//, $loginCookieIn);

        my $sqlString = '';
        $sqlString .= "SELECT COUNT(*) FROM $netID.users ";
        $sqlString .= "WHERE email = ? AND password = ? AND validation_code IS NULL ";
        my @row;
        eval {
            @row = ::ExecSQL($dbuser, $dbpasswd, $sqlString, 'ROW', $email, $password);
        };
        my $error = $@;

        if ($error or $row[0] != 1) {
            print redirect('login.pl');
        }
    }
}

sub getCurrentUser {
    my $loginCookieIn = cookie($loginCookieName);
    my $email = (split(/\//, $loginCookieIn))[0];

    return $email;
}

