#!/bin/bash
# 01-31-12 / dosman / v1.0 / decode zara radio event records into human readable format & HTML
##################################################################################################

# HTML output file if -html is used
OUT=/opt/www/ocho/podcasts/events.html
# Uncommenting this skips inactive records in the HTML output
#SKIP_INACTIVE=1

#DEBUG=1
#ENABLE_COUNTER=1	# DEBUG must be enabled for the byte-by-byte counter

##################################################################################################

if [[ $1 == "-html" ]];then
	INFILE=$2
	HTML=1
	echo "<html><title>ZaraRadio Event List</title><body><meta http-equiv=\"refresh\" content=\"21600\">" > $OUT
	echo "<table border=2><tr> <th>Active</th> <th>Hour<br>Date</th> <th>Start</th> <th>Event</th> <th>Priority</th> <th>Max Wait</th> <th>Days</th> <th>Hours</th> <th>Expiration</th>  </tr>" >> $OUT
else
	INFILE=$1
	HTML=0
fi

if [[ ! -e $INFILE ]];then
	echo "Error! $1 was not found."
	exit 10
fi

TMP1=/tmp/$$_zara_evt_parser-01.tmp
cleanup() {
        rm -rf $TMP1
}
trap 'echo "--Interupt signal detected, cleaning up and exiting" ; cleanup ; exit 1' 2 3        #SIGINT SIGQUIT

# dump to hex, parse 1 byte at a time
/usr/bin/od -v -A n -t x1 -w1 $INFILE > $TMP1

##################################################################################################
# Event records:
VERSION=
#NEW_RECORD=0
FIRST_RECORD=0
PRIORITY=low
IMMEDIATE=
#DELAYED=0
#MAXWAIT=
MAXDELAY=
PLAYEVERYHOUR=no
PLAYOTHERHOURS=no
THEOTHERHOURS=
EVENT=0
RECLENGTH=
FILE=
EVENTSTART=
EVENTEND=
EXPIRES=no
ACTIVE=
DAYS=

##################################################################################################
count() {
	COUNT=`expr $COUNT + 1`
}

step() {
	if [[ -n $DEBUG && -n $ENABLE_COUNTER ]];then
		echo "COUNT: ${COUNT} inbyte:${inbyte} case: $1"
	fi
}

reclength2dec() {
	# NOT WORKING, not needed for decoding-only purposes anyway
	# strip trailing zeros
	##myVAR=`echo $1 | rev | xargs expr 0 +`
	##myVAR2=`echo $myVAR | rev`
	#myVAR=`echo $1 | rev | awk '{print $1*1}' | rev`

	BYTE1=$1
	BYTE2=$2
	BYTE3=$3
	BYTE4=$4
	#if [[ $BYTE4 = "00" ]];
	echo "obase=10;ibase=16;$myVAR" | bc
}

otherhoursdecoder() {
	# reverse the byte-order 
	INPUT=`echo $3$2$1 | tr "[:lower:]" "[:upper:]"`
	# convert to binary and single-space numerals
	INPUT=`echo "obase=2;ibase=16;$INPUT" | bc | rev | sed 's/\(.\)/\1 /g'`
	HOURCOUNTER=0
	HOURTABULATOR=
	for i in $INPUT
	do
		if [[ $i -eq 1 && -z $HOURTABULATOR ]];then
			HOURTABULATOR="$HOURCOUNTER"
		elif [[ $i -eq 1 ]];then
			HOURTABULATOR="${HOURTABULATOR},$HOURCOUNTER"
		fi
		#echo "\$1 = $1 / INPUT = $INPUT / i = $i / HOURTABULATOR = $HOURTABULATOR / HOURCOUNTER = $HOURCOUNTER" >> /tmp/n6
		HOURCOUNTER=`expr $HOURCOUNTER + 1`
	done
	echo $HOURTABULATOR
}

