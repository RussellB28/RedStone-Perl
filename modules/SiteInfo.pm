# Module: LinkTitle. See below for documentation.
# Copyright (C) 2017 RedStone Development Group.
# This program is free software; rights to this code are stated in doc/LICENSE.
package M::SiteInfo;
use strict;
use warnings;
use API::Std qw(conf_get cmd_add cmd_del trans hook_add hook_del err);
use API::IRC qw(privmsg notice);
use URI::Escape;
use HTML::Tree;
use HTML::Entities qw(decode_entities);

# Initialization subroutine.
sub _init {
    # Retrieve Configuration
    if (!conf_get('siteinfo:in_channel')) {
        err(2, "SiteInfo: Please verify that you have defined whether site info should be displayed automatically in channels when a URI is posted.", 0);
    }
    if (!conf_get('siteinfo:in_private')) {
        err(2, "SiteInfo: Please verify that you have defined whether site info should be displayed automatically in private messages when a URI is posted.", 0);
    }

    # Create Commands and Hooks
    if((conf_get('siteinfo:in_channel'))[0][0] == 1)
    {
        hook_add('on_cprivmsg', 'privmsg.html.siteinfoc', \&M::SiteInfo::hook_siteinfoc) or return;
    }
    if((conf_get('siteinfo:in_private'))[0][0] == 1)
    {
        hook_add('on_uprivmsg', 'privmsg.html.siteinfou', \&M::SiteInfo::hook_siteinfou) or return;
    }
    cmd_add('SITEINFO', 0, 0, \%M::SiteInfo::FHELP_SITEINFO, \&M::SiteInfo::cmd_siteinfo) or return;

    # Success.
    return 1;
}

# Void subroutine.
sub _void {
    # Delete Commands and Hooks
    if((conf_get('siteinfo:in_channel'))[0][0] == 1)
    {
        hook_del('on_cprivmsg', 'privmsg.html.siteinfoc') or return;
    }
    if((conf_get('siteinfo:in_private'))[0][0] == 1)
    {
        hook_del('on_uprivmsg', 'privmsg.html.siteinfou') or return;
    }
    cmd_del('SITEINFO') or return;

    # Success.
    return 1;
}

our %FHELP_SITEINFO = (
    en => "This command will retrieve the title and description of a given url. \2Syntax:\2 SITEINFO <HTTP/HTTPS URL>",
);

# Hook callback
sub hook_siteinfoc {
    my ($src, $chan, @msg) = @_;

    if ($msg[0] =~ m{^(http|https)://.*\..*}xsm) {
        my $sURL = $msg[0];
        func_getinfo($src,$sURL);
        return 1;
    }

}

sub hook_siteinfou {
    my ($src, @msg) = @_;

    if ($msg[0] =~ m{^(http|https)://.*\..*}xsm) {
        my $sURL = $msg[0];
        func_getinfo($src,$sURL);
        return 1;
    }

}

# Command callback.
sub cmd_siteinfo {
    my ($src, @argv) = @_;

    if (!defined $argv[0]) {
        notice($src->{svr}, $src->{nick}, trans('Not enough parameters').q{.});
        return;
    }

    # Check if the message contains a URL.
    if ($argv[0] !~ m{^(http|https)://.*\..*}xsm) {
        privmsg($src->{svr}, $src->{target}, 'The URL entered is not valid. Supported types are HTTP or HTTPS.');
        return;
    }

    func_getinfo($src,$argv[0]);

    return 1;
}

sub func_getinfo {
    my ($src, $sURI) = @_;
    $Auto::http->request(
        url => $sURI,
        on_response => sub {
            my $hResponse = shift;
            if (!$hResponse->is_success)
            {
                privmsg($src->{svr}, $src->{target}, "\002(".$hResponse->code.")\002 ".$hResponse->message." - The website you requested information about is not available");
                return;
            }

            # Get data  parse it.
            my $pTree = HTML::Tree->new();
            $pTree->parse($hResponse->decoded_content);
            my $sDescription = $pTree->look_down('_tag', 'meta', 'name', 'description');
            my $sTitle = $pTree->look_down('_tag', 'title');

            my $sDispTitle = "No Title";
            my $sDispDescription = "No Description";

            if($sTitle)
            {
               $sDispTitle = $sTitle->as_text;
            }

            if($sDescription)
            {
               $sDispDescription = $sDescription->as_HTML;
               $sDispDescription =~ s/<meta content="//g;
               $sDispDescription =~ s/" name="description" \/>//g;
            }

            privmsg($src->{svr}, $src->{target}, "\002Title:\002 ".decode_entities($sDispTitle));
            privmsg($src->{svr}, $src->{target}, "\002Description:\002 ".decode_entities($sDispDescription));
            $pTree->delete;
        },
        on_error => sub {
            my $sError = shift;
            privmsg($src->{svr}, $src->{target}, "An error occurred while retrieving information: $sError");
        }
    );
}

# Start initialization.
API::Std::mod_init('SiteInfo', 'RedStone Development Group', '1.00', '3.0.0a11');
# build: cpan=URI::Escape,HTML::Tree,HTML::Entities perl=5.010000

__END__

=head1 NAME

SiteInfo - A module for returning the page title and description of links.

=head1 VERSION

 1.00

=head1 SYNOPSIS

 <User> !siteinfo http://rbradford.me/
 <RedStone> Title: Russell M Bradford - Welcome!
 <RedStone> Description: This is the personal website of Russell Bradford. You may be able to find out more about me here.

=head1 DESCRIPTION

This module will make RedStone when configured, parse all links sent to a channel or to a private message. When a link is
detected, RedStone will connect to it and get the page title by scanning for the
<title> tag and the description using the <meta name="Description"> tag and return its contents to the channel or user.

This module replaces the former and now deprecated LinkTitle module.

=head1 DEPENDENCIES

This module is dependent on three modules from the CPAN.

=over

=item L<URI::Escape>

This module is used for escaping html characters that may be used in titles or descriptions

=item L<HTML::Tree>

This module is used to locate the title and description tags within the web page

=item L<HTML::Entities>

This module is used for escaping html characters that may be used in titles or descriptions

=back

=head1 AUTHOR

This module was written by Russell Bradford.

This module is maintained by RedStone Development Group.

=head1 LICENSE AND COPYRIGHT

This module is Copyright 2017 RedStone Development Group.
reserved.

This module is released under the same licensing terms as RedStone itself.

=cut

# vim: set ai et sw=4 ts=4:
