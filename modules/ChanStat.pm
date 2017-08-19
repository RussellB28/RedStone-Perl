# Module: ChanStat. See below for documentation.
# Copyright (C) 2017 RedStone Development Group.
# This program is free software; rights to this code are stated in doc/LICENSE.
package M::ChanStat;
use strict;
use warnings;
use API::Std qw(cmd_add cmd_del hook_add hook_del rchook_add rchook_del has_priv match_user);
use API::IRC qw(privmsg notice who);
my ($STATE, $sOption);
my $iAwayUsers = 0;
my $iOpers = 0;
my $iBots = 0; 
my $iRegisteredUsers = 0;
my $iHereUsers = 0;

my $iOwnerUsers = 0;
my $iAdminUsers = 0;
my $iOperatorUsers = 0;
my $iHalfOpUsers = 0;
my $iVoiceUsers = 0;
my $iLastUsed = 0;

# Initialization subroutine.
sub _init {
    cmd_add('CHANSTAT', 0, 0, \%M::ChanStat::HELP_CHANSTAT, \&M::ChanStat::cmd_chanstat) or return;
    hook_add('on_whoreply', 'chanstat.who', \&M::ChanStat::on_whoreply) or return;
    # Hook onto numeric 315.
    rchook_add('315', 'chanstat.eow', \&M::ChanStat::on_eow) or return;
    # Success.
    return 1;
}

# Void subroutine.
sub _void {
    cmd_del('CHANSTAT') or return;
    hook_del('on_whoreply', 'chanstat.who') or return;
    # Delete 315 hook.
    rchook_del('315', 'chanstat.eow') or return;
    # Success.
    return 1;
}

# Help for CHANSTAT.
our %HELP_CHANSTAT = (
    en => "This command will show the current channels user statistics. \2Syntax:\2 CHANSTAT",
);

# Callback for CHANSTAT command.
sub cmd_chanstat {
    my ($src, @argv) = @_;


    if(defined($argv[0]))
    {
        $sOption = lc($argv[0]);
    }
    else
    {
        $sOption = "count";
    }

    # Check ratelimit (once every two minutes).
    if ((time - $iLastUsed) < 10) {
        notice($src->{svr}, $src->{nick}, 'This command is ratelimited. Please wait a while before using it again.');
        return;
    }

    # Set last used time to current time.
    $iLastUsed = time;

    $STATE = $src->{svr}.'::'.$src->{chan};

    # Ship off a WHO.
    who($src->{svr}, $src->{chan});

    return 1;
}

# Callback for WHO reply.
sub on_whoreply {
    my ($sServer, undef, $sChannel, undef, undef, undef, $sStatus, undef, undef) = @_;
    
    # Check if we're running chanstat right now
    if ($STATE) {
        # Check if this is the target channel.
        if ($STATE eq $sServer.'::'.$sChannel) {
            # User is Away
            if ($sStatus =~ m/G/xsm) {
		        $iAwayUsers++;
            }
            # User is Here
            if ($sStatus =~ m/H/xsm) {
		        $iHereUsers++;
            }
            # User is Regged
            if ($sStatus =~ m/r/xsm) {
		        $iRegisteredUsers++;
            }
            # User is Bot
            if ($sStatus =~ m/B/xsm) {
		        $iBots++;
            }
            # User is IRC Operator
            if ($sStatus =~ m/\*/xsm) {
		        $iOpers++;
            }
            # User is Channel Owner
            if ($sStatus =~ m/\~/xsm) {
		        $iOwnerUsers++;
            }
            # User is Channel Admin
            if ($sStatus =~ m/\&/xsm) {
		        $iAdminUsers++;
            }
            # User is Channel Operator
            if ($sStatus =~ m/\@/xsm) {
		        $iOperatorUsers++;
            }
            # User is Half Operator
            if ($sStatus =~ m/\%/xsm) {
		        $iHalfOpUsers++;
            }
            # User is Voiced
            if ($sStatus =~ m/\+/xsm) {
		        $iVoiceUsers++;
            }
        }
    }

    return 1;
}

