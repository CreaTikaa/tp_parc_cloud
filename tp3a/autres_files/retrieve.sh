#!/bin/bash

VAULT_NAME="nomdegolmonsamere"
SECRET_NAME="my-very-secret-secret"

# demande token id
TOKEN=$(curl -s 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fvault.azure.net' -H Metadata:true | jq -r '.access_token')

# demande secret a l'api avec token en bearer
SECRET_VALUE=$(curl -s -H "Authorization: Bearer $TOKEN" "https://${VAULT_NAME}.vault.azure.net/secrets/${SECRET_NAME}?api-version=7.4" | jq -r '.value')

echo "$SECRET_VALUE"
