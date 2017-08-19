# Module: Autojoin. See below for documentation.
# Copyright (C) 2017 RedStone Development Group.
# This program is free software; rights to this code are stated in doc/LICENSE.
package M::Autojoin;
use strict;
use warnings;
use feature qw(switch);
use API::Std qw(conf_get trans cmd_add cmd_del hook_add hook_del);
use API::IRC qw(notice privmsg cpart cjoin);
use API::Log qw(slog dbug alog);

# Initialization subroutine.
sub _init {
    # PostgreSQL is not supported, yet.
    if ($Auto::ENFEAT =~ /pgsql/) { err(3, 'Unable to load Autojoin: PostgreSQL is not supported.', 0); return }


    # Create `autojoin` table.
    $Auto::DB->do('CREATE TABLE IF NOT EXISTS autojoin (net TEXT, chan TEXT, key TEXT)') or return;

    # Create our required hooks.
    hook_add('on_connect', 'autojoin.connect', \&M::Autojoin::on_connect, 1) or return; # Hook at same level as core so nothing stops us.

    cmd_add('AUTOJOIN', 0, 'cmd.autojoin', \%M::Autojoin::HELP_AUTOJOIN, \&M::Autojoin::cmd_autojoin) or return;

    # Success.
    return 1;
}

# Void subroutine.
sub _void {
    # Delete the hooks.
    hook_del('on_connect', 'autojoin.connect') or return;

    # Delete the command.
    cmd_del('AUTOJOIN') or return;

    # Success.
    return 1;
}

# Help for AUTOJOIN.
our %HELP_AUTOJOIN = (
    en => "This command allows manipulation of autojoin. \2Syntax:\2 AUTOJOIN <ADD|DEL|LIST> [ [<#channel>[\@network] [key]] | <network>]",
);

# Subroutine to check if a channel is already on the autojoin list.
sub check_status {
    my ($sNetwork, $sChannel) = @_;
    my $pQuery = $Auto::DB->prepare('SELECT net FROM autojoin WHERE net = ? AND chan = ?') or return 0;
    $pQuery->execute(lc $sNetwork, lc $sChannel) or return 0;
    if ($pQuery->fetchrow_array) {
        return 1;
    }
    return 0;
}

# Subroutine to check if a channel is in the config (legacy autojoin).
sub in_conf {
    my ($sNetwork, $sChannel) = @_;
    return 0 if !conf_get("server:$sNetwork:ajoin");
    my @aJoin = @{ (conf_get("server:$sNetwork:ajoin"))[0] };

    if (!defined $aJoin[1]) {
        my @aSplitJoin = split(',', $aJoin[0]);
        foreach(@aSplitJoin) {
            return 1 if ($_ =~ m/\s/xsm and lc((split(/ /, @aSplitJoin))[0]) eq lc($sChannel));
            return 1 if lc $_ eq lc $sChannel;
        }
    }
    else {
        foreach (@aJoin) {
            return 1 if ($_ =~ m/\s/xsm and lc((split(/ /, @aJoin))[0]) eq lc($sChannel));
            return 1 if lc $_ eq $sChannel;
        }
    }
    return 0;
}

