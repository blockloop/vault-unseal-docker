#!/bin/bash

for i in {1..20}; do
    # https://github.com/hashicorp/vault/blob/c44f1c9817955d4c7cd5822a19fb492e1c2d0c54/command/status.go#L107
    # code reflects the seal status (0 unsealed, 2 sealed, 1 error).
    vault status;
    st=$?

    if [ $st -eq 0 ]; then
        echo "vault is unsealed"
        exit 0
    elif [ $st -eq 2 ]; then
        echo "vault is sealed"
        echo "unsealing with key $i"
        v="VAULT_UNSEAL_KEY_$i"
        v="${!v}"

        if [ -z "$v" ]; then
            echo "ran out of vault uneal keys at $i (VAULT_UNSEAL_KEY_$i is empty). terminating..."
            exit 1
        fi

        vault useal "$v" > /dev/null
        code=$?
        if [ $? -ne 0 ] ; then
            echo "unseal returned a bad exit code ($code). terminating..."
            exit $code
        fi

    elif [ $st -eq 1 ]; then
        echo "vault returned an error"
        exit 1
    fi
done
