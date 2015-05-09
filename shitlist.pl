#!/usr/bin/perl

use strict;
use warnings;
#use 5.012;
use Getopt::Long;
use Pod::Usage;
require "Debug.pm";
#use Data::Dumper;

# Subroutine Declarations
sub slurp;
sub getDefs;

# Config
my ($types, $defs) =
( 'types'
, 'conditions'
);
my ($help, $man, $ident);

GetOptions
( 'types=s' => \$types
, 'defs=s' => \$defs
, 'identify' => \$ident
, 'help|?' => \$help
, 'man' => \$man
) or pod2usage(2);

pod2usage(1) if $help;
pod2usage(-exitval => 0, -verbose => 2) if $man;

# Globals
my %ip;
my %matches = %{&getDefs($defs)};
my %cata = %{&getDefs($types)};
my @shitlist;
chomp(my $me = `dig +short jenic.wubwub.me`);

# Read input
while (<STDIN>) {
    chomp();
    my ($IP, $string, $type);
    Debug::msg("Looping $_");
    # Reset each() iterator by calling keys() in void context
    # Need this because loop control statements are not seen by each()'s
    # internal iterator. This causes elements in %cata to be skipped on some
    # lines unless in debug mode, driving the maintainer to quantum madness.
    # See: http://perldoc.perl.org/functions/keys.html and
    # http://perldoc.perl.org/functions/each.html
    keys %cata;
    while (my ($k, $v) = each %cata) {
        Debug::msg("\t$v->[0]");
        my @m = ($_ =~ $v->[0]);
        if (@m > 2) {
            Debug::msg("More than 2 groups?! (@m)");
            next;
        } elsif (!@m) {
            next;
        }
        # Still here if we matched 1 or 2 things
        # Goes without saying, line categorizes as first match
        Debug::msg("$_ identified as $k : @m");
        $type = $k;
        # Third field of types defines k,v order
        if ($v->[1]) {
            ($IP, $string) = @m;
            Debug::msg("Order is key, value");
        } else {
            ($string, $IP) = @m;
            Debug::msg("Order is value, key");
        }
        # Spaces complicate things
        $string =~ s/\s+/_/g;
        last;
    }

    # Did we ever match?
    next unless ($type);

    # This exact record (IP=>Type=>Event) already exists. Increment its
    # "seen" counter and continue
    if (exists $ip{$IP} && exists $ip{$IP}->{$type}->{$string}) {
        $ip{$IP}->{$type}->{$string}++;
        next;
    } else {
        # We failed the first check but we do have a record for this
        # IP. Create the event record as an anonymous hash while
        # incrementing its seen counter
        if (exists $ip{$IP}) {
            $ip{$IP}->{$type}->{$string}++;
        # This record has never been seen, initalize structure and set
        # seen to 1.
        } else {
            $ip{$IP} = { $type => { $string => 1 } }
                # Sometimes IPs aren't IPs
                # Silly postfix.
                unless ($IP =~ /^[A-z]+$/);
        }
    }
}

# Apply conditions to known log events
Debug::msg("== Applying conditions to stored events == ");
IP:
while (my ($K, $V) = each %ip) {
    Debug::msg(sprintf "Evaluating $K, has %i types", scalar keys %$V);
    if ($K eq $me) {
        Debug::msg("$K is me ($me), skipping");
        next;
    }

    # Iterate through log types within IP record
    while (my ($k, $v) = each %$V) {
        Debug::msg(
            sprintf "%i \"%s\" type events within %s",
            scalar keys %$v,
            $k, $K
        );
        # Matches known conditions?
        #warn Dumper(%matches);
        keys %matches; # Reset each() iterator, see above for desc

        while (my ($rx, $d) = each %matches) {
            next unless ($d->[0] eq $k);

            while ( my ($event, $count) = each %$v) {
                Debug::msg(
                    "$event ~ $rx && $count >= $d->[1]"
                );
                if ($event =~ /$rx/ && $count >= $d->[1]) {
                    Debug::msg("$k -> $event matches & is >= $d->[1]");
                    Debug::msg("Adding $K to shitlist");
                    push @shitlist, $K;
                    next IP;
                }
            }
        }
    }
}

Debug::msg(sprintf "Have %i: %s\n", scalar @shitlist, "@shitlist");
#Debug::msg(Dumper(%ip));

system 'shorewall', 'drop', @shitlist
    if (!$ENV{DRYRUN} && @shitlist);

# Subroutines
sub slurp {
    my $file = shift;
    return -1 unless -e $file;
    open FH, $file
        or die "Couldn't open $file: $!\n";
    my @lines = <FH>;
    close FH;
    @lines  = grep { !/^(#|;|$)/ } @lines;
    chomp @lines;

    return \@lines;
}

sub getDefs {
    my $file = shift;
    my @raw = @{&slurp($file)};
    Debug::msg("[getDefs] @raw");
    my %types = map { $_->[0] => [ $_->[1], $_->[2] ] }
            map { [ split ] }
            @raw;
    return \%types;
}

__END__

=head1 shitlist

Perl Shitlist detection using Shorewall and regex definitions.

=head1 SYNOPSIS

journalctl --since=today | ./shitlist
OR 
./shitlist < /var/log/messages

=head1 OPTIONS

=over 8

=item B<-help>

Print a brief help message and exit

=item B<-man>

Prints the manual page and exits

=item B<-identify>

Reports lines that could not be identified with the given type regex file

=item B<-types>

Specify a file to read type definitions from. Defaults to 'types'

=item B<-defs>

Specify a file to read condition definitions from. Defaults to 'conditions'

=back

=head1 DESCRIPTION

B<shitlist> is a fail2ban inspired project to detect IPs that should be banned
with shorewall based on regex definitions and log files given over STDIN.
