# Module: DNS. See below for documentation.
# Copyright (C) 2017 RedStone Development Group.
# This program is free software; rights to this code are stated in doc/LICENSE.
package M::DNS;
use strict;
use warnings;
use API::Std qw(cmd_add cmd_del trans);
use API::IRC qw(privmsg notice);
use Net::DNS;

# Initialization subroutine.
sub _init {
    # Create the DNS command.
    cmd_add('DNS', 0, 0, \%M::DNS::HELP_DNS, \&M::DNS::cmd_dns) or return;

    # Success.
    return 1;
}

# Void subroutine.
sub _void {
    # Delete the DNS command.
    cmd_del('DNS') or return;

    # Success.
    return 1;
}

# Help hash.
our %HELP_DNS = (
    en => "This command will do a DNS lookup. \2Syntax:\2 DNS <host>",
);

# Callback for DNS command.
sub cmd_dns {
    my ($src, @argv) = @_;
     
    if (!defined $argv[0]) {
        notice($src->{svr}, $src->{nick}, trans('Not enough parameters').q{.});
        return;
    }

    # For humour purposes

    if($argv[0] eq "hell")
    {
	privmsg($src->{svr}, $src->{chan}, "Results for \2hell\2:");
	privmsg($src->{svr}, $src->{chan}, "IPv4 Results (1): 6.6.6.6");
	privmsg($src->{svr}, $src->{chan}, "TXT Results (1): \"You are going to hell!\"");
	return;
    }

    # Actual command

    if(!defined($argv[1])) {
        my $pResolver1 = Net::DNS::Resolver->new;
        my $pResolver2  = Net::DNS::Resolver->new;
        my $pResolver3 = Net::DNS::Resolver->new;
        my $pResolver4 = Net::DNS::Resolver->new;
        my $pResolver5 = Net::DNS::Resolver->new;
        my $pResolver6 = Net::DNS::Resolver->new;
        my $pResolver7 = Net::DNS::Resolver->new;
        my $pResolver8 = Net::DNS::Resolver->new;
        $pResolver1->force_v4(1);
        $pResolver2 ->force_v4(0);

        $pResolver1->tcp_timeout(3);
        $pResolver2 ->tcp_timeout(3);
        $pResolver3->tcp_timeout(3);
        $pResolver4->tcp_timeout(3);
        $pResolver5->tcp_timeout(3);
        $pResolver6->tcp_timeout(3);
        $pResolver7->tcp_timeout(3);
        $pResolver8->tcp_timeout(3);
        $pResolver8->udp_timeout(3);
        $pResolver7->udp_timeout(3);
        $pResolver6->udp_timeout(3);
        $pResolver5->udp_timeout(3);
        $pResolver4->udp_timeout(3);
        $pResolver3->udp_timeout(3);
        $pResolver2 ->udp_timeout(3);
        $pResolver1->udp_timeout(3);


        my $hQuery1 = $pResolver1->search($argv[0],'A');
        my $hQuery2 = $pResolver2 ->search($argv[0],'AAAA');
        my $hQuery3 = $pResolver3->search($argv[0]);
        my $hQuery4 = $pResolver4->search($argv[0],'MX');
        my $hQuery5 = $pResolver5->search($argv[0],'TXT');
        my $hQuery6 = $pResolver6->search($argv[0],'CNAME');
        my $hQuery7 = $pResolver7->search($argv[0],'NS');
        my $hQuery8 = $pResolver8->search($argv[0],'SRV');
        my @aResult1;
        my @aResult2;
        my @aResult3;
        my @aResult4;
        my @aResult5;
        my @aResult6;
        my @aResult7;
        my @aResult8;

        if ($hQuery6) {
            foreach my $hResult6 ($hQuery6->answer) {
                next if $hResult6->type ne 'CNAME';
                push(@aResult6, $hResult6->rdatastr);
            }
        }

        if ($hQuery1) {
            foreach my $hResult1 ($hQuery1->answer) {
                next if $hResult1->type ne 'A';
                push(@aResult1, $hResult1->address);
            }
        }

        if ($hQuery2) {
            foreach my $hResult2 ($hQuery2->answer) {
                next if $hResult2->type ne 'AAAA';
                push(@aResult2, $hResult2->address);
            }
        }

        if ($hQuery3) {
            foreach my $hResult3 ($hQuery3->answer) {
                next if $hResult3->type ne 'PTR';
                push(@aResult3, $hResult3->rdatastr);
            }
        }

        if ($hQuery4) {
            foreach my $hResult4 ($hQuery4->answer) {
                next if $hResult4->type ne 'MX';
	            my @aMXRecord = split(" ", $hResult4->rdatastr);
                push(@aResult4, $aMXRecord[1]." [Priority: ".$aMXRecord[0]."]");
            }
        }

        if ($hQuery5) {
            foreach my $hResult5 ($hQuery5->answer) {
                next if $hResult5->type ne 'TXT';
                push(@aResult5, $hResult5->rdatastr);
            }
        }

        if ($hQuery7) {
            foreach my $hResult7 ($hQuery7->answer) {
                next if $hResult7->type ne 'NS';
                push(@aResult7, $hResult7->rdatastr);
            }
        }

        if ($hQuery8) {
            foreach my $hResult8 ($hQuery8->answer) {
                next if $hResult8->type ne 'SRV';
                push(@aResult8, $hResult8->rdatastr);
            }
        }


        if(scalar(@aResult1) == 0 && scalar(@aResult2)  == 0 && scalar(@aResult3)  == 0 && scalar(@aResult4)  == 0 && scalar(@aResult5)  == 0 && scalar(@aResult6) == 0 && scalar(@aResult7)  == 0 && scalar(@aResult8)  == 0) {
    	    privmsg($src->{svr}, $src->{chan}, "No results found for \2$argv[0]\2.");
            return;
        }
        else {

            if(scalar(@aResult1) > 50 || scalar(@aResult2) > 50 || scalar(@aResult3) > 50 || scalar(@aResult4) > 50 || scalar(@aResult5) > 50 || scalar(@aResult6) > 50 || scalar(@aResult7) > 50 || scalar(@aResult8) > 50) {
	            privmsg($src->{svr}, $src->{chan}, 'Too many results were returned..');
	            return;
            }


            privmsg($src->{svr}, $src->{chan}, "Results for \2$argv[0]\2:");

            if (@aResult6) {
	            my $sResult = join ' ', @aResult6;
	            privmsg($src->{svr}, $src->{chan}, "\002$argv[0]\002 is aliased to \002$sResult\002");
            }
            if (@aResult1) {
	            my $sResult = join ' ', @aResult1;
	            privmsg($src->{svr}, $src->{chan}, "IPv4 Results (".scalar(@aResult1)."): ".$sResult);
            }
            if (@aResult2) {
                my $sResult = join ' ', @aResult2;
                privmsg($src->{svr}, $src->{chan}, "IPv6 Results (".scalar(@aResult2)."): ".$sResult);
            }
            if (@aResult4) {
                my $sResult = join ' :: ', @aResult4;
                privmsg($src->{svr}, $src->{chan}, "MX Results (".scalar(@aResult4)."): ".$sResult);
            }
            if (@aResult7) {
                my $sResult = join ' :: ', @aResult7;
                privmsg($src->{svr}, $src->{chan}, "NS Results (".scalar(@aResult7)."): ".$sResult);
            }
            if (@aResult8) {
                my $sResult = join ' :: ', @aResult8;
                privmsg($src->{svr}, $src->{chan}, "SRV Results (".scalar(@aResult8)."): ".$sResult);
            }
            if (@aResult5) {
                my $sResult = join ' :: ', @aResult5;
                privmsg($src->{svr}, $src->{chan}, "TXT Results (".scalar(@aResult5)."): ".$sResult);
            }
            if (@aResult3) {
                my $sResult = join ' ', @aResult3;
                privmsg($src->{svr}, $src->{chan}, "RDNS Results (".scalar(@aResult3)."): ".$sResult);
            }
        }
        return 1;
    }
    else {
        if(uc($argv[0]) eq 'A') {  
            my $pResolver1 = Net::DNS::Resolver->new;
            $pResolver1->tcp_timeout(3);
            $pResolver1->udp_timeout(3);
            my $hQuery1 = $pResolver1->search($argv[1],'A');
            $pResolver1->force_v4(1);
            my @aResult1;

            if ($hQuery1) {
                foreach my $hResult1 ($hQuery1->answer) {
                    next if $hResult1->type ne 'A';
                    push(@aResult1, $hResult1->address);
                }
            }

            if(scalar(@aResult1) == 0) {
    	        privmsg($src->{svr}, $src->{chan}, "No IPv4 results found for \2$argv[1]\2.");
                return;
            }

    	    if(scalar(@aResult1) > 50) {
        	    privmsg($src->{svr}, $src->{chan}, 'Too many results were returned..');
        	    return;
    	    }

        	my $sResult = join ' ', @aResult1;
    	    privmsg($src->{svr}, $src->{chan}, "Results for \2$argv[1]\2:");
    	    privmsg($src->{svr}, $src->{chan}, "IPv4 Results (".scalar(@aResult1)."): ".$sResult);

        }
        elsif(uc($argv[0]) eq 'AAAA') {  
            my $pResolver1 = Net::DNS::Resolver->new;
            $pResolver1->tcp_timeout(3);
            $pResolver1->udp_timeout(3);
            my $hQuery1 = $pResolver1->search($argv[1],'AAAA');
            $pResolver1->force_v4(0);
            my @aResult1;

            if ($hQuery1) {
                foreach my $hResult1 ($hQuery1->answer) {
                    next if $hResult1->type ne 'AAAA';
                    push(@aResult1, $hResult1->address);
                }
            }

            if(scalar(@aResult1) == 0) {
    	        privmsg($src->{svr}, $src->{chan}, "No IPv6 results found for \2$argv[1]\2.");
                return;
            }

    	    if(scalar(@aResult1) > 50) {
        	    privmsg($src->{svr}, $src->{chan}, 'Too many results were returned..');
        	    return;
    	    }

    	    my $sResult = join ' ', @aResult1;
    	    privmsg($src->{svr}, $src->{chan}, "Results for \2$argv[1]\2:");
    	    privmsg($src->{svr}, $src->{chan}, "IPv6 Results (".scalar(@aResult1)."): ".$sResult);
        }
        elsif(uc($argv[0]) eq 'MX') {  
            my $pResolver1 = Net::DNS::Resolver->new;
            $pResolver1->tcp_timeout(3);
            $pResolver1->udp_timeout(3);
            my $hQuery1 = $pResolver1->search($argv[1],'MX');
            my @aResult1;

            if ($hQuery1) {
                foreach my $hResult1 ($hQuery1->answer) {
                    next if $hResult1->type ne 'MX';
	                my @aMXRecord = split(" ", $hResult1->rdatastr);
                    push(@aResult1, $aMXRecord[1]." [Priority: ".$aMXRecord[0]."]");
                }
            }

            if(scalar(@aResult1) == 0) {
    	        privmsg($src->{svr}, $src->{chan}, "No mail results found for \2$argv[1]\2.");
                return;
            }

    	    if(scalar(@aResult1) > 50) {
        	    privmsg($src->{svr}, $src->{chan}, 'Too many results were returned..');
        	    return;
    	    }

    	    my $sResult = join ' ', @aResult1;
    	    privmsg($src->{svr}, $src->{chan}, "Results for \2$argv[1]\2:");
    	    privmsg($src->{svr}, $src->{chan}, "MX Results (".scalar(@aResult1)."): ".$sResult);
        }
        elsif(uc($argv[0]) eq 'TXT') {  
            my $pResolver1 = Net::DNS::Resolver->new;
            $pResolver1->tcp_timeout(3);
            $pResolver1->udp_timeout(3);
            my $hQuery1 = $pResolver1->search($argv[1],'TXT');
            my @aResult1;

            if ($hQuery1) {
                foreach my $hResult1 ($hQuery1->answer) {
                    next if $hResult1->type ne 'TXT';
                    push(@aResult1, $hResult1->rdatastr);
                }
            }

            if(scalar(@aResult1) == 0) {
    	        privmsg($src->{svr}, $src->{chan}, "No text results found for \2$argv[1]\2.");
                return;
            }

    	    if(scalar(@aResult1) > 50) {
        	    privmsg($src->{svr}, $src->{chan}, 'Too many results were returned..');
        	    return;
    	    }

        	my $sResult = join ' ', @aResult1;
    	    privmsg($src->{svr}, $src->{chan}, "Results for \2$argv[1]\2:");
    	    privmsg($src->{svr}, $src->{chan}, "TXT Results (".scalar(@aResult1)."): ".$sResult);


        }
        elsif(uc($argv[0]) eq 'NS') {  
            my $pResolver1 = Net::DNS::Resolver->new;
            $pResolver1->tcp_timeout(3);
            $pResolver1->udp_timeout(3);
            my $hQuery1 = $pResolver1->search($argv[1],'NS');
            my @aResult1;

            if ($hQuery1) {
                foreach my $hResult1 ($hQuery1->answer) {
                    next if $hResult1->type ne 'NS';
                    push(@aResult1, $hResult1->rdatastr);
                }
            }

            if(scalar(@aResult1) == 0) {
    	        privmsg($src->{svr}, $src->{chan}, "No nameserver results found for \2$argv[1]\2.");
                return;
            }

    	    if(scalar(@aResult1) > 50) {
        	    privmsg($src->{svr}, $src->{chan}, 'Too many results were returned..');
        	    return;
    	    }

    	    my $sResult = join ' ', @aResult1;
    	    privmsg($src->{svr}, $src->{chan}, "Results for \2$argv[1]\2:");
    	    privmsg($src->{svr}, $src->{chan}, "NS Results (".scalar(@aResult1)."): ".$sResult);
        }
        elsif(uc($argv[0]) eq 'SRV') {  
            my $pResolver1 = Net::DNS::Resolver->new;
            $pResolver1->tcp_timeout(3);
            $pResolver1->udp_timeout(3);
            my $hQuery1 = $pResolver1->search($argv[1],'SRV');
            my @aResult1;

            if ($hQuery1) {
                foreach my $hResult1 ($hQuery1->answer) {
                    next if $hResult1->type ne 'SRV';
	                my @srv = split(" ", $hResult1->rdatastr);
                    push(@aResult1, $srv[3]." [Priority: ".$srv[0]." :: Weight: ".$srv[1]." :: Port: ".$srv[2]."]");
                }
            }

            if(scalar(@aResult1) == 0) {
    	        privmsg($src->{svr}, $src->{chan}, "No SRV results found for \2$argv[1]\2.");
                return;
            }

    	    if(scalar(@aResult1) > 50) {
        	    privmsg($src->{svr}, $src->{chan}, 'Too many results were returned..');
        	    return;
    	    }

    	    my $sResult = join ' ', @aResult1;
    	    privmsg($src->{svr}, $src->{chan}, "Results for \2$argv[1]\2:");
    	    privmsg($src->{svr}, $src->{chan}, "SRV Results (".scalar(@aResult1)."): ".$sResult);
        }
        elsif(uc($argv[0]) eq 'CNAME') {  
            my $pResolver1 = Net::DNS::Resolver->new;
            $pResolver1->tcp_timeout(3);
            $pResolver1->udp_timeout(3);
            my $hQuery1 = $pResolver1->search($argv[1],'CNAME');
            my @aResult1;

            if ($hQuery1) {
                foreach my $hResult1 ($hQuery1->answer) {
                    next if $hResult1->type ne 'CNAME';
                    push(@aResult1, $hResult1->rdatastr);
                }
            }

            if(scalar(@aResult1) == 0) {
    	        privmsg($src->{svr}, $src->{chan}, "No alias results found for \2$argv[1]\2.");
                return;
            }

    	    if(scalar(@aResult1) > 50) {
        	    privmsg($src->{svr}, $src->{chan}, 'Too many results were returned..');
        	    return;
    	    }

    	    my $sResult = join ' ', @aResult1;
    	    privmsg($src->{svr}, $src->{chan}, "Results for \2$argv[1]\2:");
    	    privmsg($src->{svr}, $src->{chan}, "\002$argv[1]\002 is aliased to \002$sResult\002");

        }
        elsif(uc($argv[0]) eq 'PTR')  {  
            my $pResolver1 = Net::DNS::Resolver->new;
            $pResolver1->tcp_timeout(3);
            $pResolver1->udp_timeout(3);
            my $hQuery1 = $pResolver1->search($argv[1],'PTR');
            my @aResult1;

            if ($hQuery1) {
                foreach my $hResult1 ($hQuery1->answer) {
                    next if $hResult1->type ne 'PTR';
                    push(@aResult1, $hResult1->rdatastr);
                }
            }

            if(scalar(@aResult1) == 0) {
    	        privmsg($src->{svr}, $src->{chan}, "No reverse results found for \2$argv[1]\2.");
                return;
            }

    	    if(scalar(@aResult1) > 50) {
        	    privmsg($src->{svr}, $src->{chan}, 'Too many results were returned..');
        	    return;
    	    }

    	    my $sResult = join ' ', @aResult1;
    	    privmsg($src->{svr}, $src->{chan}, "Results for \2$argv[1]\2:");
    	    privmsg($src->{svr}, $src->{chan}, "RDNS Results (".scalar(@aResult1)."): ".$sResult);

        }
    }
    return 1;
}

