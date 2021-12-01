#!/usr/bin/env bash

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
_ROOTCA_KEY_PATH="${ROOTCA_KEY_PATH:-"CA.key"}"
_ROOTCA_PEM_PATH="${CERT_OUT_PATH:-"CA.pem"}"
_ROOTCA_CERT_EXPIRE_DAYS="${ROOTCA_CERT_EXPIRE_DAYS:-"3650"}"
_X509V3_CONFIG_PATH="${X509V3_CONFIG_PATH:-"x509v3_config.ext"}"
_DOMAIN_CRT_PATH="${DOMAIN_CRT_PATH:-"CA.crt"}"
_DOMAIN_CRT_DER_PATH="${DOMAIN_CRT_DER_PATH:-"CA.der.crt"}"
_DOMAIN_CERT_EXPIRE_DAYS="${DOMAIN_CERT_EXPIRE_DAYS:-"3650"}"


# https://www.openssl.org/docs/manmaster/man5/x509v3_config.html
cat > "$_X509V3_CONFIG_PATH" << EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:true
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names
[alt_names]
DNS.1 = ${_DOMAIN}.${_SUFFIX}
EOF


### Root CA
if [[ "$_SKIP_ROOTCA_KEY" != "true" ]]; then
  if [[ ! -f "$_ROOTCA_KEY_PATH" ]]; then
    echo "Generating private key for rootCA"
    openssl genrsa -out "$_ROOTCA_KEY_PATH" 2048
  fi
  if [[ ! -f "$_ROOTCA_PEM_PATH" ]]; then
    openssl req -new -days 3650 -key "CA.key" -out "CA.pem"
    echo "Generated the Root Certificate - ${_ROOTCA_PEM_PATH} with the private key ${_ROOTCA_KEY_PATH}"
  fi
fi


echo "Generating certificate for ${_DOMAIN}"
# Create a certificate for ${_DOMAIN}.${_SUFFIX}
# -extfile is for Android, as x509 needs to be CA:true and include DNS name
openssl x509 -req -days 3650 -in "CA.pem" -signkey "CA.key" -extfile "x509v3_config.ext" -out CA.crt


# Convert the 'crt' certificate to DER format
echo "Converting CA.crt to DER format for ${_DOMAIN}"
openssl x509 -inform PEM -outform DER -in "CA.crt" -out "CA.der.crt"
# CA.der.crt - this one should be installed on your Android device
# Upload this file to Google Drive, and then download it on your device
# On Android> Settings > CA Certificate > Install downloaded certificate - CA.der.crt


# Install the certificate on your macOS
# sudo security add-trusted-cert -d -r trustRoot -k "/Library/Keychains/System.keychain" "CA.crt"

popd || exit
