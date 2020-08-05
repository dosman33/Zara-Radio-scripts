#!/bin/bash
# 03-01-12 / dosman / sort zara log files and give counts on non-file play events
###################################################################################

STATION="1680AM The Ocho!"
METACOMMAND="lastzarasongs"

OUTPATH=/opt/www/ocho/reports
OUTPOST=_exception_tally.txt
LOGDIR=/opt/www/ocho/reports/playout

###################################################################################
YM=`date +%Y-%m`
MONTH=`date +%B`
YEAR=`date +%Y`

TMP1=/tmp/$$_zaralog_tally-1.tmp
cleanup() {
        rm -rf $TMP1
}
trap 'echo "--Interupt signal detected, cleaning up and exiting" ; cleanup ; exit 1' 2 3        #SIGINT SIGQUIT

date_mangle() {
# Subtract n number of days from current date, default output is numeric dates with leading zeros on 1-digit days and months
# $1 = number of days to subtract, assumes 1 if nothing specified

# $2 = changes output formatting if specified, valid input: -0, -1, -2:
# Default output:                        09 06 10  = June 9th, 2010
# No leading zeros:                 -0:  9 6 10    = June 9th, 2010
# Alpha month:                      -1:  09 Jun 10 = June 9th, 2010
# No leading zeros and alpha month: -2:  9 Jun 10  = June 9th, 2010

if [[ -z $1 ]];then
        typeset day_in=1
else
        typeset day_in=$1
fi
if [[ -n $2 ]];then
        # Configure how output should look: default is no leading zeros for numbers, all numeric output
        typeset zero
        typeset alpha
        case $2 in
                -0) zero=1 ;;
                -1) alpha=1 ;;
                -2) zero=1 ; alpha=1 ;;
                *) # invalid input, just give default output
                   true
                   ;;
        esac
fi

typeset MM=`date +"%m"`
typeset DD=`date +"%d"`
typeset YY=`date +"%y"`
typeset i0001=0
until [[ $i0001 = $day_in ]]
do
        i0001=`expr $i0001 + 1`
        DD=`expr $DD - 1`
        if [[ $DD -eq 0 ]];then
                DD=31
                MM=`expr $MM - 1`
                if [[ $(echo ${MM}|wc -c|tr -d " ") = "2" ]];then
                        MM=0${MM}
                fi
                #echo 'if [[ $MM -eq 0 ]];then---------------------------------------'
                if [[ $MM -eq 0 ]];then
                        MM=12
                        YY=`expr $YY - 1`
                elif [[ $MM -eq 2 && DD=29 ]];then
                        DD=28
                fi
                if [ $MM -eq 4 ];then DD=30;fi
                if [ $MM -eq 6 ];then DD=30;fi
                if [ $MM -eq 9 ];then DD=30;fi
                if [ $MM -eq 11 ];then DD=30;fi
        fi
done
if [[ $alpha = 1 ]];then
        case $MM in
                01) MM=Jan ;;
                02) MM=Feb ;;
                03) MM=Mar ;;
                04) MM=Apr ;;
                05) MM=May ;;
                06) MM=Jun ;;
                07) MM=Jul ;;
                08) MM=Aug ;;
                09) MM=Sep ;;
                10) MM=Oct ;;
                11) MM=Nov ;;
                12) MM=Dec ;;
        esac
fi
if [[ $zero = 1 && $alpha != 1 ]];then
        #Strip leading 0's
        MM=`expr $MM + 0`   # Strip leading 0's
        DD=`expr $DD + 0`   # Strip leading 0's
elif [[ $zero = 1 && $alpha = 1 ]];then
        #Strip leading 0's, don't do month as it's not numeric
        DD=`expr $DD + 0`   # Strip leading 0's
else
        #Insert zero into day if single digit number; months already do this by default
        if [[ $(echo ${DD}|wc -c|tr -d " ") = "2" ]];then
                DD=0${DD}
        fi
fi
echo "${YY} ${MM} ${DD}"
unset zero alpha DD MM YY i0001
}

###################################################################################
if [[ $1 == "-h" || $1 == "--h" || $1 == "-?" || $1 == "--?" ]];then
	echo "Usage:"
	echo "$0     - process Zara playout log and tally exceptions for the current month"
	echo "$0 -p  - process Zara playout log and tally exceptions for the previous month"
	exit
elif [[ $1 == "-p" ]];then
	# process previous month
	myDATE=`date_mangle 1 `
	YM=`echo $myDATE | awk '{print $1"-"$2}'`
	MONTH=`echo $myDATE | awk '{print $2}'`
	YEAR=`echo $myDATE | awk '{print $1}'`
	OUT=${OUTPATH}/20${YM}${OUTPOST}

	find $LOGDIR -type f -name "20${YM}*.log" -exec cat {} > $TMP1 \;
	echo "$STATION exception tally for ${YM}" > $OUT
	echo "------------------------------------------------------------------------------------" >> $OUT
	egrep -v "^[a-z]|^[A-Z]|^--|^==|^$" $TMP1 | egrep "      warning|        error|shutdown|startup|Maximum wait reached|Silence detected|${METACOMMAND}|updated_reports|jingles|playlists" | cut -c 16- | sort | uniq -c | sort -rn >> $OUT

else
	# process current month
	OUT=${OUTPATH}/current_month${OUTPOST}
	find $LOGDIR -type f -name "${YM}*.log" -exec cat {} > $TMP1 \;
	echo "$STATION exception tally for $YM" > $OUT
	echo "------------------------------------------------------------------------------------" >> $OUT
	egrep -v "^[a-z]|^[A-Z]|^--|^==|^$" $TMP1 | egrep "      warning|        error|shutdown|startup|Maximum wait reached|Silence detected|${METACOMMAND}|updated_reports|jingles|playlists" | cut -c 16- | sort | uniq -c | sort -rn >> $OUT
fi
cleanup
