#!/usr/bin/perl

use strict;
use constant _T => 3;

my %ips =	map { my @r = split;chomp @r;$r[1] => $r[0] || '' }
		(qx'journalctl --since -3h -u sshd | grep Invalid | \
		 perl -ne \'/from\s(.*?)$/;print $1, "\n"\' | \
		 sort | uniq -c'
		);

my @shitlist;

while (my ($k, $v) = each %ips) {
	push @shitlist, $k
		if ($v > _T);
}

system 'shorewall', 'drop', @shitlist
	if (@shitlist);
