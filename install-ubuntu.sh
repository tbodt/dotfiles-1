#!/bin/sh

. ./shared.sh

if [ ! "$IS_ROOT" ]; then
	SUDO=sudo
else
	SUDO=
fi

ask "Install cmake?" && $SUDO apt install cmake
ask "Install bashlogin?" && checked_copy bashlogin /bin/bashlogin

set -x

gsettings set io.elementary.terminal.settings natural-copy-paste false
gsettings set io.elementary.terminal.settings shell bashlogin

gsettings set org.pantheon.desktop.gala.appearance button-layout close,minimize,maximize

{ set +x; } 2>/dev/null

true
