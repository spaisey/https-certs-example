#!/usr/bin/env bash
#!/usr/bin/env bash

export WORKING_DIR=`dirname $0`
export OUTPUT_DIR="${WORKING_DIR}/out"
export DEFAULT_PASSWORD="123456"
echo "Working directory: ${WORKING_DIR}"
echo "Output directory: ${OUTPUT_DIR}"

rm -rf ${OUTPUT_DIR}
mkdir ${OUTPUT_DIR}

echo "Generate Private Key"
openssl genrsa -des3 -out ${OUTPUT_DIR}/server.key -passout pass:${DEFAULT_PASSWORD} 2048

echo "Create CSR"
openssl req -new -key ${OUTPUT_DIR}/server.key -out ${OUTPUT_DIR}/server.csr -subj "/C=UK/ST=Avon/L=Bath/O=Pay360/CN=rootcsr" -passin pass:${DEFAULT_PASSWORD}

echo "Generate Root Certificate"
openssl req -x509 -new -nodes -key ${OUTPUT_DIR}/server.key -sha256 -days 1825 -out ${OUTPUT_DIR}/server.pem -subj "/C=UK/ST=Avon/L=Bath/O=Pay360/CN=rootcert" -passin pass:${DEFAULT_PASSWORD}

echo "Create the issued certificate"
openssl x509 -req -in ${OUTPUT_DIR}/server.csr -CA ${OUTPUT_DIR}/server.pem -CAkey ${OUTPUT_DIR}/server.key -CAcreateserial -out ${OUTPUT_DIR}/server.crt -days 1825 -sha256 -extfile ${WORKING_DIR}/server.cert.config  -passin pass:${DEFAULT_PASSWORD}

echo "Create PKSC12"
openssl pkcs12 -export -in ${OUTPUT_DIR}/server.crt -inkey ${OUTPUT_DIR}/server.key -out ${OUTPUT_DIR}/server.p12 -chain -name server -CAfile ${OUTPUT_DIR}/server.pem -caname rootserver -passin pass:${DEFAULT_PASSWORD} -passout pass:${DEFAULT_PASSWORD}

echo "Create keystore"
keytool -importkeystore -deststorepass ${DEFAULT_PASSWORD} -destkeypass ${DEFAULT_PASSWORD} -destkeystore ${OUTPUT_DIR}/server.jks \
        -srckeystore ${OUTPUT_DIR}/server.p12 -srcstoretype PKCS12 -srcstorepass ${DEFAULT_PASSWORD} \
        -alias server -deststoretype PKCS12

echo "Create truststore"
keytool -import -v -alias server -file ${OUTPUT_DIR}/server.pem -keystore ${OUTPUT_DIR}/server_truststore.jks -deststorepass ${DEFAULT_PASSWORD} -noprompt