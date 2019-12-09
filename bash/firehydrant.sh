#!/usr/bin/env bash

fhconsole() {
  kubectl -n laddertruck exec -ti $(kubectl -n laddertruck get pod -l 'name=rails' -o json | jq -r .items[0].metadata.name) bin/rails console
}

export fhconsole
export PROJECT_LADDERTRUCK_DIR=/Users/lritter/src/laddertruck
