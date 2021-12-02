#!/usr/bin/env bash

set -e
set -o pipefail


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


_SKIP_DNSMASQ="${SKIP_DNSMASQ:-"false"}"
_DNSMASQ_CONF_PATH="${DNSMASQ_CONF_PATH:-"/etc/dnsmasq.conf"}"
_TARGET_FQDN="${1:-"$TARGET_FQDN"}"
_TARGET_IP_ADDRESS="${2:-"$TARGET_IP_ADDRESS"}"
_DEV_LOGS_PATH="${DEV_LOGS_PATH:-"./.dev.logs"}"

[[ -z "$_TARGET_FQDN" ]] && msg_error "Must provide TARGET_FQDN"
[[ -z "$_TARGET_IP_ADDRESS" ]] && msg_error "Must provide TARGET_IP_ADDRESS"

if [[ "$_SKIP_DNSMASQ" != "true" ]]; then
    msg_log "Starting dnsmasq"
    echo "address=/${_TARGET_FQDN}/${_TARGET_IP_ADDRESS}" >> "${_DNSMASQ_CONF_PATH}"
    dnsmasq --log-facility="${_DEV_LOGS_PATH}"
    dnsmasq --test
fi


yarn serve
