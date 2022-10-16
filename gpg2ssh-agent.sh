#!/bin/bash

# Transfer gpg-ssh-keys to ssh-agent

HOMEDIR="~/.gnupg"
GPG_TTY=$(tty)
#export GPG_TTY

function test-key {
    local L_USER="${1:-}"

    if [ -z "$L_USER" ]; then
        echo "ERROR: missing required parameter 1!"
        return 1
    fi

    gpg --export --homedir "$HOMEDIR" "$L_USER" | hokey lint 
}

function add_by_sshcontrol {
    LIST="$(cat "$HOMEDIR"'/sshcontrol' | grep -v '\(^ *$\|^#\)')"

    while IFS= read -r line; do
        keygrip="$(echo "$line" | cut -d' ' -f1)"
        ttl="$(echo "$line" | cut -d' ' -f2)"
        confirm="$(echo "$line" | cut -d' ' -f3)"
        comment="$(echo "$line" | cut -d' ' -f4)"
        
        if [ "${keygrip:0:1}" == "!" ]; then
            continue
        fi

        CMD="agent-transfer"
        if [ -n "$ttl" ]; then
            CMD+=" -t $ttl"
        fi
        if [ -n "$confirm" ] && [ "${confirm,,}" == "confirm" ]; then
            CMD+=" -c"
        fi
        CMD+=" $keygrip"
        if [ -n "$comment" ]; then
            CMD+=" $comment"
        fi

        echo "Execute: $CMD < $GPG_TTY"
        eval "$CMD < $GPG_TTY"
    done <<< $(echo "$LIST")
}

function trap_exit {
    :
}

### MAIN
HOMEDIR="${HOMEDIR/\~/$HOME}"
echo "GPG-TTY: $GPG_TTY"


trap trap_exit EXIT
add_by_sshcontrol
