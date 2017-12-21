#!/bin/bash
set -ex

if [[ "$#" -ne 1 ]]; then
  echo "$0 [image]"
  exit 1
fi

make_args="DOCKER=docker REGISTRY=gcr.io/shopify-docker-images/cloud"

docker run -v $PWD:/go/src/k8s.io/ingress-nginx -w /tmp/src golang:1.8 make -C /go/src/k8s.io/ingress-nginx build $make_args

SHA="$(echo $1| cut -d ':' -f2)"
make container TAG=$SHA ARCH=amd64 $make_args
