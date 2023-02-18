#!/usr/bin/env bash

# Name: generate_self_signed_ca_certificate.sh
# Description: Generate a self-signed CA rootKey, rootCA, certificate per domain (CNAME) for both pem and DER formats
# Author: Meir Gabay (unfor19)

set -e
set -o pipefail


### Functions
msg_error(){
    local msg="$1"
    echo -e "[ERROR] $(date) :: $msg"
    exit 1
}


msg_log(){
    local msg="$1"
    echo -e "[LOG] $(date) :: $msg"
}

# IMPORTANT: choose ".test" as a suffix
# ".dev" and ".local" are reserved
_DOMAIN="${1:-"$DOMAIN"}"
_SUFFIX="${SUFFIX:-"test"}"
if [[ -z "$_DOMAIN" ]]; then
  msg_error "Required variable: DOMAIN"
fi
_FQDN="${FQDN:-"${_DOMAIN}.${_SUFFIX}"}"


_CERTS_DIR_PATH="${CERTS_DIR_PATH:-".certs"}"
msg_log "Creating the directory ${_CERTS_DIR_PATH} ..."
mkdir -p "$_CERTS_DIR_PATH"
pushd "$_CERTS_DIR_PATH" || exit

_SKIP_ROOTCA_KEY="${SKIP_ROOT_CA_KEY:-"false"}"
_ROOTCA_KEY_PATH="${ROOTCA_KEY_PATH:-"rootCA.key"}"
_ROOTCA_PEM_PATH="${ROOTCA_PEM_PATH:-"rootCA.pem"}"
_ROOTCA_CERT_EXPIRE_DAYS="${ROOTCA_CERT_EXPIRE_DAYS:-"3650"}"
_X509V3_CONFIG_PATH="${X509V3_CONFIG_PATH:-"x509v3_config.ext"}"

_DOMAIN_CRT_PATH="${DOMAIN_CRT_PATH:-"${_FQDN}.crt"}"
_DOMAIN_CRT_DER_PATH="${DOMAIN_CRT_DER_PATH:-"${_FQDN}.der.crt"}"
_DOMAIN_CERT_EXPIRE_DAYS="${DOMAIN_CERT_EXPIRE_DAYS:-"3650"}"

msg_log "Print values:"
echo "
############################################################
         CERTS_DIR_PATH: '${_CERTS_DIR_PATH}'
       SKIP_ROOT_CA_KEY: '${_SKIP_ROOTCA_KEY}'
        ROOTCA_KEY_PATH: '${_ROOTCA_KEY_PATH}'
        ROOTCA_PEM_PATH: '${_ROOTCA_PEM_PATH}'
ROOTCA_CERT_EXPIRE_DAYS: '${_ROOTCA_CERT_EXPIRE_DAYS}'
     X509V3_CONFIG_PATH: '${_X509V3_CONFIG_PATH}'
        DOMAIN_CRT_PATH: '${_DOMAIN_CRT_PATH}'
############################################################
"

### Root CA

if [[ "$_SKIP_ROOTCA_KEY" != "true" ]]; then
  if [[ ! -f "$_ROOTCA_KEY_PATH" ]]; then
    msg_log "Generating private key for rootCA"
    # 2048 bit key is hardcoded no purpose - https://expeditedsecurity.com/blog/measuring-ssl-rsa-keys/
    openssl genrsa -out "$_ROOTCA_KEY_PATH" 2048
  fi
  if [[ ! -f "$_ROOTCA_PEM_PATH" ]]; then
    msg_log "Generating the rootCA Certificate ${_ROOTCA_PEM_PATH} and signing it with the private key ${_ROOTCA_KEY_PATH}"
    openssl req -new \
    -days "$_ROOTCA_CERT_EXPIRE_DAYS" \
    -key "$_ROOTCA_KEY_PATH" \
    -out "$_ROOTCA_PEM_PATH" \
    -subj "/C=IL/CN=${_FQDN}/O=rootCaOrg"
  fi
fi


### Domain

# https://www.openssl.org/docs/manmaster/man5/x509v3_config.html
cat > "$_X509V3_CONFIG_PATH" << EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=critical,CA:true
keyUsage=critical,digitalSignature,nonRepudiation,cRLSign,keyCertSign
subjectAltName=@alt_names
issuerAltName=issuer:copy
subjectKeyIdentifier=hash
[alt_names]
DNS.1=${_FQDN}
EOF


msg_log "Applicant generates CSR with ${_ROOTCA_PEM_PATH}, though no CSR file will be generated"
msg_log "rootCA signs the certifcate with ${_ROOTCA_KEY_PATH}"
msg_log "rootCA generates the CA certificate ${_DOMAIN_CRT_PATH}"
openssl x509 -req \
  -days "$_ROOTCA_CERT_EXPIRE_DAYS" \
  -in "$_ROOTCA_PEM_PATH" \
  -signkey "$_ROOTCA_KEY_PATH" \
  -extfile "$_X509V3_CONFIG_PATH" \
  -out "$_DOMAIN_CRT_PATH"


# Convert the 'crt' certificate to DER format for Android
msg_log "Converting ${_DOMAIN_CRT_DER_PATH} to DER format for ${_FQDN}"
openssl x509 -inform PEM -outform DER -in "$_DOMAIN_CRT_PATH" -out "$_DOMAIN_CRT_DER_PATH"

echo "

  _   _                   
 | | | |___ __ _ __ _ ___ 
 | |_| (_-</ _\` / _\` / -_)
  \___//__/\__,_\__, \___|
                |___/     


### Output Files

           rootCA Certificate: ${_CERTS_DIR_PATH}/${_ROOTCA_PEM_PATH}
           rootCA Private Key: ${_CERTS_DIR_PATH}/${_ROOTCA_KEY_PATH}
 Local Machine CA Certificate: ${_CERTS_DIR_PATH}/${_DOMAIN_CRT_PATH}    
Android Device CA Certificate: ${_CERTS_DIR_PATH}/${_DOMAIN_CRT_DER_PATH}


### Use in quasar.config.js

devServer: {
  https: {
    cert: '${_CERTS_DIR_PATH}/${_DOMAIN_CRT_PATH}',
    key: '${_CERTS_DIR_PATH}/${_ROOTCA_KEY_PATH}',
  },
  port: 443,
  open: false
},


### Install the certificate '${_DOMAIN_CRT_PATH}' on local machine

- macOS
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain \"${_CERTS_DIR_PATH}/${_DOMAIN_CRT_PATH}\"


### Install the certificate '${_DOMAIN_CRT_DER_PATH}' on Android device    

Local Machine > Upload '${_DOMAIN_CRT_DER_PATH}' to Google Drive
On Android    > Download '${_DOMAIN_CRT_DER_PATH}' to local storage
On Android    > Settings > CA Certificate > Install downloaded certificate - '${_DOMAIN_CRT_DER_PATH}'

Why DER? See https://knowledge.digicert.com/quovadis/ssl-certificates/ssl-general-topics/what-is-der-format.html
Quoting: \"..DER is often used with Java platforms.\" 
Android is based on Java, so it makes sense to use DER

### Lint and verify certificate

Lint the output certificate '${_DOMAIN_CRT_PATH}' by copy-pasting its value to - https://crt.sh/lintcert
"

popd || exit
