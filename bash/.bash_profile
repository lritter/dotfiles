export BASH_CONFIG_ROOT="$( dirname $( readlink "${BASH_SOURCE[0]}" ))"

source "$BASH_CONFIG_ROOT"/git_prompt

# Get the path of our "bash env" file (where env variable go) and source it.  This seems 
# like a bit of a brittle way to do this...
source "$BASH_CONFIG_ROOT"/bash_env

[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*