#!/bin/bash

github_keychain_service_name='Github User Token'

keychain_args="-a ${USER} -s '${github_keychain_service_name}' -w"
gh_token_cmd="security find-generic-password $keychain_args"

function read_secret_from_keychain {
  service_name="${1}"
  security find-generic-password -a ${USER} -s "${service_name}" -w 
}

function prompt_user_for_secret {
  service_name="${1}"
  message="${2}"
  echo "${message}"
  read secret
  security add-generic-password -a ${USER} -s "${service_name}" -w ${secret} > /dev/null
}

function add_secret_to_keychain_if_needed {
  service_name="${1}"
  message="${2}"

  read_token_from_keychain "${service_name}" > /dev/null
  if [ $? -ne 0 ]
  then
     # Add a new token
     prompt_user_for_secret "${service_name}" "${message}"
     add_github_token_if_needed "${service_name}" "${message}" # This is a sanity check
  fi 
}

function print_env_command {
  service_name="${1}"
  env_var="${2}"
  kc_args="-a ${USER} -s '${service_name}' -w"
  kc_cmd="security find-generic-password $kc_args"
  echo -e "Add:\n"\"export $env_var=\$\($kc_cmd\)\""\nto your .bashrc"
}

function add_github_token_if_needed {
  p="Please enter your github token:"
  add_secret_to_keychain_if_needed "${github_keychain_service_name}" "${p}"
}

add_github_token_if_needed

print_env_command "${github_keychain_service_name}" "GITHUB_TOKEN" 
