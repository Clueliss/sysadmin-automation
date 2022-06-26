#!/bin/bash

set -euo pipefail

hash_algo=sha256
private_key=/etc/pki/dkms/dkms.key
x509_cert=/etc/pki/dkms/dkms.der

if "/usr/src/kernels/${1}/scripts/sign-file" "${hash_algo}" "${private_key}" "${x509_cert}" "${2}"; then
    echo "Successfully signed newly-built module ${2}." 1>&2
    exit 0
else
    echo "Error signing module ${2}." 1>&2
    exit 1
fi
