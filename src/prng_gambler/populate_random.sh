#!/bin/bash


# make NSEQ random sequences
if [ -z "$NSEQ" ]; then
	NSEQ=4096
fi

# the sequences are BLEN bytes long
if [ -z "$BLEN" ]; then
	BLEN=65536
fi

mkdir -p bin
mkdir -p seq/{N,R}
mkdir -p seq/{N,R}/urand
mkdir -p seq/{N,R}/openssl
mkdir -p seq/{N,R}/rc4
mkdir -p seq/{N,R}/spritz
mkdir -p seq/{N,R}/vmpc
mkdir -p seq/{N,R}/rc4p
mkdir -p seq/{N,R}/aes128ctr
mkdir -p seq/{N,R}/aes192ctr
mkdir -p seq/{N,R}/aes256ctr
mkdir -p seq/{N,R}/crand
mkdir -p seq/{N,R}/randu
mkdir -p seq/{N,R}/hc128
mkdir -p seq/{N,R}/rabbit
mkdir -p seq/{N,R}/trivium
mkdir -p seq/{N,R}/sosemanuk
mkdir -p seq/{N,R}/salsa20
mkdir -p seq/{N,R}/grain
mkdir -p seq/{N,R}/mickey

#
# Generate NSEQ random sequences from various sources:
# (the sequences have length of $BLEN, 64 KB by default)
#
# seq/N - the key/seed of each sequence is serial, i.e. 1, 2, 3, ... NSEQ
# seq/R - the key/seed of each sequence is psudorandom 
#
# seq/*/urand/*			: sequence from /dev/urandom
# seq/*/openssl/*		: sequence from openssl rand function
# seq/*/rc4/*			: sequence from RC4 (128 bit key)
# seq/*/spritz/*		: sequence from Spritz
# seq/*/vmpc/*			: sequence from VMPC (KSA variant)
# seq/*/rc4p/*			: sequence from RC4+
# seq/*/aes128ctr/*		: sequence from AES-128-CTR
# seq/*/aes192ctr/*		: sequence from AES-192-CTR
# seq/*/aes256ctr/*		: sequence from AES-256-CTR
# seq/*/crand/*			: sequence of first bytes of C rand() function
# seq/*/randu/*			: sequence of first two bytes of RANDU function
# seq/*/hc128/*			: sequence from hc128
# seq/*/rabbit			: sequence from rabbit (eSTREAM implementation)
# seq/*/trivium			: sequence from trivium (eSTREAM implementation)
# seq/*/sosemanuk		: sequence from sosemanuk (eSTREAM implementation)
# seq/*/salsa20			: sequence from salsa20 (eSTREAM implementation)
# seq/*/grain			: sequence from grain (eSTREAM implementation)
# seq/*/mickey			: sequence from mickey (eSTREAM implementation)

function compileSmallC # $1: generator name
{
	if [ ! -f bin/$1 ]; then
		gcc --std=c99 generators/$1.c -o bin/$1
	fi
}

function compileEstream # $1: generator name
{
	if [ ! -f bin/$1 ]; then
		gcc --std=c99 generators/common/ecrypt-sync.c generators/$1/$1.c generators/$1/$1_gen.c -o bin/$1 -iquote generators/common -iquote generators/$1
	fi
}

compileSmallC "spritz"
compileSmallC "vmpc"
compileSmallC "rc4p"
compileSmallC "c_rand"
compileSmallC "randu"
compileSmallC "hc128"

if [ ! -f bin/los-rng ]; then
	g++ --std=c++11 generators/los-rng.cpp -o bin/los-rng
fi

compileEstream "rabbit"
compileEstream "trivium"
compileEstream "sosemanuk"
compileEstream "salsa20"
compileEstream "grain"
compileEstream "mickey"

