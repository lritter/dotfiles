# Try and discover where *this file* lives.  This is a bit annoying and probably not very 
# reliable since normally I symlink it. It's possilble a better alternative is to just
# assume that it lives at ~/.bash_profile and go from there...

export BASH_CONFIG_ROOT="$( dirname $( readlink "${BASH_SOURCE[0]}" ))"


# Try to load up some completions
for file in /usr/local/etc/bash_completion.d/{git-completion.bash,git-prompt.sh,R}; do
  [ -r "$file" ] && source "$file"
done
unset file

for file in "$BASH_CONFIG_ROOT"/{update_terminal_cwd.function,exitstatus_prompt.function,copy.function,bash_env,history,completion,alias}; do
  [ -r "$file" ] && source "$file"
done
unset file

# Enable some Bash 4 features when possible:
# * `autocd`, e.g. `**/qux` will enter `./foo/bar/baz/qux`
# * Recursive globbing, e.g. `echo **/*.txt`
for option in autocd globstar; do
  shopt -s "$option" 2> /dev/null
done

export PATH=/usr/local/share/npm/bin:/usr/local/bin:/usr/local/share/npm/bin:/usr/local/bin:/Users/lritter/.rvm/gems/ruby-1.8.7-p371/bin:/Users/lritter/.rvm/gems/ruby-1.8.7-p371@global/bin:/Users/lritter/.rvm/rubies/ruby-1.8.7-p371/bin:/Users/lritter/.rvm/bin:/usr/local/heroku/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/opt/X11/bin:/Users/lritter/Local/bin:/Users/lritter/.rvm/bin:/usr/local/share/npm/bin
export PATH="/usr/local/sbin:$PATH"

[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function* # export PATH=/usr/local/share/npm/bin:/usr/local/bin:/usr/local/share/npm/bin:/usr/local/bin:/Users/lritter/.rvm/gems/ruby-1.8.7-p371/bin:/Users/lritter/.rvm/gems/ruby-1.8.7-p371@global/bin:/Users/lritter/.rvm/rubies/ruby-1.8.7-p371/bin:/Users/lritter/.rvm/bin:/usr/local/heroku/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/opt/X11/bin:/Users/lritter/Local/bin:/Users/lritter/.rvm/bin:/usr/local/share/npm/bin
export PATH="$PATH:$HOME/.rvm/bin" # Add RVM to PATH for scripting
