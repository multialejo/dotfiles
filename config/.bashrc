# If not running interactively, don't do anything (leave this at the top of this file)
[[ $- != *i* ]] && return

# Omarchy bash extras (envs, aliases, functions, init), portable port.
# Comment this line out on distros where Omarchy already provides them
# (avoids duplicate PATH/init).
[ -f ~/.bash-omarchy ] && source ~/.bash-omarchy

# Add your own exports, aliases, and functions here.
alias ueb-update="~/scripts/ueb-update"

# Laravel Sail
alias sail='sh $([ -f sail ] && echo sail || echo vendor/bin/sail)'