# Callback for end of WHO reply.
sub on_eow {
    if ($STATE) {
        my ($sServer, $sChannel) = split '::', $STATE, 2;
        my $iTotal = $iAwayUsers + $iHereUsers;


        if($sOption eq "count")
        {
            privmsg($sServer, $sChannel, "\002Channel Statistics for $sChannel\002");
            privmsg($sServer, $sChannel, "[\002Owners:\002 $iOwnerUsers] [\002Admins:\002 $iAdminUsers] [\002Ops:\002 $iOperatorUsers] [\002Halfops:\002 $iHalfOpUsers] [\002Voices:\002 $iVoiceUsers]");
            privmsg($sServer, $sChannel, "[\002Away:\002 $iAwayUsers] [\002Here:\002 $iHereUsers] [\002Bots:\002 $iBots]");
            privmsg($sServer, $sChannel, "[\002Registered Users:\002 $iRegisteredUsers] [\002IRC Operators:\002 $iOpers] [\002Total Users:\002 $iTotal]");
        }
        else
        {
            my ($iOwnerPercentage, $iAdminPercentage, $iOperatorPercentage, $iHalfOpPercentage, $iVoicePercentage, $iAwayPercentage, $iHerePercentage, $iBotPercentage, $iRegisteredPercentage, $iOpersPercentage);
            $iOwnerPercentage = $iOwnerUsers / $iTotal * 100;
            $iAdminPercentage = $iAdminUsers / $iTotal * 100;
            $iOperatorPercentage = $iOperatorUsers / $iTotal * 100;
            $iHalfOpPercentage = $iHalfOpUsers / $iTotal * 100;
            $iVoicePercentage = $iVoiceUsers / $iTotal * 100;
            $iAwayPercentage = $iAwayUsers / $iTotal * 100;
            $iHerePercentage = $iHereUsers / $iTotal * 100;
            $iBotPercentage = $iBots / $iTotal * 100;
            $iRegisteredPercentage = $iRegisteredUsers / $iTotal * 100;
            $iOpersPercentage = $iOpers / $iTotal * 100;

            privmsg($sServer, $sChannel, "\002Channel Statistics for $sChannel\002");
            privmsg($sServer, $sChannel, "[\002Owners:\002 ".int($iOwnerPercentage)."%] [\002Admins:\002 ".int($iAdminPercentage)."%] [\002Ops:\002 ".int($iOperatorPercentage)."%] [\002Halfops:\002 ".int($iHalfOpPercentage)."%] [\002Voices:\002 ".int($iVoicePercentage)."%]");
            privmsg($sServer, $sChannel, "[\002Away:\002 ".int($iAwayPercentage)."%] [\002Here:\002 ".int($iHerePercentage)."%] [\002Bots:\002 ".int($iBotPercentage)."%]");
            privmsg($sServer, $sChannel, "[\002Registered Users:\002 ".int($iRegisteredPercentage)."%] [\002IRC Operators:\002 ".int($iOpersPercentage)."%] [\002Total Users:\002 100%]");
        
        }
	    $iAwayUsers = 0;
	    $iHereUsers = 0;
	    $iRegisteredUsers = 0;
	    $iBots = 0;
	    $iOpers = 0;
        $iOwnerUsers = 0;
        $iAdminUsers = 0;
        $iOperatorUsers = 0;
        $iHalfOpUsers = 0;
        $iVoiceUsers = 0;
        undef($STATE);
        undef($sOption);
    }

    return 1;
}

# Start initialization.
API::Std::mod_init('ChanStat', 'RedStone Development Group', '1.00', '3.0.0a11');
# build: perl=5.010000

__END__

=head1 NAME

 ChanStat - Basic Channel Statistics.

=head1 VERSION

 1.00

=head1 SYNOPSIS

 <User> !chanstat percent  
 <RedStone> Channel Statistics for #somechannel
 <RedStone> [Owners: 8%] [Admins: 25%] [Ops: 16%] [Halfops: 8%] [Voices: 41%]
 <RedStone> [Away: 8%] [Here: 91%] [Bots: 58%]
 <RedStone> [Registered Users: 100%] [IRC Operators: 33%] [Total Users: 100%]

 <User> !chanstat count
 <RedStone> Channel Statistics for #somechannel
 <RedStone> [Owners: 1] [Admins: 3] [Ops: 2] [Halfops: 1] [Voices: 5]
 <RedStone> [Away: 1] [Here: 11] [Bots: 7]
 <RedStone> [Registered Users: 12] [IRC Operators: 4] [Total Users: 12]

=head1 DESCRIPTION

This creates the CHANSTAT command, which will count every user in the channel,
using the output of '/who' and show statistics in the format requested.

=head1 AUTHOR

This module was written by Russell M Bradford.

This module is maintained by RedStone Development Group.

=head1 LICENSE AND COPYRIGHT

This module is Copyright 2017 RedStone Development Group.
reserved.

This module is released under the same licensing terms as RedStone itself.

=cut

# vim: set ai et ts=4 sw=4:
