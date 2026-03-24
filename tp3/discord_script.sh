#!/bin/bash

AIDE_WEBHOOK_URL=https://discord.com/api/webhooks/1485909255260209196/fHdiqNckVyZlfxOqSUp6bRUxYqan-o81WeE_VVYAk89ZMcoeD9RNLlw5-YitQ9Z7xinF
# on lance le check
/usr/sbin/aide --check
# on vérifie c'est quoi l'exit code de la commande
EXIT_CODE=$?

# si c'est 4 ça veut dire qu'il y a eu une modif dans un file
if [ $EXIT_CODE -eq 4 ]; then
        curl -H "Content-Type: application/json" \
             -X POST \
             -d '{"content": "**Alerte Sec** : AIDE à détecté modifs sur des fichiers critiques !!!!"}' \
             "$AIDE_WEBHOOK_URL"
fi