# Start initialization.
API::Std::mod_init('DNS', 'RedStone Development Group', '1.00', '3.0.0a11');
# build: cpan=Net::DNS perl=5.010000

__END__

=head1 NAME

DNS - Net::DNS interface.

=head1 VERSION

 1.00

=head1 SYNOPSIS

 <User> !dns ipv6test.com
 <RedStone> Results for ipv6test.com:
 <RedStone> IPv4 Results (6): 209.85.203.99 209.85.203.147 209.85.203.106 209.85.203.105 209.85.203.103 209.85.203.104
 <RedStone> IPv6 Results (1): 2a00:1450:400b:c03:0:0:0:63
 <RedStone> NS Results (4): ns1.ipv6test.com. :: ns3.ipv6test.com. :: ns4.ipv6test.com. :: ns2.ipv6test.com.
 <RedStone> TXT Results (1): "v=spf1 ?all"

 <User> !dns A google.com
 <RedStone> Results for google.com:
 <RedStone> IPv4 Results (6): 209.85.203.113 209.85.203.101 209.85.203.139 209.85.203.138 209.85.203.102 209.85.203.100

=head1 DESCRIPTION

This module creates the DNS command for performing DNS
lookups.

=head1 DEPENDENCIES

This module depends on the following CPAN modules:

=over

=item L<Net::DNS>

This is the DNS agent this module uses.

=back

=head1 AUTHOR

This module was written by Russell Bradford.

This module is maintained by RedStone Development Group.

=head1 LICENSE AND COPYRIGHT

This module is Copyright 2017 RedStone Development Group.

Released under the same licensing terms as RedStone itself.

=cut

# vim: set ai et sw=4 ts=4:
