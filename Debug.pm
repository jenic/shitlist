package Debug;

use 5.018001;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Debug ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	msg
	break
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

our $VERSION = '0.01';
our $ENABLED = ($ENV{DEBUG}) ? 1 : 0;

sub msg {
    return unless $ENABLED;
    my ($msg) = @_;
    my ($s,$m,$h) = ( localtime(time) )[0,1,2,3,6];
    my $date = sprintf "%02d:%02d:%02d", $h, $m, $s;
    warn "$date $msg", "\n";
}

sub break {
	return unless $ENABLED;
	my $break = <STDIN>;
}

sub iterate {
	return unless $ENABLED;
	for (@_) {
		next unless ref;
		msg("$_:");
		for my $v ($_) {
			msg($v);
		}
	}
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 Debug

Debug - Perl extension for blah blah blah

=head1 SYNOPSIS

  use Debug;
  Debug::ENABLED = 1;
  debug("message goes here");

=head1 DESCRIPTION

Basic debugging framework since I got tired of pasting the debug subroutine
into all of my scripts. Prints to STDERR if and only if ENABLED variable is set
to true.

=head2 EXPORT

debug subroutine by default.
ENABLED variable optional.


=head1 SEE ALSO

Nothing to see here.

=head1 AUTHOR

Jenic Rycr, E<lt>jenic@wubwub.meE<gt>

=head1 COPYRIGHT AND LICENSE

Author claims no copyright to this work. No fucks given.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
