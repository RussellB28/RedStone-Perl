# Module: Urban. See below for documentation.
# Copyright (C) 2017 RedStone Development Group.
# This program is free software; rights to this code are stated in doc/LICENSE.
package M::Urban;
use strict;
use warnings;
use HTML::Tree;
use URI::Escape;
use API::Std qw(cmd_add cmd_del conf_get trans);
use API::IRC qw(privmsg notice);
my $iLastUsed = 0;

# Initialization subroutine.
sub _init {
    # Create the UD command.
    cmd_add('UD', 0, 0, \%M::Urban::HELP_UD, \&M::Urban::cmd_ud) or return;

    # Success.
    return 1;
}

# Void subroutine.
sub _void {
    # Delete the UD command.
    cmd_del('UD') or return;

    # Success.
    return 1;
}

# Help hash for UD.
our %HELP_UD = (
    en => "Look up a term on Urban Dictionary. \2Syntax:\2 UD <term>",
);

# Callback for UD command.
sub cmd_ud {
    my ($src, @argv) = @_;

    # One parameter required.
    if (!defined $argv[0]) {
        notice($src->{svr}, $src->{nick}, trans('Not enough parameters').q{.});
        return;
    }

    # Ratelimit?
    if (conf_get('urban_ratelimit')) {
        if (time - $iLastUsed <= (conf_get('urban_ratelimit'))[0][0]) {
            notice($src->{svr}, $src->{nick}, 'This command has been used recently. Please wait a moment before using it again.');
            return;
        }
    }
    
    my $sTerm = join(q{ }, @argv);
    my $sURI = 'http://www.urbandictionary.com/define.php?term='.uri_escape($sTerm);

    $Auto::http->request(
        url => $sURI,
        on_response => sub {
            my $sResponse = shift;

            if ($sResponse->is_success) {
                my $pTree = HTML::Tree->new();
                $pTree->parse($sResponse->decoded_content);

                my $sDefinition = $pTree->look_down('_tag', 'div', 'class', 'meaning');
                my $sExample = $pTree->look_down('_tag', 'div', 'class', 'example');

                if (defined $sDefinition) {
                    # Almost there, make sure we're getting the whole thing.
                    if ($sDefinition->as_text =~ m/\.\.\.$/xsm) {
                        my $iID = $pTree->look_down('_tag', 'td', 'id', qr/entry_[0-9]+/);
                        $iID = $iID->attr('id');
                        $iID =~ s/[^0-9]//gxsm;
                        
                        my $sURL = $pTree->look_down('_tag', 'a', 'href', qr/\/define\.php\?term=(.+)&defid=$iID/);
                        if (defined $sURL) {
                            $pTree->delete;
                            return (-1, $iID);
                        }
                    }

                    my $sDefText = $sDefinition->as_text;
                    my $sExamText = 'None';
                    if (defined $sExample) { $sExamText = $sExample->as_text }
                    $pTree->delete;
                    if (length $sDefText > 1536) { $sDefText = substr $sDefText, 0, 1536; $sDefText .= '.....' }
                    if (length $sExample > 1536) { $sExample = substr $sExample, 0, 1536; $sExample .= '.....' }
                    privmsg($src->{svr}, $src->{target}, "\2Definition:\2 ".$sDefText);
                    privmsg($src->{svr}, $src->{target}, "\2Example:\2 ".$sExamText);
                    $iLastUsed = time;
                    return 1;
                } else {
                    # No results.
                    $pTree->delete;
                    privmsg($src->{svr}, $src->{target}, "No results for \2".$sTerm."\2.");
                    return 0;
                }
                $pTree->delete;
            }
        },
        on_error => sub {
            my $sError = shift;
            privmsg($src->{svr}, $src->{target}, "An error occurred while while retrieving the definition: $sError");
            return 0;
        },
    );
    return 1;
}

# Start initialization.
API::Std::mod_init('Urban', 'RedStone Development Group', '1.00', '3.0.0a11');
# build: perl=5.010000 cpan=HTML::Tree,URI::Escape

__END__

=head1 NAME

Urban - IRC interface to Urban Dictionary.

=head1 VERSION

 1.03

=head1 SYNOPSIS

 <User> !ud foobar
 <RedStone> Definition: A common term found in unix/linux/bsd program help pages as space fillers for a word. Or, can be used as a less intense or childish form of fubar.
 <RedStone> Example: To run the program, simply cd to the directory you installed it in like this: user@localhost cd foo/bar or The server foobared again?

=head1 DESCRIPTION

This creates the UD command which looks up the given term on
urbandictionary.com and returns the first definition+example.

=head1 CONFIGURATION

Simply add the following to your configuration file:

 urban_ratelimit <time in seconds>;

Where <time in seconds> is how often the UD command may be used. Like so:

 urban_ratelimit 3;

Not including this will make it use no ratelimit. (discouraged, unless you use
a good value for the bot-wide ratelimit)

=head1 DEPENDENCIES

This module depends on the following CPAN modules:

=over

=item L<URI::Escape>

The tool used to encode unsafe URL characters.

=item L<HTML::Tree>

The tool used to parse the data returned by Urban Dictionary.

=back

=head1 AUTHOR

This module was written by Elijah Perrault.

This module is maintained by RedStone Development Group.

=head1 LICENSE AND COPYRIGHT

This module is Copyright 2017 RedStone Development Group.

Released under the same licensing terms as RedStone itself.

=cut

# vim: set ai et sw=4 ts=4:
