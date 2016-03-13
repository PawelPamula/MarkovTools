FKEY="00000000000000000000000000000000"
IHEX="00000000000000000000000000000000" # just for IVs here

KEY32=`echo $FKEY | cut -c1-8`
DKEY32=`echo $((16#$KEY32))`
KEY80=`echo $FKEY | cut -c1-20`
KEY128=`echo $FKEY | cut -c1-32`
KEY192=`echo $FKEY | cut -c1-48`
KEY256=$FKEY

BLEN=65536
BLLEN=$(($BLEN/1024))

FNAME="tmp.out"

echo /dev/urandom
time dd if=/dev/urandom of=$FNAME count=$BLLEN bs=1KiB iflag=fullblock status=none
echo openssl rand
time openssl rand -out $FNAME $BLEN
echo openssl rc4
time head -c $BLEN /dev/zero | openssl rc4 -out $FNAME -K $KEY128
echo spritz
time bin/spritz $BLEN $KEY128 > $FNAME
echo vmpc
time bin/vmpc $BLEN $KEY128 > $FNAME
echo rc4+
time bin/rc4p $BLEN $KEY128 > $FNAME
echo aes128ctr
time head -c $BLEN /dev/zero | openssl enc -aes-128-ctr -out $FNAME -K $KEY128 -iv $IHEX
echo aes192ctr
time head -c $BLEN /dev/zero | openssl enc -aes-192-ctr -out $FNAME -K $KEY192 -iv $IHEX
echo aes256ctr
time head -c $BLEN /dev/zero | openssl enc -aes-256-ctr -out $FNAME -K $KEY256 -iv $IHEX
echo c_rand
time bin/c_rand $BLEN $DKEY32 > $FNAME
echo randu
time bin/randu $BLEN $DKEY32 > $FNAME
echo hc128
time bin/hc128 $BLEN $KEY128 > $FNAME
echo rabbit
time bin/rabbit $BLEN $KEY128 > $FNAME
echo trivium
time bin/trivium $BLEN $KEY80 > $FNAME
echo sosemanuk
time bin/sosemanuk $BLEN $KEY256 > $FNAME
echo salsa20
time bin/salsa20 $BLEN $KEY256 > $FNAME
echo grain
time bin/grain $BLEN $KEY128 > $FNAME
echo mickey
time bin/mickey $BLEN $KEY128 > $FNAME

rm $FNAME
