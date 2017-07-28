#!/bin/bash

set -x
export LANG=zh_CN.UTF-8
mix local.rebar --force
mix local.hex --force
mix deps.get && mix compile
