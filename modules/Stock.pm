# Module: Eval. See below for documentation.
# Copyright (C) 2014 Russell M Bradford
# This program is free software; rights to this code are stated in doc/LICENSE.
package M::Stock;
use strict;
use warnings;
use English qw(-no_match_vars);
use API::Std qw(cmd_add cmd_del trans conf_get);
use API::IRC qw(privmsg notice);
use API::Log qw(slog dbug alog);
use JSON::Any;
use JSON;
use TryCatch;

sub _init {
    cmd_add('STOCK', 2, 0, \%M::Stock::HELP_STOCK, \&M::Stock::cmd_stock) or return;

    return 1;
}

sub _void {
    cmd_del('STOCK') or return;

    return 1;
}

# Help hash for EVAL command. Spanish and French translations are needed.
our %HELP_STOCK = (
    en => "This command allows you to retrieve a share or stock price from the market. \2Syntax:\2 STOCK <Market Symbol>"
);

# Callback for EVAL command.
sub cmd_stock {
    my ($src, @argv) = @_;

    # Check for needed parameter.
    if (!defined $argv[0]) {
        notice($src->{svr}, $src->{nick}, trans('Not enough parameters').q{.});
        return;
    }
    
    my $sQuery = "select * from yahoo.finance.quote where symbol in (\"".$argv[0]."\")";
    my $sStockURL = "http://query.yahooapis.com/v1/public/yql?format=json&env=store%3A%2F%2Fdatatables.org%2Falltableswithkeys&q=".$sQuery;

    $Auto::http->request(
        url => $sStockURL,
        on_response => sub {
            my $hResponse = shift;

            if(!$hResponse->is_success)
            {
                privmsg($src->{svr}, $src->{target}, "Stock information could not be retrieved. Try again later");
                return 1;
            }

			my $hJsonData = $hResponse->decoded_content;
			my $hJsonInfo = decode_json($hJsonData);

            if(!$hJsonInfo->{"query"}{"results"}{"quote"}{"Change"})
            {
                privmsg($src->{svr}, $src->{target}, "The market symbol you have specified does not exist.");
                return 1;
            }

            my $iColor;

            if($hJsonInfo->{"query"}{"results"}{"quote"}{"Change"} > 0)
            {
                $iColor = "3";
            }
            else
            {
                $iColor = "5";
            }

	        my $iPercentChange;

	        try
            {
	      	    eval { $iPercentChange = 100 * $hJsonInfo->{"query"}{"results"}{"quote"}{"Change"} / ($hJsonInfo->{"query"}{"results"}{"quote"}{"LastTradePriceOnly"} - $hJsonInfo->{"query"}{"results"}{"quote"}{"Change"}); };
            	$iPercentChange = sprintf("%.2f", $iPercentChange);
	        }
	        catch
            {
		        $iPercentChange = "Unknown";
            }

            privmsg($src->{svr}, $src->{target}, "Stock Information for \002".$hJsonInfo->{"query"}{"results"}{"quote"}{"Name"}." (".$hJsonInfo->{"query"}{"results"}{"quote"}{"symbol"}.")");
            privmsg($src->{svr}, $src->{target}, "\x0312Last Trade Price:\x0f ".$hJsonInfo->{"query"}{"results"}{"quote"}{"LastTradePriceOnly"}." :: \x0312Change:\x0f \x030$iColor".$hJsonInfo->{"query"}{"results"}{"quote"}{"Change"}." (".$iPercentChange."%)\x0f");
            privmsg($src->{svr}, $src->{target}, "\x0312Market Capital:\x0f ".$hJsonInfo->{"query"}{"results"}{"quote"}{"MarketCapitalization"}." :: \x0312Days Range:\x0f ".$hJsonInfo->{"query"}{"results"}{"quote"}{"DaysRange"}."");
            privmsg($src->{svr}, $src->{target}, "\x0312Day High/Low:\x0f ".$hJsonInfo->{"query"}{"results"}{"quote"}{"DaysHigh"}."/".$hJsonInfo->{"query"}{"results"}{"quote"}{"DaysLow"}." :: \x0312Years High/Low:\x0f ".$hJsonInfo->{"query"}{"results"}{"quote"}{"YearHigh"}."/".$hJsonInfo->{"query"}{"results"}{"quote"}{"YearLow"}."");

        },
        on_error => sub {
            my $sError = shift;
            privmsg($src->{svr}, $src->{target}, "An error occurred: $sError");
            return 1;
        }
    );

    return 1;
}


# Start initialization.
API::Std::mod_init('Stock', 'RedStone Development Group', '1.00', '3.0.0a11');
# build: cpan=JSON,JSON::Any,TryCatch perl=5.010000

__END__

=head1 NAME

Stock - Allows you to retrieve stock information about a given market symbol

=head1 VERSION

 1.02

=head1 SYNOPSIS

    <User> !stock JDW.L
    <RedStone> Stock Information for WETHERSPOON ( J.D.) PLC ORD 2P (JDW.L)
    <RedStone> Last Trade Price: 1053.00 :: Change: +1.00 (0.10%)
    <RedStone> Market Capital: 1.15B :: Days Range: 1049.00 - 1059.00
    <RedStone> Day High/Low: 1059.00/1049.00 :: Years High/Low: 1063.00/810.00

=head1 DESCRIPTION

This module adds the STOCK command which allows you to retrieve information from
the stock market about a given market symbol

This module is compatible with Auto v3.0.0a10+.

=head1 DEPENDENCIES

This module depends on the following CPAN modules:

=over

=item L<JSON>

This is used to parse JSON returned from the API.

=item L<JSON::Any>

This is used to parse JSON returned from the API.

=item L<TryCatch>

This is used to handle errors on calculating percentage.

=back

=head1 AUTHOR

This module was written by Russell M Bradford.

=head1 LICENSE AND COPYRIGHT

This module is Copyright 2017 RedStone Development Group.

This module is released under the same licensing terms as RedStone itself.

=cut

# vim: set ai et sw=4 ts=4:
