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
mkdir -p seq/urand
mkdir -p seq/openssl
mkdir -p seq/rc4
mkdir -p seq/aes128ctr
mkdir -p seq/aes192ctr
mkdir -p seq/aes256ctr
mkdir -p seq/crand
mkdir -p seq/randu

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
# seq_randu_N			: sequence of first two bytes of RANDU function with seed N
# 

# gcc c_rand.c -o c_rand

for i in $(seq 1 $NSEQ); do 
	IHEX=`echo "obase=16; $i" | bc`
	BLLEN=$(($BLEN/1024))

	FNAME="seq/urand/$i"
	dd if=/dev/urandom of=$FNAME count=$BLLEN bs=1KiB iflag=fullblock status=none
	FNAME="seq/openssl/$i"
	openssl rand -out $FNAME $BLEN
	FNAME="seq/rc4/$i"
	head -c $BLEN /dev/zero | openssl rc4 -out $FNAME -K $IHEX
	FNAME="seq/aes128ctr/$i"
	head -c $BLEN /dev/zero | openssl enc -aes-128-ctr -out $FNAME -K $IHEX -iv $IHEX
	FNAME="seq/aes192ctr/$i"
	head -c $BLEN /dev/zero | openssl enc -aes-192-ctr -out $FNAME -K $IHEX -iv $IHEX
	FNAME="seq/aes256ctr/$i"
	head -c $BLEN /dev/zero | openssl enc -aes-256-ctr -out $FNAME -K $IHEX -iv $IHEX
	FNAME="seq/crand/$i"
	./c_rand $BLEN $i > $FNAME
	FNAME="seq/randu/$i"
	./randu $BLEN $i > $FNAME
done
