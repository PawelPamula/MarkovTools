#!/bin/bash


# make NSEQ random sequences
if [ -z "$NSEQ" ]; then
	NSEQ=4096
fi

#
# Generate NSEQ random sequences from various sources:
# (the sequences have length of 16kB)
#
# seq_urand_N			: sequence from /dev/urandom
# seq_openssl_N			: sequence from openssl rand function
# seq_rc4_N				: sequence from RC4 with key and iv equal to N (interpreted as hex)
# seq_aes128ctr_N		: sequence from AES-128-CTR with ... (      ||      )
# seq_aes192ctr_N		: sequence from AES-192-CTR with ... (      ||      )
# seq_aes256ctr_N		: sequence from AES-256-CTR with ... (      ||      )
# seq_crand_N			: sequence of first bytes of C rand() function with seed N
# 

# gcc c_rand.c -o c_rand

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
	FNAME="seq_crand_$i"
	./c_rand 16384 $i > $FNAME
done
