#!/usr/bin/env bash

function __list_recent_branches() {
  git branch --sort=-committerdate | grep -v HEAD | sed 's/^\*/  */'
}

function gsw() {
  if [ -z "$1" ]; then
    num_branches=10
    echo "Available branches:"
    __list_recent_branches | head -n "$num_branches" | nl -ba
    read -p "Enter branch no.: " branch_num
    branch_name=$(__list_recent_branches | sed -n "${branch_num}p" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    if [ -n "$branch_name" ]; then
      git checkout "$branch_name"
    else
      echo "Invalid branch number."
    fi
  elif [ "$1" == "-m" ]; then
    git checkout master || git checkout main
  elif [ "$1" == "-c" ]; then
    if [ -z "$2" ]; then
      echo "Usage: gsw -c <new_branch_name>"
    else
      git checkout -b "$2"
    fi
  else
    git checkout "$1"
  fi
}