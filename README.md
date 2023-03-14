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

8. Fetch repository infomation

    ```bash
    # list repository
    curl --user <username>:<user_passwd> https://registry.example.com/v2/_catalog

    # fetch list of tags, e.g., python
    curl --user <username>:<user_passwd> https://registry.example.com/v2/python/tags/list

    # fetch manifests of image, e.g., python:latest
    curl --user <username>:<user_passwd> https://registry.example.com/v2/python/manifests/latest
    ```

## Reference
- [Deploy a registry server](https://docs.docker.com/registry/deploying/)

- [How To Pass Username & Password to Private Docker Registry For "htpasswd" authentication](https://stackoverflow.com/questions/56522039/how-to-pass-username-password-to-private-docker-registry-for-htpasswd-authen)

- [使用 Private Registry 分享 image - iT 邦幫忙::一起幫忙解決難題，拯救 IT 人的一天](https://ithelp.ithome.com.tw/articles/10248854)

- [docker-registry-ui/simple.yml at main · Joxit/docker-registry-ui](https://github.com/Joxit/docker-registry-ui/blob/main/examples/ui-as-standalone/registry-config/simple.yml)

- [How to delete images from a private docker registry?](https://stackoverflow.com/questions/25436742/how-to-delete-images-from-a-private-docker-registry)