days() {
	DAYCOUNTER=0
	DAYTABULATOR=
	for daysinn in `echo $1 $2 $3 $4 $5 $6 $7`
	do
		case $DAYCOUNTER in
			0) [[ $daysinn == "01" ]] && DAYTABULATOR="${DAYTABULATOR},Sun" ; DAYCOUNTER=`expr $DAYCOUNTER + 1`;;
			1) [[ $daysinn == "01" ]] && DAYTABULATOR="${DAYTABULATOR},Mon" ; DAYCOUNTER=`expr $DAYCOUNTER + 1`;;
			2) [[ $daysinn == "01" ]] && DAYTABULATOR="${DAYTABULATOR},Tue" ; DAYCOUNTER=`expr $DAYCOUNTER + 1`;;
			3) [[ $daysinn == "01" ]] && DAYTABULATOR="${DAYTABULATOR},Wed" ; DAYCOUNTER=`expr $DAYCOUNTER + 1`;;
			4) [[ $daysinn == "01" ]] && DAYTABULATOR="${DAYTABULATOR},Thu" ; DAYCOUNTER=`expr $DAYCOUNTER + 1`;;
			5) [[ $daysinn == "01" ]] && DAYTABULATOR="${DAYTABULATOR},Fri" ; DAYCOUNTER=`expr $DAYCOUNTER + 1`;;
			6) [[ $daysinn == "01" ]] && DAYTABULATOR="${DAYTABULATOR},Sat" ; DAYCOUNTER=`expr $DAYCOUNTER + 1`;;
		esac
	done
	echo "$DAYTABULATOR" | cut -c 2-
}

file_command() {
	# Zara embeds commands in the filename field for some events - process them
	if [[ $1 == ".play" ]];then
		echo "Play"
	elif [[ $1 == ".stop" ]];then
		echo "Stop"
	elif [[ $1 == ".satcon" ]];then
		echo "Connect to satellite"
	elif [[ $1 == ".satdis" ]];then
		echo "Disconnect from satellite"
	elif [[ `echo $1 | awk -F. '{print $2}'` == "satellite" ]];then
		# 13452.satellite is number of seconds to play the satellite feed
		TIME=`echo $1 | awk -F. '{print $1}'`
		TIME=`expr $TIME / 60`
		echo "Satellite for $TIME minutes"
	elif [[ `echo $1 | awk -F. '{print $2}'` == "stream" ]];then
		# localhost*11045.stream	
		STREAM=`echo $1 | awk -F\* '{print $1}'`
		TIME=`echo $1 | awk -F. '{print $1}' | awk -F\* '{print $2}'`
		TIME=`expr $TIME / 60`
		echo "Stream $STREAM for $TIME minutes"
	else
		echo "Error: unknown command: $1"
	fi
}
##################################################################################################

