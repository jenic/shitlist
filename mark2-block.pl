#!/usr/bin/perl

use strict;
use warnings;
use constant _T => 5;

my @matches =	( 'lost conn.*AUTH'
		, 'NOQU'
		, 'reject'
		);

# Compile Regex
@matches = map qr/$_/, @matches;
my %ips =	map { my @r = split;chomp @r;$r[1] => {count=>$r[0],reason=>$r[2]} || '' }
		(qx'journalctl --since -6h -u postfix | grep from | \
		 perl -ne \'/\]:\s(.*?)\s[A-z0-9\.]+\[(.*?)\]/;$t=$1;$i=$2;$t=~s/\s/_/g;print "$t $i\n" if $t;\' | \
		 sort | uniq -c'
		);
my @shitlist;

IP:
while (my ($k, $v) = each %ips) {
	my %data = %$v;
	my $m = 0;
	for (@matches) {
		if( $data{reason} =~ /$_/) {
			$m = 1;
			last;
		}
	}
	next if (!$m);
	push @shitlist, $k
		if ($data{count} > _T);
}

print "@shitlist\n";
exit;
system 'shorewall', 'drop', @shitlist
	if (@shitlist);
