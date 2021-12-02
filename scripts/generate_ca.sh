#!/usr/bin/env bash

set -e
set -o pipefail

# Requires - openssl
# Based on: https://android.stackexchange.com/a/238859/363870

# IMPORTANT: choose ".test" as a suffix
# ".dev" and ".local" are reserved
_DOMAIN="${1:-"$DOMAIN"}"
_SUFFIX="${SUFFIX:-"test"}"
if [[ -z "$_DOMAIN" ]]; then
    echo "[ERR] Required variable: DOMAIN"
fi


_CERTS_DIR_PATH="${CERTS_DIR_PATH:-"awesome-pwa/.certs"}"
mkdir -p "$_CERTS_DIR_PATH"
pushd "$_CERTS_DIR_PATH" || exit


_SKIP_ROOTCA_KEY="${SKIP_ROOT_CA_KEY:-"false"}"
_ROOTCA_KEY_PATH="${ROOTCA_KEY_PATH:-"rootCA.key"}"
_ROOTCA_PEM_PATH="${CERT_OUT_PATH:-"rootCA.pem"}"
_ROOTCA_CERT_EXPIRE_DAYS="${ROOTCA_CERT_EXPIRE_DAYS:-"3650"}"
_X509V3_CONFIG_PATH="${X509V3_CONFIG_PATH:-"x509v3_config.ext"}"

_FQDN="${FQDN:-"${_DOMAIN}.${_SUFFIX}"}"
_DOMAIN_CRT_PATH="${DOMAIN_CRT_PATH:-"${_FQDN}.crt"}"
_DOMAIN_CRT_DER_PATH="${DOMAIN_CRT_DER_PATH:-"${_FQDN}.der.crt"}"
_DOMAIN_CERT_EXPIRE_DAYS="${DOMAIN_CERT_EXPIRE_DAYS:-"3650"}"

### Root CA

if [[ "$_SKIP_ROOTCA_KEY" != "true" ]]; then
  if [[ ! -f "$_ROOTCA_KEY_PATH" ]]; then
    echo "Generating private key for rootCA"
    openssl genrsa -out "$_ROOTCA_KEY_PATH" 2048
  fi
  if [[ ! -f "$_ROOTCA_PEM_PATH" ]]; then
    echo "Generating the rootCA Certificate ${_ROOTCA_PEM_PATH} and signing it with the private key ${_ROOTCA_KEY_PATH}"
    openssl req -new \
    -days 3650 \
    -key "$_ROOTCA_KEY_PATH" \
    -out "$_ROOTCA_PEM_PATH" \
    -subj "/CN=${_FQDN}/"
  fi
fi


### Domain

# https://www.openssl.org/docs/manmaster/man5/x509v3_config.html
cat > "$_X509V3_CONFIG_PATH" << EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:true
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names
[alt_names]
DNS.1 = ${_FQDN}
EOF


echo "Applicant generates CSR with ${_ROOTCA_PEM_PATH}, though no CSR file will be generated"
echo "rootCA signs the certifcate with ${_ROOTCA_KEY_PATH}"
echo "rootCA generates the CA certificate ${_DOMAIN_CRT_PATH}"
# -extfile is for Android, as x509 needs to be CA:true and include DNS name
openssl x509 -req \
  -days 3650 \
  -in "$_ROOTCA_PEM_PATH" \
  -signkey "$_ROOTCA_KEY_PATH" \
  -extfile "$_X509V3_CONFIG_PATH" \
  -out "$_DOMAIN_CRT_PATH"


# Convert the 'crt' certificate to DER format
echo "Converting ${_DOMAIN_CRT_DER_PATH} to DER format for ${_FQDN}"
openssl x509 -inform PEM -outform DER -in "$_DOMAIN_CRT_PATH" -out "$_DOMAIN_CRT_DER_PATH"

echo "

  _   _                   
 | | | |___ __ _ __ _ ___ 
 | |_| (_-</ _\` / _\` / -_)
  \___//__/\__,_\__, \___|
                |___/     


### Output Files

           rootCA Certificate: ${_ROOTCA_PEM_PATH}
           rootCA Private Key: ${_ROOTCA_KEY_PATH}
 Local Machine CA Certificate: ${_DOMAIN_CRT_PATH}    
Android Device CA Certificate: ${_DOMAIN_CRT_DER_PATH}


### Use in quasar.config.js

devServer: {
  https: {
    cert: '${_DOMAIN_CRT_PATH}',
    key: '${_ROOTCA_KEY_PATH}',
  },
  port: 443,
  open: false
},


### Install ${_DOMAIN_CRT_PATH} certificate on local machine

- macOS
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain \"${_DOMAIN_CRT_PATH}\"


### Install ${_DOMAIN_CRT_DER_PATH} certificate on Android device    

Local Machine > Upload ${_DOMAIN_CRT_DER_PATH} to Google Drive
On Android    > Download ${_DOMAIN_CRT_DER_PATH} to local storage
On Android    > Settings > CA Certificate > Install downloaded certificate - \"${_DOMAIN_CRT_DER_PATH}\"

Why DER? See https://knowledge.digicert.com/quovadis/ssl-certificates/ssl-general-topics/what-is-der-format.html
Quoting: \"..DER is often used with Java platforms.\" 
Android is based on Java, so it makes sense to use DER
"

popd || exit
