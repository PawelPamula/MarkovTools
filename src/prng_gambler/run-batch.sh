#!/bin/bash

BATCH_START=1
BATCH_END=16

for num in `seq $BATCH_START $BATCH_END`; do
	sfx=`printf "%04x" $num`
	sed -i "s/ADD_BASE=\"GAMBLER_....\"/ADD_BASE=\"GAMBLER_$sfx\"/g" generator.sh
	# grep "ADD_BASE=" generator.sh
	julia Main.jl results-$num.csv
done
