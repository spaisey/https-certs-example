#!/usr/bin/env bash

# Generate Private Key
openssl genrsa -out out/server.key 2048
openssl genrsa -out out/client.key 2048

# Generate CSR
openssl req -new -key out/server.key -out out/server.csr
openssl req -new -key out/client.key -out out/client.csr