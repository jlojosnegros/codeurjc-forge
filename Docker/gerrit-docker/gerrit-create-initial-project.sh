#!/bin/bash -x
set -e

echo "#####################################"
echo "### GERRIT CREATE INITIAL PROJECT ###"
echo "#####################################"

# Usage
usage() {
    echo "Usage:"
    echo "    ${0} -A <username> -P <password> -p <initial_project_name> -d <initial_project_description>"
    exit 1
}

while getopts "A:P:p:d:" opt; do
  case $opt in
    A)
      username=${OPTARG}
      ;;
    P)
      password=${OPTARG}
      ;;
    p)
      initial_project_name=${OPTARG}
      ;;
    d)
      initial_project_description="${OPTARG}"
      ;;
    *)
      echo "Invalid parameter(s) or option(s)."
      usage
      ;;
  esac
done

if [ -z "${username}" ] || [ -z "${password}" ] || [ -z "${initial_project_name}" ] || [ -z "${initial_project_description}" ]; then
    echo "Parameters missing"
    usage
fi

# Generate Gerrit admin rsa key
ssh-keygen -t rsa -f ~/.ssh/id_rsa -q -P ""

# Load the key
ssh_key=$(cat ~/.ssh/id_rsa.pub)
ret=$(curl --request POST --user ${username}:${password} --data "${ssh_key}" --output /dev/null --silent --write-out '%{http_code}' http://localhost:8080/a/accounts/admin/sshkeys)
if [[ ${ret} -eq 201 ]]; then
  echo "Public-key was uploaded"
else
  echo "Public-key was uploaded with the invalid response code: ${ret}"
fi

# Create the project
ssh admin@localhost -p 29418 -o "StrictHostKeyChecking no" gerrit create-project ${initial_project_name}.git --description "'${initial_project_description}'"
if [ "$?" == "0" ]; then
	echo "Project ${initial_project_name} created"
else
	echo "Project creation failed"
fi