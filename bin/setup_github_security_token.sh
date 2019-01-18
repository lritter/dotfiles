#!/bin/bash

github_keychain_service_name='Github User Token'

keychain_args="-a ${USER} -s '${github_keychain_service_name}' -w"
gh_token_cmd="security find-generic-password $keychain_args"

function read_token_from_keychain {
  security find-generic-password -a ${USER} -s "${keychain_service_name}" -w
}

function add_new_github_token_to_keychain {
  echo Please enter your github token:
  read github_token
  security add-generic-password -a ${USER} -s "${keychain_service_name}" -w ${github_token} > /dev/null
}

function add_github_token_if_needed {
  read_token_from_keychain > /dev/null

  if [ $? -ne 0 ]
  then
     # Add a new token
     add_new_github_token_to_keychain
     add_github_token_if_needed # This is a sanity check
  fi
}

add_github_token_if_needed

# echo $gh_token_cmd
# alias gh_token='$(security find-generic-password -s '"${keychain_service_name}"' -w)'

echo -e "Add:\n"\"export GITHUB_TOKEN=\$\($gh_token_cmd\)\""\nto your .bashrc"