print_event() {
VERSION=`echo $VERSION | xxd -r -p`
FILE=`echo $FILE | xxd -r -p`
echo $FILE | egrep "\.play|\.stop|\.satcon|\.satdis|\.stream|\.satellite" > /dev/null
if [[ $? -eq 0 ]];then
	FILE=`file_command $FILE`
fi
#RECLENGTH=`reclength2dec $RECLENGTH`
EVENTSTART=`echo $EVENTSTART | xxd -r -p | awk '{print $2" "$1}'`
EVENTEND=`echo $EVENTEND | xxd -r -p | awk '{print $2" "$1}'`
MAXDELAY=`echo $MAXDELAY | tr "[:lower:]" "[:upper:]"`
MAXDELAY=`echo "obase=10;ibase=16;$MAXDELAY" | bc`
DAYS=`days $DAYS`


if [[ $HTML == 0 ]];then
####
if [[ $FIRST_RECORD == "1" ]];then
	echo "ZaraRadioEventVersion: $VERSION"
	echo ""
fi
####
echo "Active: $ACTIVE"
echo "Event: $FILE"
####
if [[ -n $DEBUG ]];then
	echo "RecordLength(hex): $RECLENGTH"
fi
####
echo "Days: $DAYS"
echo "StartOn:    $EVENTSTART"
####
if [[ -n $DEBUG ]];then
	echo "Expiration:   $EVENTEND"
	echo "ExpireEnabled: $EXPIRES"
elif [[ $EXPIRES == "no" ]];then
	# this record always populated, but ignored unless EXPIRES is set
	echo "Expiration: never"
else
	echo "Expiration: $EVENTEND"
fi
####
echo "Priority: $PRIORITY"
####
if [[ $IMMEDIATE == "yes" ]];then
	echo "Start: immediate"
else
	#echo "Start: max_delay_set"
	echo "Start: delayed"
fi
####
if [[ $PLAYEVERYHOUR == "yes" ]];then
	echo "PlayEveryHour: $PLAYEVERYHOUR"
elif [[ $PLAYOTHERHOURS == "yes" ]];then
	THEOTHERHOURS=`otherhoursdecoder $THEOTHERHOURS`
	echo "OtherHours(24hr): $THEOTHERHOURS"
else
	echo "Play: OnceDaily"
fi
####
if [[ $IMMEDIATE == "no" && $MAXDELAY != "255" ]];then
	# This can have a value even if IMMEDIATE is enabled - value is greyed out in Zara
	# If the value is uninitialized it seems to be set to ff along with the next two unused bytes in the file
	# which is strange as the next two bytes are not used as far as I can tell - may be a bug in Zara.
	# This 255 check could be bogus - zara caches old values here, need to check for both IMMEDIATE and some other byte we are missing in this file
	echo "MaxDelay(mins): $MAXDELAY"
fi
####
if [[ -n $DEBUG ]];then
	echo "Reserved/unknown bytes:"
	if [[ $FIRST_RECORD == "1" ]];then
		echo "byte05: $byte05"
	fi
	echo "byte8_10:  $byte8_10"
	echo "byte23_25: $byte23_25"
	echo "byte27_29: $byte27_29"
	echo "byte49_51: $byte49_51"
	echo "byte58_60: $byte58_60"
	echo "byte55:     $byte55"
fi
echo ","	# record separator for processing back into binary format
echo 

else
##################################
# HTML output

if [[ -n $SKIP_INACTIVE && $ACTIVE == "no" ]];then
	return
fi
echo "<tr><td>$ACTIVE</td>" >> $OUT
echo "<td>$EVENTSTART</td>" >> $OUT

if [[ $IMMEDIATE == "yes" ]];then
	echo "<td>Immediate</td>" >> $OUT
else
	echo "<td>Delayed</td>" >> $OUT
fi

echo "<td>$FILE</td>" >> $OUT
echo "<td>$PRIORITY</td>" >> $OUT

if [[ $IMMEDIATE == "no" && $MAXDELAY != "255" ]];then
	echo "<td>$MAXDELAY</td>" >> $OUT
else
	echo "<td>None</td>" >> $OUT
fi

echo "<td>$DAYS</td>" >> $OUT

#echo "PLAYEVERYHOUR = $PLAYEVERYHOUR"
#echo "PLAYOTHERHOURS = $PLAYOTHERHOURS"
if [[ $PLAYEVERYHOUR == "yes" ]];then
	echo "<td>Every hour</td>" >> $OUT
elif [[ $PLAYOTHERHOURS == "yes" ]];then
	THEOTHERHOURS=`otherhoursdecoder $THEOTHERHOURS`
	echo "<td>$THEOTHERHOURS</td>" >> $OUT
else
	# can we hit this? Play once a day
	echo "<td>Once daily</td>" >> $OUT
fi

if [[ $EXPIRES == "no" ]];then
	echo "<td>Never</td>" >> $OUT
else
	echo "<td>$EVENTEND</td> </tr>" >> $OUT
fi

#
fi
}

##################################################################################################
# Byte-processor

