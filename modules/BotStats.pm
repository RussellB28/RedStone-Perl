# Module: BotStats. See below for documentation.
# Copyright (C) 2017 RedStone Development Group.
# This program is free software; rights to this code are stated in doc/LICENSE.
package M::BotStats;
use strict;
use warnings;
use English qw(-no_match_vars);
use API::Std qw(cmd_add cmd_del);
use API::IRC qw(privmsg);

# Initialization subroutine.
sub _init {
    # Create the BOTSTATS command.
    cmd_add('BOTSTATS', 2, 0, \%M::BotStats::HELP_STATS, \&M::BotStats::cmd_botstats) or return;

    # Success.
    return 1;
}

# Void subroutine.
sub _void {
    # Delete the STATS command.
    cmd_del('BOTSTATS') or return;

    # Success.
    return 1;
}

# Help hash for STATS. Spanish, German and French translations needed.
our %HELP_STATS = (
    en => "This command will return information about the bot (uptime, version, etc.). \2Syntax:\2 STATS",
);

# Callback for STATS command.
sub cmd_botstats {
    my ($src, undef) = @_;

    # Check if this was private or public.
    my $sTarget = ($src->{chan} ? $src->{chan} : $src->{nick});

    # Get uptime data.
    my $sUptime = time - $Auto::STARTTIME;
    my $iDays = my $iHours = my $iMinutes = my $iSeconds = 0;
    while ($sUptime >= 86_400) { $iDays++; $sUptime -= 86_400 }
    while ($sUptime >= 3_600) { $iHours++; $sUptime -= 3_600 }
    while ($sUptime >= 60) { $iMinutes++; $sUptime -= 60 }
    while ($sUptime >= 1) { $iSeconds++; $sUptime-- }

    # Return it.
    privmsg($src->{svr}, $sTarget, "I have been running for \2$iDays\2 days, \2$iHours\2 hours, \2$iMinutes\2 minutes, and \2$iSeconds\2 seconds.");

    # Return version data.
    privmsg($src->{svr}, $sTarget, 'I am running '.Auto::NAME.' (version '.Auto::VER.q{.}.Auto::SVER.q{.}.Auto::REV.Auto::RSTAGE.") for Perl $PERL_VERSION on $OSNAME.");

    # Get network and channel data.
    my $iSockets = keys %Auto::SOCKET;
    my $iNetworks;
    my $iChannels;
    foreach (%Auto::SOCKET) {
        if (Auto::is_ircsock($_)) {
             $iNetworks++;
             foreach (keys %{$Proto::IRC::botchans{$_}}) { $iChannels++; }
        }
    }

    # Return network/channel data.
    privmsg($src->{svr}, $sTarget, "I am on \2$iChannels\2 channels across \2$iNetworks\2 networks. In all, I have \2$iSockets\2 active sockets.");

    return 1;
}


API::Std::mod_init('BotStats', 'RedStone Development Group', '1.00', '3.0.0a11');
# build: perl=5.010000

__END__

=head1 NAME

BotStats - General information about the bot

=head1 VERSION

 1.00

=head1 SYNOPSIS

 <User> !stats
 <RedStone> I have been running for 0 days, 0 hours, 1 minutes, and 5 seconds.
 <RedStone> I am running RedStone IRC Bot (version 3.0.0a11) for Perl v5.12.3 on linux.
 <RedStone> I am on 2 channels, across 1 networks.

=head1 DESCRIPTION

This module creates the STATS command, for returning general information about
the bot such as uptime, version, etc.

This module is compatible with RedStone v3.0.0a10+.

=head1 AUTHOR

This module was written by Elijah Perrault.

This module is maintained by RedStone Development Group.

=head1 LICENSE AND COPYRIGHT

This module is Copyright 2017 RedStone Development Group.

This module is released under the same licensing terms as RedStone itself.

=cut

# vim: set ai et sw=4 ts=4:
