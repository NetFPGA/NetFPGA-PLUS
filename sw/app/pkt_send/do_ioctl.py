#
# This is an attempt to do a simple register read/write in Python.
#
# Even though the ifr and sifr structures appear to be identical to
# the same structures in C, this does not work.
#
# Might consider using ctypes instead?

import socket
import fcntl
import array
import struct

NFDP_IOCTL_CMD_WRITE_REG = 35313
NFDP_IOCTL_CMD_READ_REG = 35314
IFR_SIZE = 40 # struct ifreq
NAMESIZE = 16 # max file name size

def rd_ioctl(ifname, addr):
    s = socket.socket(socket.AF_INET6, socket.SOCK_DGRAM)
    sifr = struct.pack('II',addr,0)
    print(f"Size of II object is {struct.calcsize('II')}")
    print("before call, sifr is 0x%0x 0x%0x " % (sifr[0], sifr[1]))

    sifr_addr = id(sifr)
    ifname16 = ifname + (chr(0) * (NAMESIZE -len(ifname)))
    print("sifr is at 0x%0x" % sifr_addr)

    # ifr = struct.pack('40s',ifname40.encode('UTF-8'))
    ifr = struct.pack('<16sQQQ',ifname16.encode('UTF-8'), sifr_addr, 0,0)

    print("Before call ifr is ",end='')
    for b in ifr: print("%02x " % b,end='')
    print('')

    r = fcntl.ioctl(s.fileno(), 
                   NFDP_IOCTL_CMD_READ_REG,
                   ifr)
    print(f"ioctl returned {r}\nAfter call ifr is ",end='')
    for b in ifr: print("%0x " % b,end='')
    print('')
    print("after call, sifr is 0x%0x 0x%0x" % (sifr[0], sifr[1]))
    return sifr

#get_ip_address('nf0') 

# for a in [0x0, 0x10000, 0x20000, 0x30000, 0x40000]:
for a in [0x10000]:
    sifr = rd_ioctl('nf0', a)
    print("IOCTL to addr 0x%0x returned 0x%0x" % (a, sifr[1]))

