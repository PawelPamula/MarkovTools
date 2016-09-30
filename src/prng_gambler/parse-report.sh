#!/bin/bash

tail fullreport.csv -n+2 | sort > normreport.csv
# ^                         ^      ^--------------------# Save temporarily sorted report
# |                         +---------------------------# Sort the rows alphabetically (groups them together)
# +-----------------------------------------------------# Drop the first line (header)

sed -r "s/([^;]+;[^;]+;[^;]+;[^;]+;[^;]+;[^;]+;)[^;]+;[^;]+;/\\1/g" normreport.csv | uniq > tests.csv
# ^                                                                  ^                ^      ^-------# Save the names of test runs
# |                                                                  |                +--------------# Select only unique rows
# |                                                                  +-------------------------------# Use the temporary report file
# +--------------------------------------------------------------------------------------------------# Filter out only the first six columns

# Create a new output file for win/loss statistics
echo "sim;bs;i;N;p;q;win;loss;" > winloss.csv
while read test; do
	WON=`grep "${test}true;" normreport.csv | wc -l`
	LOST=`grep "${test}false;" normreport.csv | wc -l`
	# Append win/loss statistics to the aformentioned file
	echo "${test}${WON};${LOST};" >> winloss.csv

	# Prepare filename without spaces and semicolons
	FNAME=`echo "${test%?}" | sed -e "s/ //g" -e "s/;/-/g"`

	grep "${test}" normreport.csv | sed -e "s/$test//g" -re "s/(true|false);//g" -e "s/;//g" > "$FNAME-all.csv"
	grep "${test}true;" normreport.csv | sed -e "s/$test//g" -re "s/(true|false);//g" -e "s/;//g" > "$FNAME-won.csv"
	grep "${test}false;" normreport.csv | sed -e "s/$test//g" -re "s/(true|false);//g" -e "s/;//g" > "$FNAME-lost.csv"
done < tests.csv
