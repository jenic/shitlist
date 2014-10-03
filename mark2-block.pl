#!/usr/bin/perl

use strict;
require "Debug.pm";
#$Debug::ENABLED = 1;
#use Data::Dumper;

use constant {
	_DEFS	=> 'conditions',
	_TYPES	=> 'types',
};

# Subroutine Declarations
sub slurp;
sub getDefs;

# Globals
my %ip;
my %matches = %{&getDefs(_DEFS)};
my %type = %{&getDefs(_TYPES)};
my @shitlist;
chomp(my $me = `dig +short jenic.wubwub.me`);

# Read input
while (<STDIN>) {
	my ($IP, $string, $type);
	while (my ($k, $v) = each %type) {
		my @m = ($_ =~ $v->[0]);
		if (@m > 2) {
			Debug::msg("More than 2 groups?! (@m)");
			next;
		} elsif (!@m) {
			next;
		}
		Debug::msg("$_ identified as $k");
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

#system 'shorewall', 'drop', @shitlist
#	if (@shitlist);

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
	Debug::msg("[getTypes] @raw");
	my %types =	map { $_->[0] => [ $_->[1], $_->[2] ] }
			map { [ split ] }
			@raw;
	return \%types;
}
