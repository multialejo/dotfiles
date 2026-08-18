# If not running interactively, don't do anything (leave this at the top of this file)
[[ $- != *i* ]] && return

# Add your own exports, aliases, and functions here.
alias ueb-update="~/scripts/ueb-update"

# Laravel Sail
alias sail='sh $([ -f sail ] && echo sail || echo vendor/bin/sail)'