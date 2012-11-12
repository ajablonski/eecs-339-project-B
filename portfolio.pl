#!/usr/bin/perl -w

#
#
# portfolio.pl
#----------------------------------------------------------------------------------
# EECS 339: Databases
# Fall 2012, Dinda
#
# Lizz Bartos - eab879
# Stephen Duraski - sjd842
# Alex Jablonski -
#----------------------------------------------------------------------------------
#
# Example code for EECS 339, Northwestern University
#
#
#

#
# BASE
#
# The base action presents the overall page to the browser
#
#
#
if ($action eq "base") {
    
    

    #
    # The Javascript portion of our app
    #
    #print "<script type=\"text/javascript\" src=\"rwb.js\"> </script>";
    
    
    #
    # User mods
    #
    #
    #if ($user eq "anon") {
    #    print "<p>You are anonymous, but you can also <a href=\"rwb.pl?act=login\">login</a></p>";
    #}
    #else {
        # for other users, display links to things they have permission to do
    #   print "<p>You are logged in as $user and can do the following:</p>";
    # if (UserCan($user,"give-opinion-data")) {
    #       print "<a href=\"rwb.pl?act=give-opinion-data\" width=40px\">Give Opinion Of Current Location</a> <br/>";
            #}
        
    #  if (UserCan($user,"manage-users") || UserCan($user,"add-users")) {
    #       print "<a href=\"portfolio.pl?act=add-user\">Add User</a> <br/>";
    #   }
       
    #   print "<p><a href=\"portfolio.pl?act=logout&run=1\">Logout</a></p>";
    #}
    
    if ($user) {
        print "<p> Hello, $user. You are logged in.";
        print "<br/> <a href='#'>Log out</a></p>";
    }
    
    else {
        print "<p>You are anonymous, but you can also <a href=\"rwb.pl?act=login\">login</a></p>";
    }
    

    #
    # The Sidebar Div, which displays actions the user can do
    #
    print "<div id='sidebar'>";
    

    
    

    
    
    print "</div>"; # end the sidebar div
    
}