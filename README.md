# Private Registry with Self-signed Certificate

Setup a private registry with the self-signed certificate. The project is rely on the powerful tool [`mkcert`](https://github.com/FiloSottile/mkcert), please make sure you had installed it before the project.

## How to setup
1. Generate certificate authority (CA) via `mkcert`

    ```bash
    mkdir -p cert

    mkcert -install && sudo update-ca-certificates
    mkcert -key-file cert/key.pem -cert-file cert/cert.pem -client registry.example.com
    cp $(mkcert -CAROOT)/rootCA.pem cert/ca.crt
    ```

2. Generate htpasswd authentication via `httpd`

    ```bash
    mkdir -p auth

    docker run --rm --entrypoint htpasswd httpd:2 -Bbn guest guesspassword > auth/htpasswd
    ```

3. Activate registry service

    ```bash
    echo "REGISTRY_PORT=" > .env
    echo "REGISTRY_DATA_DIR=" >> .env
    docker-compose up -d --force-recreate
    ```

4. Prepare certificate for clients

    ```bash
    cp -r cert registry.example.com
    zip -q -r cert_registry.example.com.zip registry.example.com
    ```

5. Install certificate

    ```bash
    mkdir -p /etc/docker/certs.d
    unzip cert_registry.example.com.zip -d /etc/docker/certs.d
    ```

6. Push image

    ```bash
    docker login registry.example.com -u guest -p guesspassword

    docker pull busybox
    docker tag busybox:latest registry.example.com/busybox:latest
    docker push registry.example.com/busybox:latest

    docker logout registry.example.com
    ```

7. Pull image

    ```bash
    docker login registry.example.com -u guest -p guesspassword

    docker pull registry.example.com/busybox:latest
    docker tag registry.example.com/busybox:latest busybox:latest
    docker rmi registry.example.com/busybox:latest

    docker logout registry.example.com
    ```
