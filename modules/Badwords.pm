# Module: Badwords. See below for documentation.
# Copyright (C) 2017 RedStone Development Group.
# This program is free software; rights to this code are stated in doc/LICENSE.
package M::Badwords;
use strict;
use warnings;
use feature qw(switch);
use API::Std qw(hook_add hook_del conf_get err);
use API::IRC qw(privmsg notice kick ban);

# Initialization subroutine.
sub _init  {
    # Check for required configuration values.
    if (!conf_get('badwords')) {
        err(2, 'Please verify that you have a badwords block with word entries defined in your configuration file.', 0);
        return;
    }
    # Create the act_on_badword hook.
    hook_add('on_cprivmsg', 'act_on_badword', \&M::Badwords::actonbadword) or return;

    # Success.
    return 1;
}

# Void subroutine.
sub _void  {
    # Delete the act_on_badword hook.
    hook_del('act_on_badword') or return;

    # Success.
    return 1;
}

# Callback for act_on_badword hook.
sub actonbadword {
    my (($src, $sChannel, @sMessage)) = @_;

    my $sMessage = join ' ', @sMessage;

    if (conf_get("badwords:$sChannel:word")) {
        my @aWords = @{ (conf_get("badwords:$sChannel:word"))[0] };

        foreach (@aWords) {
            my ($sWord, $sAction) = split m/[:]/, $_;

            if ($sMessage =~ m/($sWord)/ixsm) {
                given ($sAction) {
                    when ('kick') { 
                        kick($src->{svr}, $sChannel, $src->{nick}, 'Foul language is prohibited here.'); 
                    }
                    when ('kickban') { 
                        ban($src->{svr}, $sChannel, 'b', $src); 
                        kick($src->{svr}, $sChannel, $src->{nick}, 'Foul language is prohibited here.'); 
                    }
                    when ('quiet') { 
                        ban($src->{svr}, $sChannel, 'q', $src); 
                    }
                    default { 
                        kick($src->{svr}, $sChannel, $src->{nick}, 'Foul language is prohibited here.'); 
                    }
                }
            }
        }
    }

    return 1;
}


API::Std::mod_init('Badwords', 'RedStone Development Group', '1.00', '3.0.0a11');
# build: perl=5.010000

__END__

=head1 Badwords

=head2 Description

=over

This module adds the ability to kick/ban a user if a configured word is
sent by them in a PRIVMSG to a configured channel using a badwords block.

=back

=head2 How To Use

=over

Add Badwords to module auto-load and the following to your configuration file:

  badwords "#channel" {
    word "foo:kick";
    word "bar:kickban";
    word "moo:quiet";
    word "cows:kickban";
  }

Changing the obvious to your wish.

=back

=head2 Examples

=over

  badwords "#johnsmith" {
    word "moo:ban";
  }

<troll> moo
* Auto sets mode +b *!*@troll.com
* Auto has kicked troll from #johnsmith (Foul language is prohibited here.)

=back

=head2 Technical

=over

This module is compatible with RedStone version 3.0.0a10+.

=back

# vim: set ai et sw=4 ts=4:
