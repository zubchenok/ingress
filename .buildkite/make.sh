#!/bin/bash
set -ex

: ${PIPA_IMAGE_FULL_NAME?Missing Pipa environment}

export REGISTRY=$(echo $PIPA_IMAGE_FULL_NAME | cut -d':' -f1)
export TAG=$(echo $PIPA_IMAGE_FULL_NAME | cut -d':' -f2)

if [[ "$#" -ne 1 ]]; then
  echo "$0 [image]"
  exit 1
fi

docker run -v $PWD:/go/src/k8s.io/ingress -w /tmp/src golang:1.8 make -C /go/src/k8s.io/ingress/controllers/nginx build

make -C controllers/nginx container