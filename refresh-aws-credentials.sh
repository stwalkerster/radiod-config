#!/bin/bash

touch vault-response.json private_key.pem
chmod go= vault-response.json private_key.pem
vault write -format=json pki_iam/issue/radiod-bot ttl=90d common_name=radiod-bot > vault-response.json
cat vault-response.json | jq -r .data.certificate > certificate.pem
cat vault-response.json | jq -r .data.issuing_ca > issuing_ca.pem
cat vault-response.json | jq -r .data.private_key > private_key.pem
rm vault-response.json
