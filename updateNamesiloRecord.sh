#!/usr/bin/env sh

print(){
  echo $1
}

getMyIp(){
  IP=$(curl -s $IP_ECHO)
  echo $IP
}

LIST_XML_FILE=_list_temp.xml
getRecordId(){
  curl -s "https://www.namesilo.com/api/dnsListRecords?version=1&type=xml&key=$API_KEY&domain=$DOMAIN" > $LIST_XML_FILE
  VAL=$(xmllint --xpath "/namesilo/reply/resource_record[host=\"$RECORD_NAME.$DOMAIN\"]/record_id/text()" $LIST_XML_FILE)
  echo $VAL
}

UPDATE_XML_FILE=_update_temp.xml
updateRecord(){
  RRID=$(getRecordId)
  if [ -z "$RRID" ]
  then
    print "got invalid RRID"
    return 1
  fi
  curl -s "https://www.namesilo.com/api/dnsUpdateRecord?version=1&type=xml&key=$API_KEY&domain=$DOMAIN&rrid=$RRID&rrhost=$RECORD_NAME&rrvalue=$MY_IP&rrttl=7207" > $UPDATE_XML_FILE
  RESULT=$(xmllint --xpath '/namesilo/reply/detail/text()' $UPDATE_XML_FILE)
  echo $RESULT
}

updateAndLog(){
  UPDATE_RESULT=$(updateRecord)
  # print $UPDATE_RESULT
  echo $UPDATE_RESULT
}

is_Ip(){
  str=$1
  if expr "$str" : '[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$' >/dev/null; then
    for i in 1 2 3 4; do
      if [ $(echo "$ip" | cut -d. -f$i) > 255 ]; then
        return 1
      fi
    done
  else
    return 1
  fi
  echo "yes"
}

MY_LAST_IP=None
checkMyIp(){
  # print "gonna get ip from [$IP_ECHO]"
  MY_IP=$(getMyIp)
  # print "new ip [$MY_IP]"
  NOW=$(now)
  if [ -z "$IS_CRON_JOB" ]
  then
    if [ "$MY_LAST_IP" = "$MY_IP" ]
    then
      SAME_COUNT=$(expr $SAME_COUNT + 1)
      MODULO=$(expr $SAME_COUNT % $PRINT_SAME_COUNT_STEP)
      # print "Ip unchanged: $MY_IP"
      if [ "$MODULO" = "0"  ]
      then
        UPDATE_LOG="[$NOW] make sure it's still [$MY_IP] after [$SAME_COUNT] times"
        UPDATE_RESULT=$(updateRecord)
        print "$UPDATE_LOG [$UPDATE_RESULT]"
      fi
      return 0
    fi
  fi
  IS_IP=$(is_Ip $MY_IP)
  if [ "$IS_IP" != "yes" ]
  then
    echo "getMyIp got invalid value: $MY_IP"
    return 1
  fi
  UPDATE_LOG="[$NOW] replace [$MY_LAST_IP] to [$MY_IP] after [$SAME_COUNT] times"
  UPDATE_RESULT=$(updateRecord)
  print "$UPDATE_LOG [$UPDATE_RESULT]"
  # print "[$NOW] replace [$MY_LAST_IP] to [$MY_IP] $UPDATE_RESULT"
  if [ "$UPDATE_RESULT" = "success" ]
  then
    MY_LAST_IP=$MY_IP
    SAME_COUNT=0
  fi
  touch /tmp/i_am_ready
}

now(){
  echo $(date +'%Y-%b-%d %T')
}

exitScript(){
  trap "exit 1" TERM
  export TOP_PID=$$
  kill -s TERM $TOP_PID
}

validate(){
  VAR_NAME=$1
  VAR_VALUE=$2
  DEFAULT_VALUE=$3
  if [ -z "${VAR_VALUE}" ]
  then
    print "please set your [$VAR_NAME] in environment variable"
    exitScript
  fi
}

# log every (CHECK_INTERVAL_SECONDS * PRINT_SAME_COUNT_STEP) seconds for same ip
IpEchoDefault=http://icanhazip.com

chech_IP_ECHO(){
  if [ -z "${IP_ECHO}" ]
  then
    IP_ECHO=$IpEchoDefault
  fi
}

validateEnvironmentVariable(){
  validate API_KEY $API_KEY
  validate DOMAIN $DOMAIN
  validate RECORD_NAME $RECORD_NAME
  chech_IP_ECHO
}

printAll(){
  print "last 4 char of API_KEY: ${API_KEY#"${API_KEY%????}"}"
  print "DOMAIN: $DOMAIN"
  print "RECORD_NAME: $RECORD_NAME"
  print "PRINT_SAME_COUNT_STEP: $PRINT_SAME_COUNT_STEP"
  print "IP_ECHO: $IP_ECHO"
}

SAME_COUNT=0
COMMAND_NAME=$0
main(){
  validateEnvironmentVariable

  if [ "$IS_DEBUG_MODE" = 1 ]
  then
    printAll
  fi

  print "$COMMAND_NAME start at [$(now)]"
  while :
  do
    checkMyIp
  done
}

if [ "$IS_CRON_JOB" = 1 ]
then
  validateEnvironmentVariable
  if [ "$IS_DEBUG_MODE" = 1 ]
  then
    printAll
  fi

  checkMyIp
  exit 0
else
  main
fi
