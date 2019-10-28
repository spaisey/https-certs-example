#!/usr/bin/env bash
curl -v --cacert ./out/myCA.pem --key out/client.key --cert out/client.crt https://localhost:8443/ping