# Callback for the AUTOJOIN command.
sub cmd_autojoin {
    my ($src, @argv) = @_;

    if (!defined $argv[0]) {
        notice($src->{svr}, $src->{nick}, trans('Not enough parameters').q{.});
        return;
    }

    my $sTarget = (defined $src->{chan} ? $src->{chan} : $src->{nick});

    given(uc $argv[0]) {
        when ('ADD') {
            my $sChannel;
            my $sServer = lc($src->{svr});
            if (!defined $argv[1]) {
                notice($src->{svr}, $src->{nick}, trans('Not enough parameters').q{.});
                return;
            }
            $sChannel = $src->{chan};
            if (defined $argv[1]) {
                if ($argv[1] =~ m/(#.*)\@(.*)/) {
                    $sChannel = $1;
                    $sServer = lc($2);
                }
                else {
                    $sChannel = $argv[1];
                }                          
            }
            my $key = (defined $argv[2] ? $argv[2] : undef);
            if(!fix_net($sServer)) {
                privmsg($src->{svr}, $sTarget, "I'm not configured for $sServer.");
                return;
            }
            notice($src->{svr}, $sTarget, "$sChannel\@$sServer is manually configured thus can not be added through AUTOJOIN.") and return if in_conf(fix_net($sServer), $sChannel);
            notice($src->{svr}, $sTarget, "$sChannel\@$sServer is already on my autojoin list.") and return if check_status($sServer, $sChannel);
            if (add($sServer, $sChannel, $key)) {
                $sServer = fix_net($sServer);
                privmsg($src->{svr}, $sTarget, "$sChannel\@$sServer was added to my autojoin list.");
                slog("[\2Autojoin\2] $$src{nick} added $sChannel\@$sServer to my autojoin list.");
                cjoin($sServer, $sChannel, $key);
            }
            else {
                privmsg($src->{svr}, $sTarget, 'Failed to add to autojoin.');
            }

        }
        when ('DEL') {
            my $sChannel;
            my $sServer = lc($src->{svr});
            if (!defined $argv[1]) {
                notice($src->{svr}, $src->{nick}, trans('Not enough parameters').q{.});
                return;
            }
            $sChannel = $src->{chan};
            if (defined $argv[1]) {
                if ($argv[1] =~ m/(#.*)\@(.*)/) {
                    $sChannel = $1;
                    $sServer = lc($2);
                }   
                else {
                    $sChannel = $argv[1];
                }
            }
            if(!fix_net($sServer)) {
                privmsg($src->{svr}, $sTarget, "I'm not configured for $sServer.");
                return;
            }
            notice($src->{svr}, $sTarget, "$sChannel\@$sServer is manually configured thus can not be deleted.") and return if in_conf(fix_net($sServer), $sChannel);
            notice($src->{svr}, $sTarget, "$sChannel\@$sServer is not on my autojoin list.") and return if !check_status($sServer, $sChannel);
            if (del($sServer, $sChannel)) {
                $sServer = fix_net($sServer);
                privmsg($src->{svr}, $sTarget, "$sChannel\@$sServer deleted from my autojoin list.");
                slog("[\2Autojoin\2] $$src{nick} deleted $sChannel\@$sServer from my autojoin list.");
                cpart($sServer, $sChannel, 'Removed from autojoin.');
            }
            else {
                privmsg($src->{svr}, $sTarget, 'Failed to delete from autojoin.');
            }
        }
        when ('LIST') {
            my $sServer = (defined $argv[1] ? lc($argv[1]) : lc($src->{svr}));
            my $sChannel = $src->{chan};
            if(!fix_net($sServer)) {
                privmsg($src->{svr}, $sTarget, "I'm not configured for $sServer.");
                return;
            }
            my $pQuery = $Auto::DB->prepare('SELECT chan FROM autojoin WHERE net = ?');
            $pQuery->execute(lc $sServer);
            my @aChannel1 = $dbh->fetchall_arrayref;
            my @aChannel2 = ();
            foreach my $sFirst (@aChannel1) {
                foreach my $sSecond (@{$sFirst}) {
                    foreach my $sChannel (@{$sSecond}) {
                        push @aChannel2, $sChannel;
                    }
                }
            }
            privmsg($src->{svr}, $sTarget, join ', ', @aChannel2);
        }
        default {
            # We don't know this command.
            notice($src->{svr}, $src->{nick}, trans('Unknown action', $_).q{.});
            return;
        }
    }

   return 1;
}

sub on_connect {
    my ($sServer) = @_;
    my $pQuery = $Auto::DB->prepare('SELECT * FROM autojoin WHERE net = ?');
    $pQuery->execute(lc $sServer);
    my $hChannels = $dbh->fetchall_hashref('chan');
    foreach my $sChannel (keys %$hChannels) {
        cjoin($sServer, $sChannel, $hChannels->{$sChannel}->{key});
    }
}

sub fix_net {
    my ($sServer) = @_;
    my %hServers = conf_get('server');
    foreach my $sServerName (keys %hServers) {
         if (lc($sServerName) eq lc($sServer)) {
              return $sServerName;
         }
    }
    return 0;
}

# Begin API
sub add {
    my ($sServer, $sChannel, $sChanKey) = @_;
    my $pQuery = $Auto::DB->prepare('INSERT INTO autojoin (net, chan, key) VALUES (?, ?, ?)');
    return 1 if $pQuery->execute(lc $sServer, lc $sChannel, $sChanKey);
    return 0;
}

sub del {
    my ($sServer, $sChannel) = @_;
    my $pQuery = $Auto::DB->prepare('DELETE FROM autojoin WHERE net = ? AND chan = ?');
    return 1 if $pQuery->execute(lc $sServer, lc $sChannel);
    return 0;
}

# Start initialization.
API::Std::mod_init('Autojoin', 'RedStone Development Group', '1.00', '3.0.0a11');
# build: perl=5.010000

__END__

=head1 NAME

Autojoin

=head1 VERSION

 1.00

=head1 SYNOPSIS

<User> !autojoin add #channel
<RedStone> #channel@network added to my autojoin list.

=head1 DESCRIPTION

This module separates autojoin from the core. This allows us to easily manipulate it.

=head2 Notes

This module does not care if a network is deleted from the configuration. This will change when
servers are added to the db as well. With that will come a server manipulation module as well.
Also, eventually support for legacy autojoins (in the config) will be dropped. Please start using
this. This module also can not tell the difference of when a channel is added to manual autojoin.
That being said if you add a channel to the config that's already in the db do not complain
when you can't delete it.

=head1 AUTHOR

This module was written by Matthew Barksdale.

This module is maintained by RedStone Development Group.

=head1 LICENSE AND COPYRIGHT

This module is Copyright 2017 RedStone Development Group.
reserved.

This module is released under the same licensing terms as RedStone itself.

=cut

# vim: set ai et ts=4 sw=4:

