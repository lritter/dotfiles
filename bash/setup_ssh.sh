alias rx='ssh -t -t bastion rx'
eval "$(ssh-agent -s)" > /dev/null 2>&1
ssh-add -K ~/.ssh/animoto_id_rsa > /dev/null 2>&1
