# Vault Unsealer for Docker

Unseal a [vault](https://www.vaultproject.io) with a docker container given only environment variables.

[![Foo](https://img.shields.io/docker/pulls/blockloop/vault-unseal.svg)](https://hub.docker.com/r/blockloop/vault-unseal/)

This project was initially created to run as a kubernetes job to unseal a vault within the same cluster. This gives you the ability to pass env variables to a docker container and have it unseal a vault with the given keys. This image is based on the official vault image so many of the variables are the same. 

`VAULT_ADDR` - the location of the vault server. You must specify the protocol (i.e. VAULT_ADDR=http://vault:8200)

`VAULT_UNSEAL_KEY_X` - this is the format of the unseal keys. In Kubernetes these are stored in a secret store and mounted to the Vault Unsealer Job as environment variables.

This container will loop up to 15 times, as many times as it can until vault is either unsealed or it returns an error. Each time it loops it checks the vault status and then, if the vault is still sealed, it runs `unseal` with the next key, or if it is unsealed, it exists 0. 

## Instructions

1. Set vault key environment variables  as `VAULT_UNSEAL_KEY_1`, `VAULT_UNSEAL_KEY_2`, etc. 
2. Set vault key address as `VAULT_ADDR`
3. Optionally set `VAULT_SKIP_VERIFY` to 1. 
4. Check the [vault docs](https://www.vaultproject.io/docs/commands/environment.html) on environment variables to see all of your options. 
5. Run the container and watch it unseal your vault.
