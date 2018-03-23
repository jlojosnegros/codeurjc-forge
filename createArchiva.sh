#!/bin/bash -x
set -e

. config.rc

docker volume create --name ${ARCHIVA_VOLUME}

docker run \
--name archiva \
--net ${CI_NETWORK} \
--volume ${ARCHIVA_VOLUME}:/archiva-data \
--publish 7070:8080 \
--detach xetusoss/archiva

until curl --location --output /dev/null --silent --write-out "%{http_code}\\n" "http://localhost:7070/" | grep 200 &>/dev/null
do
  echo "Waiting for Archiva"
  sleep 1
done

generate_post_data()
{
  cat <<EOF
{
	"username":"admin",
	"password":"$GERRIT_ADMIN_PWD",
	"confirmPassword":"$GERRIT_ADMIN_PWD",
	"fullName":"URJC CI Forge",
	"email":"$GERRIT_ADMIN_EMAIL",
	"assignedRoles":[],
	"modified":true,
	"rememberme":false,
	"logged":false
}
EOF
}

curl 'http://localhost:7070/restServices/redbackServices/userService/createAdminUser' \
-H 'Origin: http://localhost:7070' \
-H 'Content-Type: application/json' \
-H 'Referer: http://localhost:7070/' \
-H 'Connection: keep-alive' \
--data "$(generate_post_data)" --compressed