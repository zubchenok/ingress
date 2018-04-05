#!/bin/bash

# Copyright 2015 The Kubernetes Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

DESTDIR=./rootfs/etc/nginx/lua/vendor

get_src()
{
  hash="$1"
  url="$2"
  f=$(basename "$url")

  curl -sSL "$url" -o "$f"
  tar xzf "$f"
  rm -rf "$f"
}

cd "$DESTDIR"
rm -rf *

get_src d4a9ed0d2405f41eb0178462b398afde8599c5115dcc1ff8f60e2f34a41a4c21 \
        "https://github.com/openresty/lua-resty-lrucache/archive/v0.07.tar.gz"

get_src 92fd006d5ca3b3266847d33410eb280122a7f6c06334715f87acce064188a02e \
        "https://github.com/openresty/lua-resty-core/archive/v0.1.14rc1.tar.gz"

get_src eaf84f58b43289c1c3e0442ada9ed40406357f203adc96e2091638080cb8d361 \
        "https://github.com/openresty/lua-resty-lock/archive/v0.07.tar.gz"


cd "lua-resty-core-0.1.14rc1"
make install

cd ..
cd "lua-resty-lrucache-0.07"
make install

cd ..
cd "lua-resty-lock-0.07"
make install
