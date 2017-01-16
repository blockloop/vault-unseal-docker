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

## Example Kubernetes Config

```yaml
---
apiVersion: v1
kind: Secret
metadata:
  name: vault-secret-config-s3
  namespace: default
type: Opaque
data:
  access_key: <base64 encoded s3 access key>
  secret_key: <base64 encoded s3 secret key>
  unseal_key_1: <base64 encoded unseal key 1>
  unseal_key_2: <base64 encoded unseal key 2>
  unseal_key_3: <base64 encoded unseal key 3>
  unseal_key_4: <base64 encoded unseal key 4>
  unseal_key_5: <base64 encoded unseal key 5>
  root_token: <base64 encoded root token>

---
apiVersion: v1
kind: ConfigMap
metadata:
  name: vault-config-file
data:
  config.hcl: |-
    backend "s3" {}
    listener "tcp" {
      address = "0.0.0.0:8200"
      tls_disable = 1
    }

---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: vault
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: vault
    spec:
      volumes:
      - name: configmap
        configMap:
          name: vault-config-file
      containers:
      - name: vault
        image: vault:0.6.4
        args: ["server"]
        securityContext:
          capabilities:
            add:
              - IPC_LOCK
        ports:
        - containerPort: 8200
        imagePullPolicy: Always
        volumeMounts:
        - mountPath: /vault/config
          name: configmap
        env:
          - name: VAULT_ADDR
            value: http://127.0.0.1:8200
          - name: VAULT_SKIP_VERIFY
            value: "1"
          - name: AWS_S3_BUCKET
            value: <my bucket name>
          - name: AWS_DEFAULT_REGION
            value: <my region>
          - name: AWS_ACCESS_KEY_ID
            valueFrom:
              secretKeyRef:
                name: vault-secret-config-s3
                key: access_key
          - name: AWS_SECRET_ACCESS_KEY
            valueFrom:
              secretKeyRef:
                name: vault-secret-config-s3
                key: secret_key
          - name: VAULT_TOKEN
            valueFrom:
              secretKeyRef:
                name: vault-secret-config-s3
                key: root_token

---
apiVersion: v1
kind: Service
metadata:
  creationTimestamp: null
  labels:
    app: vault
  name: vault
spec:
  ports:
  - port: 8200
    protocol: TCP
    targetPort: 8200
  selector:
    app: vault
  sessionAffinity: None
  type: ClusterIP


---
apiVersion: batch/v1
kind: Job
metadata:
  name: vault-unseal
spec:
  template:
    metadata:
      name: vault-unseal
    spec:
      restartPolicy: OnFailure
      containers:
      - name: vault-unseal
        image: blockloop/vault-unseal
        env:
          - name: VAULT_ADDR
            value: http://vault:8200
          - name: VAULT_SKIP_VERIFY
            value: "1"
          - name: VAULT_UNSEAL_KEY_1
            valueFrom:
              secretKeyRef:
                name: vault-secret-config-s3
                key: unseal_key_1
          - name: VAULT_UNSEAL_KEY_2
            valueFrom:
              secretKeyRef:
                name: vault-secret-config-s3
                key: unseal_key_2
          - name: VAULT_UNSEAL_KEY_3
            valueFrom:
              secretKeyRef:
                name: vault-secret-config-s3
                key: unseal_key_3

```