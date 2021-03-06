#!/usr/bin/perl -w
package common;
our @ISA = 'Exporter';
our @EXPORT = qw(   $loginCookieName
                    $covarMatrixCookieName
                    redirectIfNotLoggedIn
                    getCurrentUser
                    refreshCookies
                    checkLogout
                    );

use strict;

use Exporter;
use CGI qw(:standard);
use DBI;
use user;

require "sql.pl";

our $loginCookieName="portfolioLogin";
our $covarMatrixCookieName="covMatrix";

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


sub checkLogout {
    my $action = param("act");

    if (defined($action) and ($action eq "logout")) {
        my @outCookies;
        my $loginCookieOut = cookie(-name=>$loginCookieName,
                -value=>"",
                -expires=>'-1h');
        push @outCookies, $loginCookieOut;
        print redirect(-uri=>'login.pl', -cookie=>\@outCookies);
    }
}


sub getCurrentUser {
    my $loginCookieIn = cookie($loginCookieName);
    my $email = (split(/\//, $loginCookieIn))[0];

    return $email;
}


sub refreshCookies {
    my @outCookies;
    my $loginCookieInData = cookie($loginCookieName);
    my $loginCookieOut = cookie(-name=>$loginCookieName,
            -value=>$loginCookieInData,
            -expires=>'+1h');

    push @outCookies, $loginCookieOut;
    
    return @outCookies;
}


