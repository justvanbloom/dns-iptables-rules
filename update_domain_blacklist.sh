#!/bin/sh
## Flexible updating of domain blacklist to prevent smurf && protect against dns aplification attacks
## scripty by JVB
## FIRST DEFINE VARIABLES

#IPCHAIN TO USE
IPCHAIN=dnsfilter

#Action to take when match is made DROP | REJECT | LOG | <CHAINNAME>
TARGET=DROP

#see if chain exists, if not initialize
if [ `iptables -L $IPCHAIN | wc -l` -lt 1 ]; then
    echo "adding chain $IPCHAIN"
    iptables -N $IPCHAIN
    iptables -I INPUT -p udp --dport 53 -j $IPCHAIN
fi

#backup Iptables


iptables-save > /tmp/iptables_rules_$(date +%Y%m%d_%H%M%S).txt

iptables -n -L $IPCHAIN > /tmp/iptables_old.txt
old_count=$(cat /tmp/iptables_old.txt | wc -l)
echo "Rules in $IPCHAIN before update: $(expr $old_count - 2)"

#FLUSH CHAIN
iptables -F $IPCHAIN

#Add default action
iptables -A $IPCHAIN -j RETURN

##Now for the rules  -- copied from domain-blacklist.txt

# get new rules from github, replace INPUT for IPCHAIN and DROP for TARGET and apply. 

curl -s -L https://raw.github.com/smurfmonitor/dns-iptables-rules/master/domain-blacklist.txt | while read line; 
	do RULE=$(echo "$line" | sed -e "s/INPUT/$IPCHAIN/" -e "s/-j DROP/-j $TARGET/"); 
		eval $RULE; 
	done

iptables -n -L $IPCHAIN > /tmp/iptables_new.txt
new_count=$(cat /tmp/iptables_new.txt | wc -l)
echo "Rules in $IPCHAIN after update: $(expr $new_count - 2)"

diff /tmp/iptables_old.txt /tmp/iptables_new.txt

rm /tmp/iptables_new.txt /tmp/iptables_old.txt

##now for the sake add rate limit general
iptables -N udp-flood
iptables -A udp-flood -m limit --limit 4/second --limit-burst 4 -j RETURN
iptables -A udp-flood -j DROP
iptables -A INPUT -i eth0 -p udp -j udp-flood
iptables -A INPUT -i eth0 -f -j DROP

##rules against dns amply
iptables -N DNSAMPLY
iptables -A DNSAMPLY -p udp -m state --state NEW -m udp --dport 53 -j ACCEPT
iptables -A DNSAMPLY -p udp -m hashlimit --hashlimit-srcmask 24 --hashlimit-mode srcip --hashlimit-upto 30/m --hashlimit-burst 10 --hashlimit-name DNSTHROTTLE --dport 53 -j ACCEPT
iptables -A DNSAMPLY -p udp -m udp --dport 53 -j DROP
