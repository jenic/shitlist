#!/bin/sh
export DEBUG=1 DRYRUN=1
#zcat ${@/#/testdata/} | ./mark2-block.pl 2>&1
zcat $@ | ./shitlist.pl 2>&1
