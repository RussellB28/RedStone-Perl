# Module: Eval. See below for documentation.
# Copyright (C) 2017 RedStone Development Group.
# This program is free software; rights to this code are stated in doc/LICENSE.
package M::Eval;
use strict;
use warnings;
use English qw(-no_match_vars);
use API::Std qw(cmd_add cmd_del trans conf_get);
use API::IRC qw(privmsg notice);

# Initialization subroutine.
sub _init {
    # Create the EVAL command.
    cmd_add('EVAL', 2, 'cmd.eval', \%M::Eval::HELP_EVAL, \&M::Eval::cmd_eval) or return;

    # Success.
    return 1;
}

# Void subroutine.
sub _void {
    # Delete the EVAL command.
    cmd_del('EVAL') or return;

    # Success.
    return 1;
}

# Help hash for EVAL command. Spanish and French translations are needed.
our %HELP_EVAL = (
    en => "This command allows you to eval Perl code. USE WITH CAUTION. \2Syntax:\2 EVAL <expression>",
    de => "Dieser Befehl ermoeglicht du auf bewertst Perl Code. GEBRAUCH MIT VORSICHT. \2Syntax:\2 EVAL <expression>",
    fr => "Cette commande vous permet d'évaluer du code Perl. UTILISER AVEC PRUDENCE. \2Syntaxe:\2 EVAL <expression>",
);

# Callback for EVAL command.
sub cmd_eval {
    my ($src, @argv) = @_;

    # Check for needed parameter.
    if (!defined $argv[0]) {
        notice($src->{svr}, $src->{nick}, trans('Not enough parameters').q{.});
        return;
    }

    # Evaluate the expression and return the result.
    my $sExpression = join ' ', @argv;
    my $sSource = exists $src->{chan} ? $src->{chan} : $src->{nick};
    my $sResult = do {
        local $SIG{__WARN__} = sub {
            my $sMessage = shift;
            chomp $sMessage; privmsg($src->{svr}, $sSource, 'Warning: '.$sMessage);
        };
        local $SIG{__DIE__}  = sub {
            my $sMessage = shift;
            chomp $sMessage;
            privmsg($src->{svr}, $sSource, 'Error: '.$sMessage)
        };
        eval $sExpression;
    };

    if (!defined $sResult) { $sResult = 'None' }

    # Return the result.
    my @aLines = split("\n", $sResult);
    my $iLines = 0;
    my $sResultMessage = 'Unexpected error.';
    my $iMaxLines = (conf_get('eval_maxlines') ? (conf_get('eval_maxlines'))[0][0] : 5);
    my $sTarget = (defined $src->{chan} ? $src->{chan} : $src->{nick});

    foreach (@aLines) {
        $iLines++;
        if ($iLines > $iMaxLines) { 
            $sResultMessage = 'Reached maximum number of lines. Giving up.';
            privmsg($src->{svr}, $sTarget, $sResultMessage);
            last;
        }
        $sResultMessage = (defined $src->{chan} ? "$src->{nick}: $_" : "Output: $_");
        privmsg($src->{svr}, $sTarget, $sResultMessage);
    }

    return 1;
}


# Start initialization.
API::Std::mod_init('Eval', 'RedStone Development Group', '1.00', '3.0.0a11');
# build: perl=5.010000

__END__

=head1 NAME

Eval - Allows you to evaluate Perl code from IRC

=head1 VERSION

 1.00

=head1 SYNOPSIS

 <User> eval 1;
 <RedStone> Output: 1

=head1 DESCRIPTION

This module adds the EVAL command which allows you to evaluate Perl code from
IRC, returning the output via notice.

This command requires the cmd.eval privilege.

This module is compatible with RedStone v3.0.0a10+.

=head1 AUTHOR

This module was written by Elijah Perrault.

This module is maintained by RedStone Development Group.

=head1 LICENSE AND COPYRIGHT

This module is Copyright 2017 RedStone Development Group.

This module is released under the same licensing terms as RedStone itself.

=cut

# vim: set ai et sw=4 ts=4:
