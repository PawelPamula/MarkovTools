#!/bin/bash

# make NSEQ random sequences
NSEQ=1024

for i in $(seq 1 $NSEQ); do 
	FNAME="seq_urand_$i"
	dd if=/dev/urandom of=$FNAME count=16 bs=1KiB iflag=fullblock
	FNAME="seq_openssl_$i"
	openssl rand -out $FNAME 16384
done
