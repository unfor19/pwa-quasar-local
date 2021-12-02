#!/usr/bin/env bash

set -e
set -o pipefail


# trap ctrl-c and call ctrl_c()
trap ctrl_c INT
ctrl_c() {
    msg_log "Interuppted with CTRL+C"
    exit 0
}


msg_error(){
    local msg="$1"
    echo -e "[ERROR] $(date) :: $msg"
    export DEBUG=1
    exit 1
}


msg_log(){
    local msg="$1"
    echo -e "[LOG] $(date) :: $msg"
}

wait_for_endpoints(){
    declare endpoints=($@)
    for endpoint in "${endpoints[@]}"; do
        counter=1
        while [[ $(curl --cacert "$_DOMAIN_CRT_PATH" -s -o /dev/null -w ''%{http_code}'' "$endpoint") != "200" ]]; do 
            counter=$((counter+1))
            msg_log "WAIT FOR ENDPOINTS :: Waiting for - ${endpoint}"
            if [[ $counter -gt "$_WAIT_MAX_ATTEMPTS" ]]; then
                msg_error "WAIT FOR ENDPOINTS :: Not healthy - ${endpoint}"
            fi
            sleep "$_WAIT_INTERVAL"
        done
        msg_log "WAIT FOR ENDPOINTS :: Healthy endpoint - ${endpoint}"
    done
}



_WAIT_INTERVAL="${WAIT_INTERVAL:-"5"}"
_WAIT_MAX_ATTEMPTS="${WAIT_MAX_ATTEMPTS:-"100"}"

_SKIP_DNSMASQ="${SKIP_DNSMASQ:-"false"}"
_DNSMASQ_CONF_PATH="${DNSMASQ_CONF_PATH:-"/etc/dnsmasq.conf"}"
_TARGET_FQDN="${1:-"$TARGET_FQDN"}"
_TARGET_IP_ADDRESS="${2:-"$TARGET_IP_ADDRESS"}"
_DEV_LOGS_PATH="${DEV_LOGS_PATH:-"./.dev.logs"}"

[[ -z "$_TARGET_FQDN" ]] && msg_error "Must provide TARGET_FQDN"
[[ -z "$_TARGET_IP_ADDRESS" ]] && msg_error "Must provide TARGET_IP_ADDRESS"

_DOMAIN_CRT_PATH="${DOMAIN_CRT_PATH:-".certs/${_TARGET_FQDN}.crt"}"

if [[ "$_SKIP_DNSMASQ" != "true" ]]; then
    msg_log "Starting dnsmasq"
    echo "address=/${_TARGET_FQDN}/${_TARGET_IP_ADDRESS}" >> "${_DNSMASQ_CONF_PATH}"
    dnsmasq -q -k --pid-file &
    dnsmasq --test
fi


yarn serve &

wait_for_endpoints "https://${_TARGET_FQDN}"

msg_log "macOS/Linux/WSL2 - Use the CA certificate ${_TARGET_FQDN}.crt"
msg_log "Android - Use DER CA certificate ${_TARGET_FQDN}.der.crt"
msg_log "App HTTPS URL: https://${_TARGET_FQDN}"

wait # keeps dev server running
