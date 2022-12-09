#!/usr/bin/env bash

set -o noclobber

spec_path_for() {
  source_path=${1}

  intermediate=${source_path/%\.rb/_spec.rb}

  api_prefix="app/api/"
  api_replacement="spec/requests/"
  lib_replacement="spec/lib/"
  lib_prefix="lib/"
  standard_prefix="app/"
  standard_replacement="spec/"

  if [[ ${intermediate} =~ ^${api_prefix} ]]; then
    replacement_prefix=${api_prefix}
    replacement=${api_replacement}
  elif [[ ${intermediate} =~ ^${standard_prefix} ]]; then
    replacement_prefix=${standard_prefix}
    replacement=${standard_replacement}
  elif [[ ${intermediate} =~ ^${lib_prefix} ]]; then
    replacement_prefix=${lib_prefix}
    replacement=${lib_replacement}
  else
    >&2 echo "no spec path matcher for ${source_path}"
    exit 1
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
  for changed_file in $(git changed-files main | xargs ls -1 {} 2>/dev/null | egrep '\.rb$'); do
    spec_file=$(spec_path_for ${changed_file} 2>/dev/null)
    if [ $? = 0 ]; then
      spec_paths+=(${spec_file})
    fi
  done

  printf '%s\n' $(printf '%s\n' "${spec_paths[@]}" | xargs ls -d 2>/dev/null)
}

if [[ $0 == ${BASH_SOURCE[0]} ]]; then
  args=("$@")
  if [ ${1} = "path" ]; then
    spec_for_path "${args[@]:1}"
  elif [ ${1} = "diff" ]; then
    specs_for_diff
  else
    spec_for "$@"
  fi
else
  export spec_for
  export spec_path_for
  export specs_for_diff
fi