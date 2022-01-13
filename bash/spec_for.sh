#!/usr/bin/env bash

set -o noclobber

spec_path_for() {
  source_path=${1}

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

  echo ${target_path}
}

spec_for() {
  source_path=${1}

  if [[ ! -f ${source_path} ]]; then
    >&2 echo "${source_path} does not exist"
    exit 1
  fi

  target_path=$(spec_path_for ${source_path})

  mkdir -p $(dirname ${target_path})
  touch ${target_path}

  echo $target_path
}

specs_for_diff() {
  spec_paths=()

  i=0
  for changed_file in $(git diff --name-only main); do
    spec_paths[i]=$(spec_path_for ${changed_file})
  done

  echo $(echo ${spec_paths} | xargs ls -d 2>/dev/null)
}

if [[ $0 == ${BASH_SOURCE[0]} ]]; then
  spec_for ${1}
else
  export spec_for
  export spec_path_for
  export specs_for_diff
fi