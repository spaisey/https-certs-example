#!/usr/bin/env bash

rm -rf out
mkdir out

# Generate Private Key
openssl genrsa -aes256 -out out/myCA.key 2048

# Generate Root Certificate
openssl req -x509 -new -nodes -key out/myCA.key -sha256 -days 1825 -out out/myCA.pem