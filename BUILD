#!/bin/bash
set -ex

if [[ "$#" -ne 1 ]]; then
  echo "$0 [image]"
  exit 1
fi

docker run -v $PWD:/go/src/k8s.io/ingress -w /tmp/src golang:1.8 make -C /go/src/k8s.io/ingress/controllers/nginx build

SHA="$(echo $1| cut -d ':' -f2)"
make -C controllers/nginx container TAG=$1