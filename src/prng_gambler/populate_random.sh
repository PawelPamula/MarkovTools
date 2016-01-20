#!/bin/bash


# make NSEQ random sequences
if [ -z "$NSEQ" ]; then
	NSEQ=4096
fi

# the sequences are BLEN bytes long
if [ -z "$BLEN" ]; then
	BLEN=65536
fi

mkdir -p seq

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
	IHEX=`echo "obase=16; $i" | bc`
	BLLEN=$(($BLEN/1024))

	FNAME="seq/urand_$i"
	dd if=/dev/urandom of=$FNAME count=$BLLEN bs=1KiB iflag=fullblock status=none
	FNAME="seq/openssl_$i"
	openssl rand -out $FNAME $BLEN
	FNAME="seq/rc4_$i"
	head -c $BLEN /dev/zero | openssl rc4 -out $FNAME -K $IHEX -iv $IHEX
	FNAME="seq/aes128ctr_$i"
	head -c $BLEN /dev/zero | openssl enc -aes-128-ctr -out $FNAME -K $IHEX -iv $IHEX
	FNAME="seq/aes192ctr_$i"
	head -c $BLEN /dev/zero | openssl enc -aes-192-ctr -out $FNAME -K $IHEX -iv $IHEX
	FNAME="seq/aes256ctr_$i"
	head -c $BLEN /dev/zero | openssl enc -aes-256-ctr -out $FNAME -K $IHEX -iv $IHEX
	FNAME="seq/crand_$i"
	./c_rand $BLEN $i > $FNAME
done
