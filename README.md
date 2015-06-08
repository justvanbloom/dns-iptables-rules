dns-iptables-rules
==================

DNS Amplification IPTABLES block lists and Rules against DNS Attacks

Install:
1. cd /opt && mkdir dns-iptables-rules
2. copy all there
3. add crontab 
   0 0 * * * /bin/sh /opt/dns-iptables-rules/update_domain_blacklist.sh

