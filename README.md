# pcap_parser
Using Haskell to design a parser which is efficient in time and space.

The PCAP file has the general structure

(Global Header) | (Header1) | Data1 | (Header2) | Data2 | ... | (HeaderN) | DataN
(..) terms are added by libpcap/capture software,
while the other terms are the ACTUAL datum, captured on the wire.
The (Global Header) has a fixed size of 24 bytes, only inserted once.
some useful notes on this come from:
http://www.kroosec.com/2012/10/a-look-at-pcap-file-format.html
the first four (4) bytes d4 c3 b2 a1 specify a pcap file, called the `magic-number'.

The next 4 bytes 02 00 04 00 correspond to the version of the program, so V2.4 -> 02 00 04 00, the MAjor version being 2 bytes and the Minor version being 2 bytes.

here 2 is written on two bytes as 0x0200 and not 0x0002. This is due to little endianess in which the least-significant-byte is stored in the least significant position.

This means that 2 would be witten on two bytes as 02 00. This is distinguished from big-endianess by the `magic-number' 

the real value is 0xa1b2c3d4, where we have the reverse so that means we are working in little endianess (Little E).

then we have the GMT timezone ofset minus the timezone used in the headers in seconds (four bytes).
these are set to zero most of the time, which gives the (00 00 00 00 00 00 00 00).
Then the snapshot time which is set to (ff ff 00 00), this is the default value for tcpdumb and wireshark.

the lat 4 values 01 00 00 00 (0x1) which indicates that the link-layer protocol is ethernet.


so using the hexdump program from the linux shell, we can see the first 24 bytes;
'''
$ hexdump -n 24 -C mdf-kospi200.20110216-0.pcap | cut -c 11-59
d4 c3 b2 a1 02 00 04 00  00 00 00 00 00 00 00 00 
ff ff 00 00 01 00 00 00       
'''