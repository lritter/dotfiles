# lritter's Dotfiles

This is where I keep all my dotfiles, preferences, useful shell scripts, etc.

Normally I keep my dotfiles checked out to `~/.dotfiles` and I symlink particular files in my home directory to files in my dotfiles directory.

TODO: Script the symlinking.

The directory layout is fairly self-explanatory and I try to comment the dotfiles so I can remember why I actually did what I did...

## Basic setup

I am trying out Bash 4 right now.  It seems to have most of what I liked about Zsh (fancy globbing, easy completions) but is a bit more standard since it's bash (though now that OS-X has Zsh as an approved shell...)

Set this up with:

    brew install bash # Build bash
    sudo echo '/usr/local/bin/bash' >> /etc/shells # Add to "approved" shells
    chsh -s /usr/local/bin/bash lritter

    # I do this from my homedir and use, say, src/dotfiles as the dotfiles path
    ln -s {path-to-cloned-repo}/bash/.bashrc
    ln -s {path-to-cloned-repo}/bash/.bash_profile 