function generate # $1: index number $2: file prefix $3: cipher key
{
	i=$1
	FPREFIX=$2
	FKEY=$3
	IHEX="00000000000000000000000000000000" # just for IVs here
	
	KEY32=`echo $FKEY | cut -c1-8`
	DKEY32=`echo $((16#$KEY32))`
	KEY80=`echo $FKEY | cut -c1-20`
	KEY128=`echo $FKEY | cut -c1-32`
	KEY192=`echo $FKEY | cut -c1-48`
	KEY256=$FKEY
	
	BLLEN=$(($BLEN/1024))

	FNAME="$FPREFIX/urand/$i"
	dd if=/dev/urandom of=$FNAME count=$BLLEN bs=1KiB iflag=fullblock status=none &
	P0=$!
	
	FNAME="$FPREFIX/openssl/$i"
	openssl rand -out $FNAME $BLEN &
	P1=$!
	
	FNAME="$FPREFIX/rc4/$i"
	head -c $BLEN /dev/zero | openssl rc4 -out $FNAME -K $KEY128 &
	P2=$!
	
	FNAME="$FPREFIX/spritz/$i"
	bin/spritz $BLEN $KEY128 > $FNAME &
	P3=$!
	
	FNAME="$FPREFIX/vmpc/$i"
	bin/vmpc $BLEN $KEY128 > $FNAME &
	P4=$!
	
	FNAME="$FPREFIX/rc4p/$i"
	bin/rc4p $BLEN $KEY128 > $FNAME &
	P5=$!
	
	FNAME="$FPREFIX/aes128ctr/$i"
	head -c $BLEN /dev/zero | openssl enc -aes-128-ctr -out $FNAME -K $KEY128 -iv $IHEX &
	P6=$!
	
	FNAME="$FPREFIX/aes192ctr/$i"
	head -c $BLEN /dev/zero | openssl enc -aes-192-ctr -out $FNAME -K $KEY192 -iv $IHEX &
	P7=$!
	
	FNAME="$FPREFIX/aes256ctr/$i"
	head -c $BLEN /dev/zero | openssl enc -aes-256-ctr -out $FNAME -K $KEY256 -iv $IHEX &
	P8=$!
	
	FNAME="$FPREFIX/crand/$i"
	bin/c_rand $BLEN $DKEY32 > $FNAME &
	P9=$!
	
	FNAME="$FPREFIX/randu/$i"
	bin/randu $BLEN $DKEY32 > $FNAME &
	P10=$!
	
	FNAME="$FPREFIX/hc128/$i"
	bin/hc128 $BLEN $KEY128 > $FNAME &
	P11=$!
	
	FNAME="$FPREFIX/rabbit/$i"
	bin/rabbit $BLEN $KEY128 > $FNAME &
	P12=$!
	
	FNAME="$FPREFIX/trivium/$i"
	bin/trivium $BLEN $KEY80 > $FNAME &
	P13=$!
	
	FNAME="$FPREFIX/sosemanuk/$i"
	bin/sosemanuk $BLEN $KEY256 > $FNAME &
	P14=$!
	
	FNAME="$FPREFIX/salsa20/$i"
	bin/salsa20 $BLEN $KEY256 > $FNAME &
	P15=$!
	
	FNAME="$FPREFIX/grain/$i"
	bin/grain $BLEN $KEY128 > $FNAME &
	P16=$!
	
	FNAME="$FPREFIX/mickey/$i"
	bin/mickey $BLEN $KEY128 > $FNAME &
	P17=$!
	
	wait $P0
	wait $P1
	wait $P2
	wait $P3
	wait $P4
	wait $P5
	wait $P6
	wait $P7
	wait $P8
	wait $P9
	wait $P10
	wait $P11
	wait $P12
	wait $P13
	wait $P14
	wait $P15
	wait $P16
	wait $P17
}

for i in $(seq 1 $NSEQ); do 
	IHEX=`echo "obase=16; $i" | bc`
	generate $i "seq/N" $IHEX
	IHEX=`echo "$i" | sha256sum | cut -c1-64`
	generate $i "seq/R" $IHEX
	if ! (($i % 100)); then
		echo "$i / $NSEQ"
	fi
done
