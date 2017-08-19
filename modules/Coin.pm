# Module: Coin. See below for documentation.
# Copyright (C) 2017 RedStone Development Group.
# This program is free software; rights to this code are stated in doc/LICENSE.
package M::Coin;
use strict;
use warnings;
use API::Std qw(cmd_add cmd_del);
use API::IRC qw(privmsg);

# Initialization subroutine.
sub _init {
    # Create the COIN command.
    cmd_add('COIN', 0, 0, \%M::Coin::HELP_COIN, \&M::Coin::cmd_coin) or return;

    # Success.
    return 1;
}

# Void subroutine.
sub _void {
    # Delete the COIN command.
    cmd_del('COIN') or return;

    # Success.
    return 1;
}

# Help hash for COIN.
our %HELP_COIN = (
    en => "This command performs a coin toss. \2Syntax:\2 COIN",
);

# Callback for COIN command.
sub cmd_coin {
    my ($src, undef) = @_;

    # Set variables.
    my $sCoin;
    my $iRandom = int rand 10;
    
    # Get result.
    if ($iRandom =~ m/^(0|2|4|6|8)$/xsm) { $sCoin = 'heads' }
    elsif ($iRandom =~ m/^(1|3|5|7|9)$/xsm) { $sCoin = 'tails' }

    # Return result.
    privmsg($src->{svr}, $src->{chan}, "\2$src->{nick}\2 tosses a coin into the air...");
    privmsg($src->{svr}, $src->{chan}, "The coin lands, and it's... \2$sCoin\2.");

    return 1;
}

# Start initialization.
API::Std::mod_init('Coin', 'RedStone Development Group', '1.00', '3.0.0a11');
# build: perl=5.010000

__END__

=head1 NAME

 Coin - Coin tosser.

=head1 VERSION

 1.00

=head1 SYNOPSIS

 <User> !coin
 <RedStone> User tosses a coin into the air...
 <RedStone> The coin lands, and it's... heads.

=head1 DESCRIPTION

This merely flips a coin into the air and returns the result.

=head1 AUTHOR

This module was written by Elijah Perrault.

This module is maintained by RedStone Development Group.

=head1 LICENSE AND COPYRIGHT

This module is Copyright 2017 RedStone Development Group.
reserved.

This module is released under the same licensing terms as RedStone itself.

=cut

# vim: set ai et ts=4 sw=4:
