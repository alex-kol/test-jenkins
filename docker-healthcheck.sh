#!/bin/bash

set -e

if [ "$MODE" == "backend" ]; then

  SCRIPT_NAME=public/index.php SCRIPT_FILENAME=public/index.php REQUEST_METHOD=GET cgi-fcgi -bind -connect 127.0.0.1:9000 | grep 'X-Powered-By: PHP'

elif [ "$MODE" == "worker" ]; then

  DIR=$(find /proc -mindepth 2 -maxdepth 2 -name exe  -exec ls -lh {} \; 2>/dev/null | grep php | dirname `awk '/proc/ {print $9}'`  exe | grep proc)
  cd $DIR
  grep 'queue' cmdline


elif [ "$MODE" == "cron" ]; then

  /usr/sbin/service cron status | grep 'is running'

elif [ "$MODE" == "nginx" ]; then

  node healthcheck.js

fi
