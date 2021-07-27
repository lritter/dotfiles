#!/usr/bin/env bash

set -o noclobber

spec_for() {
  source_path=${1}

  if [[ ! -f ${source_path} ]]; then
    >&2 echo "${source_path} does not exist"
    exit 1
  fi

  intermediate=${source_path/%\.rb/_spec.rb}
  
  api_prefix="app/api/"
  api_replacement="spec/requests/"
  standard_prefix="app/"
  standard_replacement="spec/"

  if [[ ${intermediate} =~ ^${api_prefix} ]]; then
    replacement_prefix=${api_prefix}
    replacement=${api_replacement}
  elif [[ ${intermediate} =~ ^${standard_prefix} ]]; then
    replacement_prefix=${standard_prefix}
    replacement=${standard_replacement}
  fi
    
  target_path=${intermediate/#${replacement_prefix}/${replacement}}

  mkdir -p $(dirname ${target_path})
  touch ${target_path}

  echo $target_path
}

if [[ $0 == ${BASH_SOURCE[0]} ]]; then
  spec_for ${1}
else
  export spec_for
fi