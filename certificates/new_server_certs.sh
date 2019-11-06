#!/usr/bin/env bash

function log() {
  echo "**** [$1] ****"
}

export WORKING_DIR=`dirname $0`
export OUTPUT_DIR="${WORKING_DIR}/out"
export DEFAULT_PASSWORD="password"
log "Working directory: ${WORKING_DIR}"
log "Output directory: ${OUTPUT_DIR}"

rm -rf ${OUTPUT_DIR}
mkdir ${OUTPUT_DIR}

# ----------------------
log "Generate Root Private Key"
openssl genrsa -aes256 -out ${OUTPUT_DIR}/root.key -passout pass:${DEFAULT_PASSWORD} 2048

log "Generate Root Certificate"
openssl req -x509 -new -nodes -key ${OUTPUT_DIR}/root.key -sha256 -days 1825 -out ${OUTPUT_DIR}/root.pem -subj "/C=UK/ST=Avon/L=Bath/O=Pay360/CN=rootCA.pay360.com" -passin pass:${DEFAULT_PASSWORD}
# ----------------------

# ----------------------
log "Creating server key"
openssl genrsa -out ${OUTPUT_DIR}/server.key 2048
log "Creating client key"
openssl genrsa -out ${OUTPUT_DIR}/client.key 2048
log "Creating server certificate signing request"
openssl req -new -key ${OUTPUT_DIR}/server.key -out ${OUTPUT_DIR}/server.csr -subj "/C=UK/ST=Avon/L=Bath/O=Pay360/CN=server.pay360.com" -passin pass:${DEFAULT_PASSWORD}
log "Creating client certificate signing request"
openssl req -new -key ${OUTPUT_DIR}/client.key -out ${OUTPUT_DIR}/client.csr -subj "/C=UK/ST=Avon/L=Bath/O=Pay360/CN=testclient.pay360.com" -passin pass:${DEFAULT_PASSWORD}
# ----------------------

# ----------------------
log "Sign server certificate"
openssl x509 -req -extensions v3_req -in ${OUTPUT_DIR}/server.csr -CA ${OUTPUT_DIR}/root.pem -CAkey ${OUTPUT_DIR}/root.key -CAcreateserial -out ${OUTPUT_DIR}/server.crt -days 1825 -sha256 -extfile ${WORKING_DIR}/server.cert.config  -passin pass:${DEFAULT_PASSWORD}
log "Sign client certificate"
openssl x509 -req -extensions v3_req -in ${OUTPUT_DIR}/client.csr -CA ${OUTPUT_DIR}/root.pem -CAkey ${OUTPUT_DIR}/root.key -CAcreateserial -out ${OUTPUT_DIR}/client.crt -days 1825 -sha256 -extfile ${WORKING_DIR}/client.cert.config  -passin pass:${DEFAULT_PASSWORD}
# ----------------------

# ----------------------
log "Create server PKCS"
openssl pkcs12 -export -in ${OUTPUT_DIR}/server.crt -inkey ${OUTPUT_DIR}/server.key -out ${OUTPUT_DIR}/server.p12 -chain -name server -CAfile ${OUTPUT_DIR}/root.pem -caname rootserver -passin pass:${DEFAULT_PASSWORD} -passout pass:${DEFAULT_PASSWORD}
log "Create client PKCS"
openssl pkcs12 -export -in ${OUTPUT_DIR}/client.crt -inkey ${OUTPUT_DIR}/client.key -out ${OUTPUT_DIR}/client.p12 -chain -name client -CAfile ${OUTPUT_DIR}/root.pem -caname rootclient -passin pass:${DEFAULT_PASSWORD} -passout pass:${DEFAULT_PASSWORD}
# ----------------------

# ----------------------
log "Create server keystore"
keytool -importkeystore -deststorepass ${DEFAULT_PASSWORD} -destkeypass ${DEFAULT_PASSWORD} -destkeystore ${OUTPUT_DIR}/server.jks \
        -srckeystore ${OUTPUT_DIR}/server.p12 -srcstoretype PKCS12 -srcstorepass ${DEFAULT_PASSWORD} \
        -alias server -deststoretype PKCS12
