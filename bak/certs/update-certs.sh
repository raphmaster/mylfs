#!/bin/bash

URL=http://anduin.linuxfromscratch.org/BLFS/other/certdata.txt
rm -f certdata.txt
wget $URL
make-ca.sh
unset URL
SSLDIR=/etc/ssl
remove-expired-certs.sh certs
install -d ${SSLDIR}/certs
cp -v certs/*.pem ${SSLDIR}/certs
c_rehash
install BLFS-ca-bundle*.crt ${SSLDIR}/ca-bundle.crt
ln -sfv ../ca-bundle.crt ${SSLDIR}/certs/ca-certificates.crt
unset SSLDIR
rm -rv certs BLFS-ca-bundle*