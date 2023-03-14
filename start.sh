#/!bin/bash
HOST_IP=`hostname -I | awk '{print $1}'`
DOMAIN_NAME="registry.${HOST_IP}.nip.io"
PORT=5001
REGISTRY_NAME="${DOMAIN_NAME}:${PORT}"
DEFAULT_USERNAME=admin
DEFAULT_PASSWORD=defaultP@ssw0rd

read -r -p "Please input the domain name of registry: (default: ${REGISTRY_NAME}) " input_registry_name
read -r -p "Please input the username: (default: ${DEFAULT_USERNAME}) " input_default_username
read -r -p "Please input the password: (default: ${DEFAULT_PASSWORD}) " input_default_password

INPUT_REGISTRY_NAME="${input_registry_name:-$REGISTRY_NAME}:"
export REGISTRY_NAME="${INPUT_REGISTRY_NAME%%:}"
export DOMAIN_NAME="${INPUT_REGISTRY_NAME%%:*}"
export PORT=`echo ${INPUT_REGISTRY_NAME#*:} | cut -d : -f 1`
export DEFAULT_USERNAME="${input_default_username:-$DEFAULT_USERNAME}"
export DEFAULT_PASSWORD="${input_default_password:-$DEFAULT_PASSWORD}"

echo "REGISTRY_PORT=$PORT" > .env
echo "REGISTRY_DATA_DIR=" >> .env

echo ""
echo ""
echo "================================================"
echo "Generate certificate and auth ..."
echo "================================================"
mkdir -p cert auth

[ ! -f ${HOME}/.local/share/mkcert/rootCA.pem ] && mkcert -install && sudo update-ca-certificates
cp $(mkcert -CAROOT)/rootCA.pem cert/ca.crt

mkcert -key-file cert/key.pem -cert-file cert/cert.pem -client ${DOMAIN_NAME}
docker run --rm --entrypoint htpasswd httpd:2 -Bbn ${DEFAULT_USERNAME} ${DEFAULT_PASSWORD} > auth/htpasswd

echo ""
echo ""
echo "================================================"
echo "Activate service ..."
echo "================================================"
docker-compose up -d --force-recreate

echo ""
echo ""
echo "================================================"
echo "Prepare certifiacte for clients ..."
echo "================================================"
cp -r cert $REGISTRY_NAME
zip -q -r cert_${REGISTRY_NAME//[.:]/_}.zip $REGISTRY_NAME
rm -rf $REGISTRY_NAME
echo "Zip cert into cert_${REGISTRY_NAME//[.:]/_}.zip ... "

echo ""
echo "Please follow the steps for installing certificate in clients ..."
echo "    mkdir -p /etc/docker/certs.d"
echo "    unzip cert_${REGISTRY_NAME//[.:]/_}.zip -d /etc/docker/certs.d"
echo "    docker login $REGISTRY_NAME -u $DEFAULT_USERNAME -p $DEFAULT_PASSWORD"
