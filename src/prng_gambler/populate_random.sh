#!/bin/bash

# make NSEQ random sequences
NSEQ=4096

for i in $(seq 1 $NSEQ); do 
	FNAME="seq_urand_$i"
	dd if=/dev/urandom of=$FNAME count=16 bs=1KiB iflag=fullblock
	FNAME="seq_openssl_$i"
	openssl rand -out $FNAME 16384
	FNAME="seq_rc4_$i"
	head -c 16384 /dev/zero | openssl rc4 -out $FNAME -K $i -iv $i
	FNAME="seq_aes128ctr_$i"
	head -c 16384 /dev/zero | openssl enc -aes-128-ctr -out $FNAME -K $i -iv $i
	FNAME="seq_aes192ctr_$i"
	head -c 16384 /dev/zero | openssl enc -aes-192-ctr -out $FNAME -K $i -iv $i
	FNAME="seq_aes256ctr_$i"
	head -c 16384 /dev/zero | openssl enc -aes-256-ctr -out $FNAME -K $i -iv $i
done
