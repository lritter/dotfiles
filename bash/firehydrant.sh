#!/usr/bin/env bash

export USE_GKE_GCLOUD_AUTH_PLUGIN=True

alias kubestaging=kubectl --context=gke_staging-f5dd003e_us-east4_staginge6eb-us-east4
alias kubeprod=kubectl --context=gke_production-96f8812d_us-east4_productioneb0c-us-east4

# fhconsole finds an appropriate container and runs the rails console.
# The command takes and optional argument which is the k8s/kubectl context. If none
# is given then the current context is used. If given, the context is swtiched (and
# will remain switched after the function exits)
fh-console() {
  if [ ! -z "$1" ]; then
    ctx="$1"
    kubectl config use-context "$ctx" || return 1
  fi

  kubectl -n laddertruck exec -ti $(kubectl -n laddertruck get pod -l 'name=rails' -o json | jq -r .items[0].metadata.name) bin/rails console
}

fh-bash() {
  if [ ! -z "$1" ]; then
    ctx="$1"
    kubectl config use-context "$ctx" || return 1
  fi

  kubectl -n laddertruck exec -ti $(kubectl -n laddertruck get pod -l 'name=rails' -o json | jq -r .items[0].metadata.name) bash
}

fh-schema-cache() {
  if [ ! -z "$1" ]; then
    ctx="$1"
    kubectl config use-context "$ctx" || return 1
  fi

  pod=$(kubectl -n laddertruck get pod -l 'name=rails' -o json | jq -r .items[0].metadata.name)
  kubectl -n laddertruck exec -ti $pod -- bash -c 'bundle exec rake db:schema:cache:dump && mv db/schema_cache.yml /tmp/schema_cache.yml'
  kubectl cp laddertruck/$pod:/tmp/schema_cache.yml ./db/schema_cache.tmp.yml
}

fh-sql() {
  if [ ! -z "$1" ]; then
    ctx="$1"
    kubectl config use-context "$ctx" || return 1
  fi

  kubectl -n laddertruck exec -ti $(kubectl -n laddertruck get pod -l 'name=rails' -o json | jq -r .items[0].metadata.name) -- bash -c 'psql $DATABASE_URL'
}

fh-backup-status() {
  if [ ! -z "$1" ]; then
    ctx="$1"
    kubectl config use-context "$ctx" || return 1
  fi
  kubectl get pod --namespace db-backups
}

fh-put-on-staging() {
  git checkout staging && git fetch origin && git reset --hard origin/staging && git merge - && git push && git checkout -
}

dc-stop-annoying() {
  dc stop $(cat ${DOTFILESPATH}/data/annoying_fh_containers)
}

export -f fh-console
export -f fh-put-on-staging
export PROJECT_LADDERTRUCK_DIR=/Users/${USER}/src/laddertruck
export LEFTHOOK=0

export COMPOSE_PROFILES="temporal_runbooks"