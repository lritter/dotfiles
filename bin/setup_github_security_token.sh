#!/bin/bash

keychain_service_name='Github User Token'

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
echo Add \"export GITHUB_TOKEN=\$\(security find-generic-password -a ${USER} -s \'"${keychain_service_name}"\' -w\)\" to your .bashrc
