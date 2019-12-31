#!/usr/bin/env bash

# fhconsole finds an appropriate container and runs the rails console.
# The command takes and optional argument which is the k8s/kubectl context. If none
# is given then the current context is used. If given, the context is swtiched (and 
# will remain switched after the function exits)
fhconsole() {
  if [ ! -z "$1" ]; then
    ctx="$1"
    kubectl config use-context "$ctx" || return 1
  fi

  kubectl -n laddertruck exec -ti $(kubectl -n laddertruck get pod -l 'name=rails' -o json | jq -r .items[0].metadata.name) bin/rails console
}

fhbash() {
  if [ ! -z "$1" ]; then
    ctx="$1"
    kubectl config use-context "$ctx" || return 1
  fi

  kubectl -n laddertruck exec -ti $(kubectl -n laddertruck get pod -l 'name=rails' -o json | jq -r .items[0].metadata.name) bash
}

fhsql() {
  if [ ! -z "$1" ]; then
    ctx="$1"
    kubectl config use-context "$ctx" || return 1
  fi

  kubectl -n laddertruck exec -ti $(kubectl -n laddertruck get pod -l 'name=rails' -o json | jq -r .items[0].metadata.name) -- bash -c 'psql $DATABASE_URL' 
}

put-on-staging() {
  git checkout staging && git fetch origin && git reset --hard origin/staging && git merge - && git push && git checkout -
}

export -f fhconsole
export -f put-on-staging
export PROJECT_LADDERTRUCK_DIR=/Users/lritter/src/laddertruck
