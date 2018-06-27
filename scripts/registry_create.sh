#!/bin/bash
#zapis ip maszyny
sudo echo subjectAltName=IP:$1 /etc/ssl/openssl.cnf

#utworzenie certyfikatu tls
openssl req -newkey rsa:4096 -nodes -sha256 -keyout /certs/my-registry.key -x509 -days 365 -out /certs/my-registry.crt -subj /CN=$1

sudo docker run -d -p 5000:5000 --restart=always --name registry \
  -v /certs:/certs \
  -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/my-registry.crt \
  -e REGISTRY_HTTP_TLS_KEY=/certs/my-registry.key \
  registry:2
