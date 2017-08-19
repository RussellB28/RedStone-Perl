# Module: FML. See below for documentation.
# Copyright (C) 2017 RedStone Development Group.
# This program is free software; rights to this code are stated in doc/LICENSE.
package M::FML;
use strict;
use warnings;
use API::Std qw(cmd_add cmd_del trans);
use API::IRC qw(privmsg notice);
use HTML::Tree;

# Initialization subroutine.
sub _init {
    # Create the FML command.
    cmd_add('FML', 0, 0, \%M::FML::HELP_FML, \&M::FML::cmd_fml) or return;

    # Success.
    return 1;
}

# Void subroutine.
sub _void {
    # Delete the FML command.
    cmd_del('FML') or return;

    # Success.
    return 1;
}

# Help hash.
our %HELP_FML = (
    en => "This command will return a random FML quote. \2Syntax:\2 FML",
    de => "Dieser Befehl liefert eine zufaellige Zitat von FML. \2Syntax:\2 FML",
);

# Callback for FML command.
sub cmd_fml {
    my ($src, undef) = @_;

    $Auto::http->request(
        url => 'http://www.fmylife.com/random',
        on_response => sub {
            my $sResponse = shift;
            if ($sResponse->is_success) {
                # If successful, get the content.
                my $pTree = HTML::Tree->new();
                $pTree->parse($sResponse->decoded_content);
                my $sData = $pTree->look_down('_tag', 'p', 'class', 'block');

                # Parse it.
                my $sFML = $sData->as_text;
                $sFML =~ s/\sFML.*//xsm;

                # Return the FML.
                privmsg($src->{svr}, $src->{target}, "\2Random FML:\2$sFML FML");
                $pTree->delete;
            }
            else {
                # Otherwise, send an error message.
                privmsg($src->{svr}, $src->{target}, 'An error occurred while retrieving the FML.');
            }
        },
        on_error => sub {
            my $sError = shift;
            privmsg($src->{svr}, $src->{target}, "An error occurred while retrieving the FML: $sError");
        }
    );

    return 1;
}

# Start initialization.
API::Std::mod_init('FML', 'RedStone Development Group', '1.00', '3.0.0a11');
# build: cpan=HTML::Tree perl=5.010000

__END__

=head1 NAME

 FML - A module for retrieving random FML quotes

=head1 VERSION

 1.00

=head1 SYNOPSIS

 <User> !fml
 <RedStone> Random FML: Today, I told my mom I loved her a lot. Her reply? "Thanks." FML

=head1 DESCRIPTION

This module creates the FML command, which will retrieve a random FML quote
and message it to the channel.

=head1 DEPENDENCIES

This module depends on the following CPAN modules:

=over

=item L<HTML::Tree>

This is the HTML parser.

=back

=head1 AUTHOR

This module was written by Russell Bradford.

This module is maintained by RedStone Development Group.

=head1 LICENSE AND COPYRIGHT

This module is Copyright 2017 RedStone Development Group.

Released under the same licensing terms as RedStone itself.

=cut

# vim: set ai et sw=4 ts=4:
