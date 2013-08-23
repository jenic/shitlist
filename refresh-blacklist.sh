#!/bin/sh
 
echo "#ADDRESS/SUBNET         PROTOCOL        PORT" > /tmp/blacklist
echo "# dshield.org blocks" >> /tmp/blacklist
wget  -q -O - http://feeds.dshield.org/block.txt | awk --posix '/^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.0\t/ { print $1 "/24";}' >> /tmp/blacklist
echo "# spamhaus.org blocks" >> /tmp/blacklist
wget -q -O - http://www.spamhaus.org/drop/drop.lasso | awk --posix '/^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\// { print $1;}' >> /tmp/blacklist
cat /etc/shorewall/shitlist >> /tmp/blacklist
mv /tmp/blacklist /etc/shorewall/blacklist
 
shorewall refresh &>/dev/null
