#!/bin/sh

#############################################################
#
# Simple helper that checks if an HTTP host is available.
# (Relies on wget)
# 
# Within hudson it can be used to test if the AS instance
# has successfully booted.
#
# @author Heiko.Braun@jboss.com
#
#############################################################

TIMEOUT=2           # wget timeout in sec
SLEEP_TIME=5		# the actual sleep time in between test
NUM_RETRIES=60 		# equals to 5 minutes before exit

if [ "x$1" = "x" ]; then
	echo "Usage: http.sh <hostname:port> <output_dir>"		
fi

if [ "x$2" = "x" ]; then
        echo "Usage: http.sh <hostname:port> <output_dir>"
fi

# cleanup
rm $2/spider.success 2&>1 /dev/null
rm $2/spider.failed 2&>1 /dev/null

COUNTER=0
while [  $COUNTER -lt $NUM_RETRIES ]; do
	if wget --spider --timeout=$TIMEOUT --tries=1 $1 &> /dev/null; then
		touch $2/spider.success
		echo "Try $COUNTER: '$1' is available"	> ./spider.success
		exit 0
	else
		echo "Try $COUNTER: '$1' does not respond, wait another $SLEEP_TIME seconds"
	fi
	sleep $SLEEP_TIME
	let COUNTER=COUNTER+1 
done

touch $2/spider.failed
echo "Unable to connect to $1, exiting..." > spider.failed
exit 0


