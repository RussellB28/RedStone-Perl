# Module: SASLAuth. See below for documentation.
# Copyright (C) 2017 RedStone Development Group.
# This program is free software; rights to this code are stated in doc/LICENSE.
package M::SASLAuth;
use strict;
use warnings;
use feature qw(switch);
use MIME::Base64;
use API::Std qw(hook_add hook_del rchook_add rchook_del conf_get err awarn timer_add timer_del);
use API::IRC qw(privmsg);


# Initialization subroutine.
sub _init {
    # Check if this Auto was built with SASL support.
    if ($Auto::ENFEAT !~ m/sasl/xsm) { err(2, 'Auto was not built with SASL support. Aborting SASLAuth.', 0) and return }
    # Add sasl to supported CAP for servers configured with SASL.
    my %hServers = conf_get('server');
    foreach my $sServer (keys %hServers) {
        if (conf_get("server:$sServer:sasl_username") and conf_get("server:$sServer:sasl_password") and conf_get("server:$sServer:sasl_timeout")) { $Proto::IRC::cap{$sServer} .= ' sasl' }
    }
    # Hook for when CAP ACK sasl is received.
    hook_add('on_capack', 'sasl.cap', \&M::SASLAuth::handle_capack) or return;
    # Hook for parsing 903.
    rchook_add('903', 'sasl.903', \&M::SASLAuth::handle_903) or return;
    # Hook for parsing 904.
    rchook_add('904', 'sasl.904', \&M::SASLAuth::handle_904) or return;
    # Hook for parsing 906.
    rchook_add('906', 'sasl.906', \&M::SASLAuth::handle_906) or return;
    # Hook for rehash.
    hook_add('on_rehash', 'sasl.rehash', \&M::SASLAuth::on_rehash) or return;
    return 1;
}

# Void subroutine.
sub _void {
    # Delete the hooks.
    hook_del('on_capack', 'sasl.cap') or return;
    rchook_del('903', 'sasl.903') or return;
    rchook_del('904', 'sasl.904') or return;
    rchook_del('906', 'sasl.906') or return;
    hook_del('on_rehash', 'sasl.rehash');
    return 1;
}

sub on_rehash {
    my %hServers = conf_get('server');
    foreach my $sServer (keys %hServers) {
        if (conf_get("server:$sServer:sasl_username") and conf_get("server:$sServer:sasl_password") and conf_get("server:$sServer:sasl_timeout")) {
            if ($Proto::IRC::cap{$sServer} !~ m/sasl/) {
                $Proto::IRC::cap{$sServer} .= ' sasl';
            }
        }
    }
}


sub handle_capack {
    my (($sServer, $sCapability)) = @_;
 
    if ($sCapability eq 'sasl') {
        Auto::socksnd($sServer, 'AUTHENTICATE PLAIN');
        timer_add('auth_timeout_'.$sServer, 1, (conf_get("server:$sServer:sasl_timeout"))[0][0], sub { Auto::socksnd($sServer, 'CAP END') });
    }
    
    return 1;
}

# Parse: AUTHENTICATE
sub handle_authenticate  {
    my ($sServer, @parv) = @_;
    my $sUsername = (conf_get("server:$sServer:sasl_username"))[0][0];
    my $sPassword = (conf_get("server:$sServer:sasl_password"))[0][0];
    my $sB64Hash = join( "\0", $sUsername, $sUsername, $sPassword );
    $sB64Hash = encode_base64( $sB64Hash, "" );

    if ( length $sB64Hash == 0 ) {
        Auto::socksnd($sServer, "AUTHENTICATE +");
        return;
    }
    else {
        while ( length $sB64Hash >= 400 ) {
            my $sAuthHash = substr( $sB64Hash, 0, 400, '' );
            Auto::socksnd($sServer, "AUTHENTICATE $sAuthHash");
        }
        if ( length $sB64Hash ) {
            Auto::socksnd($sServer, "AUTHENTICATE $sB64Hash");
        }
        else {
            Auto::socksnd($sServer, "AUTHENTICATE +");
        }
    }
    return 1;
}

# Parse: Numeric:903
# SASL authentication successful.
sub handle_903  { 
    my ($sServer, undef) = @_; 
    timer_add('cap_end_'.$sServer, 1, 2, sub { Auto::socksnd($sServer, 'CAP END') });
    timer_del('auth_timeout_'.$sServer);
}

# Parse: Numeric:904
# SASL authentication failed.
sub handle_904  { 
    my ($sServer, undef) = @_; 
    timer_add('cap_end_'.$sServer, 1, 2, sub { Auto::socksnd($sServer, 'CAP END') });
    timer_del('auth_timeout_'.$sServer);
    awarn(2, "SASL authentication failed!");
}

# Parse: Numeric:906
# SASL authentication aborted.
sub handle_906  {
    my ($sServer, undef) = @_;
    timer_add('cap_end_'.$sServer, 1, 2, sub { Auto::socksnd($sServer, 'CAP END') });
    timer_del('auth_timeout_'.$sServer);
    awarn(2, "SASL authentication aborted!");
}

# Start initialization.
API::Std::mod_init('SASLAuth', 'RedStone Development Group', '1.00', '3.0.0a11');
# build: perl=5.010000

__END__

=head1 SASLAuth

=head2 Description

=over

This module adds support for IRCv3 SASL authentication, a nicer way of authenticating
to services and/or the IRCd.

SASL is available in Charybdis IRCd's and InspIRCd 1.2+ with m_cap and m_sasl. Atheme
IRC Services also allows you to identify to NickServ/UserServ with SASL.

=back

=head2 How To Use

=over

To use SASLAuth, first add it to module auto-load then add the following to the server
block(s) you wish to use SASL with:

  sasl_username "services accountname";
  sasl_password "services password";
  sasl_timeout <timeout in seconds>;

=back

=head2 Examples

=over

  sasl_username "JohnBot";
  sasl_password "foobar12345";
  sasl_timeout 20;

=back

=head2 To Do

=over

* Add support for SASL mechanism DH-BLOWFISH.

=back

=head2 Technical

=over

This adds an extra dependency: You must build RedStone with the 
--enable-sasl option.

This module is compatible with RedStone v3.0.0a10+.

=back

# vim: set ai et sw=4 ts=4:
