#!/bin/bash

BUSTEDVERSION=2.0.rc12

if luarocks list --porcelain busted $BUSTEDVERSION | grep -q "installed"; then
  echo busted already installed, skipping ;
else
  echo busted not found, installing via luarocks...;
  luarocks install busted $BUSTEDVERSION;
fi