alias rx='ssh -t -t bastion rx'

# TODO: Make something to reap agents? http://rabexc.org/posts/pitfalls-of-ssh-agents


setup_ssh() {
  ssh-add -l &>/dev/null # See if any identies have been added
  if [ "$?" != 0 ]; then
    # Look to see if we have information about the agent that is running
    # If we do, get that info into the shell
    test -r ~/.ssh-agent && \
      eval "$(<~/.ssh-agent)" >/dev/null

    # If we still don't have any identities, start up ssh agent and
    # Put the needed info in .ssh-agent and eval it.
    ssh-add -l &>/dev/null
    if [ "$?" != 0 ]; then
      (umask 066; ssh-agent > ~/.ssh-agent)
      eval "$(<~/.ssh-agent)" >/dev/null
      ssh-add -K ~/.ssh/animoto_id_rsa
    fi
  fi
}

export setup_ssh
setup_ssh