log "Create client keystore"
keytool -importkeystore -deststorepass ${DEFAULT_PASSWORD} -destkeypass ${DEFAULT_PASSWORD} -destkeystore ${OUTPUT_DIR}/client.jks \
        -srckeystore ${OUTPUT_DIR}/client.p12 -srcstoretype PKCS12 -srcstorepass ${DEFAULT_PASSWORD} \
        -alias client -deststoretype PKCS12
# ----------------------

# ----------------------
log "Create server truststore"
keytool -import -v -alias root -file ${OUTPUT_DIR}/root.pem -keystore ${OUTPUT_DIR}/client_truststore.jks -deststorepass ${DEFAULT_PASSWORD} -noprompt
log "Create client truststore"
keytool -import -v -alias root -file ${OUTPUT_DIR}/root.pem -keystore ${OUTPUT_DIR}/server_truststore.jks -deststorepass ${DEFAULT_PASSWORD} -noprompt
# ----------------------

log "Create JWT key pair"
ssh-keygen -t rsa -b 2048 -m PEM -f ${OUTPUT_DIR}/jwt.key -N ${DEFAULT_PASSWORD}
log "Create JWT CA"
openssl req -x509 -new -nodes -key ${OUTPUT_DIR}/jwt.key -sha256 -days 1825 -out ${OUTPUT_DIR}/jwt.pem -subj "/C=UK/ST=Avon/L=Bath/O=Pay360/CN=jwtCA.pay360.com" -passin pass:${DEFAULT_PASSWORD}
log "Create JWT CSR"
openssl req -new -key ${OUTPUT_DIR}/jwt.key -out ${OUTPUT_DIR}/jwt.csr -subj "/C=UK/ST=Avon/L=Bath/O=Pay360/CN=jwt.pay360.com" -passin pass:${DEFAULT_PASSWORD}
log "Sign JWT Cert"
openssl x509 -req -in ${OUTPUT_DIR}/jwt.csr -CA ${OUTPUT_DIR}/jwt.pem -CAkey ${OUTPUT_DIR}/jwt.key -CAcreateserial -out ${OUTPUT_DIR}/jwt.crt -days 1825 -sha256 -extfile ${WORKING_DIR}/jwt.cert.config  -passin pass:${DEFAULT_PASSWORD}
log "Create JWT PKS12"
openssl pkcs12 -export -in ${OUTPUT_DIR}/jwt.crt -inkey ${OUTPUT_DIR}/jwt.key -out ${OUTPUT_DIR}/jwt.p12 -chain -name jwt -CAfile ${OUTPUT_DIR}/jwt.pem -caname jwt -passin pass:${DEFAULT_PASSWORD} -passout pass:${DEFAULT_PASSWORD}

log "Import JWT PKS12 into server keystore"
keytool -importkeystore -deststorepass ${DEFAULT_PASSWORD} -destkeypass ${DEFAULT_PASSWORD} -destkeystore ${OUTPUT_DIR}/server.jks \
        -srckeystore ${OUTPUT_DIR}/jwt.p12 -srcstoretype PKCS12 -srcstorepass ${DEFAULT_PASSWORD} \
        -alias jwt -deststoretype PKCS12

log "Create JWT PKS12 into keystore"
keytool -importkeystore -deststorepass ${DEFAULT_PASSWORD} -destkeypass ${DEFAULT_PASSWORD} -destkeystore ${OUTPUT_DIR}/jwt.jks \
    -srckeystore ${OUTPUT_DIR}/jwt.p12 -srcstoretype PKCS12 -srcstorepass ${DEFAULT_PASSWORD} \
    -alias jwt -deststoretype PKCS12

log "Import JWT PEM into client trust"
keytool -import -v -alias jwt -file ${OUTPUT_DIR}/jwt.pem -keystore ${OUTPUT_DIR}/client_truststore.jks -deststorepass ${DEFAULT_PASSWORD} -noprompt