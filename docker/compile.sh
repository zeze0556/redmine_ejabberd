#!/bin/bash

set -x
export LANG=zh_CN.UTF-8
mix local.rebar --force
mix local.hex --force
mix deps.get
sed -i 's/crypto.rand_bytes/crypto.strong_rand_bytes/g' deps/romeo/lib/romeo/stanza.ex
mix deps.compile
mix compile
