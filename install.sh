#!/bin/sh

set -eu

. ./shared.sh

check_for_bash() {
	printf "Checking if Bash..."
	if [ "${BASH_VERSION:-}" ]; then
		export HAS_BASH=1
		echo "yes, $BASH_VERSION"
	else
		export HAS_BASH=
		echo "no"
	fi
}

check_os() {
	printf "Detecting OS..."
	case "$(uname)" in
		"Darwin")
			export OS=macOS
			;;
		"Linux")
			export OS=Linux
			case "$(uname -a)" in
				*Ubuntu*)
					export OS="$OS Ubuntu"
					;;
				*Alpine*)
					export OS="$OS Alpine"
					;;
				*)
					OS=Linux
					;;
			esac
			;;
	esac
	echo "$OS"
}

check_root()  {
	if [ "$(id -u)" -eq 0 ]; then
		export IS_ROOT=1
	else
		export IS_ROOT=
	fi
}

install_stderred() {
	local SAVED_DIRECTORY="$(pwd)"
	if [ ! -w "/usr/local/stderred" ]; then
		if ask "/usr/local/stderred is not writable, elevate permissions?"; then
			cd /usr/local
			local SUDO="sudo"
		elif ask "Install locally to ~/stderred?"; then
			cd
		else
			return 1;
		fi
	fi
	if test -d stderred && ask "$(pwd)/stderred already exists, remove?"; then
		set -x
		${SUDO:-} rm -rf stderred
		{ set +x; } 2>/dev/null
	fi
	set -x
	${SUDO:-} git clone https://github.com/saagarjha/stderred.git
	cd stderred
	${SUDO:-} make
	{ set +x; } 2>/dev/null
	cd "$SAVED_DIRECTORY"
}


check_for_bash
check_os

if [ "$HAS_BASH" ]; then
	set -o pipefail
fi

case "$OS" in
	"Linux Ubuntu")
		./install-ubuntu.sh
		;;
	"Linux Alpine")
		./install-alpine.sh
		;;
esac

ask "Copy bashrc?" && checked_copy .bashrc ~/.bashrc
ask "Copy bash_profile?" && checked_copy .bash_profile ~/.bash_profile
ask "Copy inputrc?" && checked_copy .inputrc ~/.inputrc
ask "Copy nanorc?" && checked_copy .nanorc ~/.nanorc && case "$OS" in
	"Mac")
		ln -s /usr/share/nano/ ~/.nano
		;;
	"Linux"*)
		ln -s /opt/local/share/ ~/.nano
		;;
esac
ask "Copy clang-format?" && checked_copy .clang-format ~/.clang-format
ask "Install iTerm shell integration?" && curl -L https://iterm2.com/misc/install_shell_integration.sh | bash
ask "Install git-ps1-status to /usr/local/bin?" && checked_copy git-ps1-status /usr/local/bin/git-ps1-status
ask "Install stderred?" && install_stderred