COUNT=0	# keep track of our position in a record, dont increment when parsing variable length records
while read inbyte
do
	case $COUNT in
		0) #NEW_RECORD=1
		step 0/version_check
		   if [[ `echo $inbyte | awk '{print $1}'` == "45" ]];then
		   	   VERSION=$inbyte
			   FIRST_RECORD=1
			   count
		   else
			   echo "Error processing first record: got byte \"${inbyte}\" - expecting \"45\""
			   exit 2
		   fi
		;;

		[1-4]) #NEW_RECORD=1
		step 1-4/ingest_version
		    VERSION="${VERSION} $inbyte"
		    count
		;;

		5) 
		step 5-versioncheck+first_record_nullbyte
		if [[ $FIRST_RECORD == "1" && $VERSION != "45 56 54 30 33" ]];then
			# we cant parse this version, abort
			echo "Wrong ZaraRadio event file version, aborting - $VERSION"
			cleanup
			exit 1
		fi
		if [[ $FIRST_RECORD == "1" ]];then
			# On first record this should be "00", all others this doesn't exist
			byte05=$inbyte
			count
		fi
		;;

		6)
		step 6-immediate_playback/EndOfFile_check
		if [[ $FIRST_RECORD == "0" && $inbyte == "0a" ]];then
			echo "End of file"
			exit 0
		elif [[ $inbyte == "01" ]];then
			IMMEDIATE=yes
		else
			IMMEDIATE=no
		fi
		count
		;;

		7)
		step 7-play_every/other_hours
		if [[ $inbyte == "01" ]];then
			PLAYEVERYHOUR=yes
		elif [[ $inbyte == "02" ]];then
			PLAYOTHERHOURS=yes
		else
			PLAYEVERYHOUR=no
			PLAYOTHERHOURS=no
		fi
		count
		;;

		#8-10
		[89] | 10) 	# reserved bytes, 0000 00
		step 8-10/reserved
			byte8_10="$byte8_10 $inbyte"
			count
		;;

		#11-17
		1[1-7]) 	# days of the week to play
		step 11-17/days_of_the_week_to_play
			DAYS="$DAYS $inbyte"
			count
		;;

		#18-21
		1[89] | 2[01]) RECLENGTH="${RECLENGTH} $inbyte"
		step 18-21/reclength
		count
		;;

		22) if [[ $inbyte == "11" ]];then
			count
		    else
			FILE="${FILE} $inbyte"
		    fi
		step 22/filename/record-end
		;;

		#23-25
		2[3-5]) # reserved bytes, always 0000 00
		step 23-25/reserved
			byte23_25="$byte23_25 $inbyte"
			count
		;;

		26) step 26
		    if [[ $inbyte == "11" ]];then
			count
		    else
			EVENTSTART="${EVENTSTART}$inbyte"
		    fi
		;;

		#27-29
		2[7-9])	# reserved bytes, always 0000 00
			step 27-29/reserved
			byte27_29="$byte27_29 $inbyte"
			count
		;;

		#30-46
		3[0-9] | 4[0-6]) step 30-46/event-end
		       EVENTEND="${EVENTEND}$inbyte"
		       count
		;;

		47) step 47/expires
		    if [[ $inbyte == "01" ]];then
			EXPIRES=yes
		    fi
		    count
		;;

		48) step 48/priority
		    if [[ $inbyte == "01" ]];then
			PRIORITY=high
		    fi
		    count
		;;

		#49-51
		49 | 5[01]) # reserved bytes, always 0000 00
		byte49_51="$byte49_51 $inbyte"
		step 49-51/reserved
		count
		;;

		#52-54
		5[2-4]) # this 3 byte value is binary value of hours 0-23 when OTHERHOURS type event is scheduled - in reverse-byte-order
		       step 52-54/theotherhours
		       THEOTHERHOURS="${THEOTHERHOURS} $inbyte"
		       count
		;;

		#55-56 #55
		55) # unsure, probably reserved bytes, usually 00
		    step 55/reserved
		    byte55="$inbyte"
		    count
		;;

		56) step 56/active-inactive
			if [[ $inbyte == "01" ]];then
				ACTIVE=yes
			else
				ACTIVE=no
			fi
			count
		;;
		57) # delay byte, max value is 3C for 60 minutes
		       step 57/delaytime-set_to_ff_when_not_used
		       MAXDELAY="$inbyte"
		       count
		;;

		#57-60
		5[89] | 60) # reserved/somehow related to delay byte, if set to "ffff ff" then it's unset
		       step 58-60/reserved/somehow_related_to_delay_byte,sometimes_set_to_ffff_ff
		       #MAXDELAY="${MAXDELAY}$inbyte"
		       byte58_60="${byte58_60} $inbyte"
		       count
		#;;
		##6[123]) # unsure, may be EOF marker or "active event" marker
		#61) # if byte is 0a we are at end of record - otherwise it's the first byte of the next record
		#    step 61/reserved/unsure?
		#    byte55="$byte55 $inbyte"

			if [[ $COUNT == "61" ]];then
				# reached the end of this event
				print_event
				#NEW_RECORD=0
				#COUNT=0
				#COUNT=7 # this aligns filename record count correctly, but not 100% correct
				COUNT=6
				FIRST_RECORD=0
	
				# reset everything
				unset NEW_RECORD IMMEDIATE DELAYED MAXDELAY THEOTHERHOURS EVENT RECLENGTH FILE EVENTSTART EVENTEND ACTIVE DAYS
				unset byte05 byte8_10 byte23_25 byte27_29 byte49_51 byte58_60 byte55
				PRIORITY=low
				PLAYEVERYHOUR=no
				PLAYOTHERHOURS=no
				EXPIRES=no
			fi
		;;
		*) #script bug
			echo "Error! Script bug, managed to count past end of the event record - aborting - COUNT = $COUNT"
			exit
		;;
	esac
done < $TMP1

if [[ $HTML == 1 ]];then
	echo "</table></body>" >> $OUT
fi

cleanup
