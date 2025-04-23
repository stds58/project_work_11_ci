#!/bin/bash

# Проверка доступности контейнера
if ! docker ps | grep -q nginx-ci; then
  echo "Container nginx-ci is not running!"
  exit 1
fi

# Проверка HTTP-статуса 200
HTTP_STATUS=$(curl -s -o /dev/null -w '%{http_code}' http://localhost:9889)
if [ "$HTTP_STATUS" -ne 200 ]; then
  echo "Error: HTTP status code $HTTP_STATUS != 200"
  exit 1
fi

# Проверка MD5
LOCAL_MD5=$(md5sum html/index.html | awk '{print $1}')
REMOTE_MD5=$(curl -s http://localhost:9889 | md5sum | awk '{print $1}')

if [ "$LOCAL_MD5" != "$REMOTE_MD5" ]; then
  echo "Error: MD5 mismatch"
  echo "Local:  $LOCAL_MD5"
  echo "Remote: $REMOTE_MD5"
  exit 1
fi

echo "All checks passed successfully"
exit 0