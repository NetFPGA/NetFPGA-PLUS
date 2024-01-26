from scapy.all import *

# create a TCP SYN packet with IP and Ethernet layers
packet = Ether()/IP(dst="192.168.1.250")/TCP(dport=80, flags="S")

# send the packet using the eth0 interface
sendp(packet, iface="nf0")
