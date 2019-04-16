#!/bin/sh

ask "Install bash?" || { apk add bash; ask "Change shell (bash is at $(which bash))?" || nano /etc/passwd; }
ask "Install bash-completion?" || apk add bash-completion
ask "Install nano?" || apk add nano
ask "Install gcc?" || apk add gcc libc-dev
