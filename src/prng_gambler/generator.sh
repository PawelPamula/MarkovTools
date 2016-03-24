#!/bin/bash

#
# Usage: generator.sh [kdf: sha|hex|echo] [generator] [length] [keybase]

DATE=`date`
echo "$DATE $1 $2 $3 $4" >> generator.log

# set the key derivation function [possible are sha, echo and hex]
KDF=$1

function sha # $1 keybase # hashes keybase and returns hex
{
	echo $1 | sha256sum | cut -c1-64
}

function hex # $1 keybase # interprets key as integer and returns hex repr.
{
	echo "obase=16; $1" | bc
}

function kdf32 # $1 keybase
{
	KEY=`$KDF $1`
	echo $KEY | cut -c1-8
}

function kdf32d # $1 keybase
{
	KEY=`kdf32 $1`
	echo $((16#$KEY))
}

function kdf64 # $1 keybase
{
	KEY=`$KDF $1`
	echo $KEY | cut -c1-8
}

function kdf64d # $1 keybase
{
	KEY=`kdf64 $1`
	echo $((16#$KEY))
}

function kdf80 # $1 keybase
{
	KEY=`$KDF $1`
	echo $KEY | cut -c1-20
}

function kdf128 # $1 keybase
{
	KEY=`$KDF $1`
	echo $KEY | cut -c1-32
}

function kdf192 # $1 keybase
{
	KEY=`$KDF $1`
	echo $KEY | cut -c1-48
}

function kdf256 # $1 keybase
{
	KEY=`$KDF $1`
	echo $KEY | cut -c1-64
}


# generator functions:
# [generator] [length in bytes] [keybase in hex]

function urandom # [length] [keybase] # keybase ignored for urandom
{
	BLLEN=$(($1/1024))
	dd if=/dev/urandom of=/dev/stdout count=$BLLEN bs=1KiB iflag=fullblock status=none
}

function openssl-rnd # [length] [keybase] # keybase ignored for openssl rand
{
	openssl rand $1 2>tmp.log
	grep -v "error writing output file" tmp.log >> err.log
}

function rc4 # [length] [keybase]
{
	KEY128=`kdf128 $2`
	head -c $1 /dev/zero | openssl rc4 -K $KEY128 2>tmp.log
	grep -v "error writing output file" tmp.log >> err.log
}
	
function spritz # [length] [keybase]
{
	KEY128=`kdf128 $2`
	bin/spritz $1 $KEY128
}

function vmpc # [length] [keybase]
{
	KEY128=`kdf128 $2`
	bin/vmpc $1 $KEY128
}
	
function rc4p # [length] [keybase]
{
	KEY128=`kdf128 $2`
	bin/rc4p $1 $KEY128
}

function aes128ctr # [length] [keybase]
{
	KEY128=`kdf128 $2`
	head -c $1 /dev/zero | openssl enc -aes-128-ctr -out $FNAME -K $KEY128 -iv $IHEX
}

function aes192ctr # [length] [keybase]
{
	KEY192=`kdf192 $2`
	head -c $1 /dev/zero | openssl enc -aes-192-ctr -out $FNAME -K $KEY192 -iv $IHEX
}

function aes256ctr # [length] [keybase]
{
	KEY256=`kdf256 $2`
	head -c $1 /dev/zero | openssl enc -aes-256-ctr -out $FNAME -K $KEY256 -iv $IHEX
}

function c_rand # [length] [keybase]
{
	DKEY32=`kdf32d $2`
	bin/c_rand $1 $DKEY32
}

function randu # [length] [keybase]
{
	DKEY32=`kdf32d $2`
	bin/randu $1 $DKEY32
}

function hc128 # [length] [keybase]
{
	KEY128=`kdf128 $2`
	bin/hc128 $1 $KEY128
}

function rabbit # [length] [keybase]
{
	KEY128=`kdf128 $2`
	bin/rabbit $1 $KEY128
}

function trivium # [length] [keybase]
{
	KEY80=`kdf80 $2`
	bin/trivium $1 $KEY80
}

function sosemanuk # [length] [keybase]
{
	KEY256=`kdf256 $2`
	bin/sosemanuk $1 $KEY256
}
	
function salsa20 # [length] [keybase]
{
	KEY256=`kdf256 $2`
	bin/salsa20 $1 $KEY256
}
	
function grain # [length] [keybase]
{
	KEY128=`kdf128s $2`
	bin/grain $1 $KEY128
}
	
function mickey # [length] [keybase]
{
	KEY128=`kdf128 $2`
	bin/mickey $1 $KEY128
}
	
function ffcsr # [length] [keybase]
{
	KEY80=`kdf80 $2`
	bin/ffcsr $1 $KEY80
}

function mersenne # [length] [keybase]
{
	DKEY64=`kdf64d $2`
	bin/los-rng Mersenne $1 $DKEY64
}

$2 $3 $4
