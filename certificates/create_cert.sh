#!/usr/bin/env bash

# Create the issued certificate
openssl x509 -req -in out/server.csr -CA out/myCA.pem -CAkey out/myCA.key -CAcreateserial -out out/server.crt -days 1825 -sha256 -extfile server.cert.config
openssl x509 -req -in out/client.csr -CA out/myCA.pem -CAkey out/myCA.key -CAcreateserial -out out/client.crt -days 1825 -sha256 -extfile client.cert.config

openssl pkcs12 -export -in out/server.crt -inkey out/server.key -out out/server.p12 -chain -name server -CAfile out/myCA.pem -caname rootserver
openssl pkcs12 -export -in out/client.crt -inkey out/client.key -out out/client.p12 -chain -name client -CAfile out/myCA.pem -caname rootclient

keytool -importkeystore -deststorepass 123456 -destkeypass 123456 -destkeystore out/server.jks \
        -srckeystore out/server.p12 -srcstoretype PKCS12 -srcstorepass 123456 \
        -alias server -deststoretype PKCS12
keytool -importkeystore -deststorepass 123456 -destkeypass 123456 -destkeystore out/client.jks \
        -srckeystore out/client.p12 -srcstoretype PKCS12 -srcstorepass 123456 \
        -alias client -deststoretype PKCS12

keytool -import -v -alias root -file out/myCA.pem -keystore out/client_truststore.jks -deststorepass 123456
keytool -import -v -alias root -file out/myCA.pem -keystore out/server_truststore.jks -deststorepass 123456
