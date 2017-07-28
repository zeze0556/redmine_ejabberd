#!/bin/bash

set -x

sleep 5

ping -c 1 chatbuild 2>/dev/null 1>/dev/null

while [ $? == 0 ]; do
    echo "build is working sleep 5"
    sleep 5;
    ping -c 1 chatbuild 2>/dev/null 1>/dev/null
done

echo "build is over start server last=$?"
export LANG=zh_CN.UTF-8
mix run --no-halt

