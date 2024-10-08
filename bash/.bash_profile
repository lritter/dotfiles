# Try and discover where *this file* lives.  This is a bit annoying and probably not very
# reliable since normally I symlink it. It's possilble a better alternative is to just
# assume that it lives at ~/.bash_profile and go from there...
CONFIG_DIR=$( dirname $( readlink "${BASH_SOURCE[0]}" ))
if [ -d "$CONFIG_DIR" ]; then
  export BASH_CONFIG_ROOT="$( dirname $( readlink "${BASH_SOURCE[0]}" ))"
else
  export BASH_CONFIG_ROOT="/Users/$(whoami)/$( dirname $( readlink "${BASH_SOURCE[0]}" ))"
fi
# export BASH_CONFIG_ROOT="$( dirname $( readlink "${BASH_SOURCE[0]}" ))"
source "$BASH_CONFIG_ROOT"/bash_env

if [ -f /etc/bashrc ]; then
  . /etc/bashrc        # --> Read /etc/bashrc, if present.
fi

[[ $- = *i* ]] || return

shopt -s histappend # Append to history file instead of overwrite

# Try to load up some completions
for file in /usr/local/etc/bash_completion.d/{git-completion.bash,git-prompt.sh,R}; do
  [ -r "$file" ] && source "$file"
done
unset file

for file in "$BASH_CONFIG_ROOT"/{bash_colors.sh,findmyfile.function,__edit.function,exitstatus_prompt.function,copy.function,history,completion,aliases,misc_functions.function,google-cloud-sdk.sh,nvm.sh,spec_for.sh,rbenv.sh}; do
  [ -r "$file" ] && source "$file"
done
unset file

# ASDF
# . $(brew --prefix asdf)/asdf.sh

# Enable some Bash 4 features when possible:
# * `autocd`, e.g. `**/qux` will enter `./foo/bar/baz/qux`
# * Recursive globbing, e.g. `echo **/*.txt`
for option in autocd globstar; do
  shopt -s "$option" 2> /dev/null
done

# Make bash check its window size after a process completes
shopt -s checkwinsize

# source "$BASH_CONFIG_ROOT"/liquidprompt/liquidprompt
export CONFIG_ENV=development
export RACK_ENV=development
export RAILS_ENV=development

source "$BASH_CONFIG_ROOT"/setup_ssh.sh

source "$BASH_CONFIG_ROOT"/firehydrant.sh
ulimit -n 10240

bracketed-paste-disable

# eval "$(pyenv init -)"
# eval "$(direnv hook bash)"