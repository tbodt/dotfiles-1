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
			case "$(cat /etc/os-release)" in
				*elementary*)
					export OS="$OS elementary"
					;;
				*Ubuntu*)
					export OS="$OS Ubuntu"
					;;
				*Alpine*)
					export OS="$OS Alpine"
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
	local dil="${DYLD_INSERT_LIBRARIES:-}"
	local ld_preload="${LD_PRELOAD:-}"
	unset DYLD_INSERT_LIBRARIES
	unset LD_PRELOAD
	set -x
	cd stderred
	make clean && make
	cd ..
	{ set +x; } 2>/dev/null
	export DYLD_INSERT_LIBRARIES=$dil
	export LD_PRELOAD=$ld_preload
}

install_fixnano() {
	case "$OS" in
		"macOS")
			extension=dylib
			undefined_flags=-Wl,-U,_program_invocation_short_name
			;;
		"Linux"*)
			extension=so
			undefined_flags=
			;;
	esac
	set -x
	gcc -shared -fPIC -lc -ldl -Os $undefined_flags fixnano.c -o libfixnano.$extension
	{ set +x; } 2>/dev/null
}


check_for_bash
check_os

if [ "$HAS_BASH" ]; then
	set -o pipefail
fi

if [ ! -d ~/bin ]; then
	set -x
	mkdir ~/bin || true
	{ set +x; } 2>/dev/null
fi

ask "Run platform-specific steps?" && case "$OS" in
	"macOS")
		./install-macos.sh
		;;
	"Linux elementary")
		./install-elementary.sh
		;;
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
ask "Copy nanorc?" && checked_copy .nanorc ~/.nanorc && ! test -L ~/.nano && \
case "$OS" in
	"macOS")
		set -x
		ln -s /opt/local/share/nano ~/.nano
		{ set +x; } 2>/dev/null
		;;
	"Linux"*)
		set -x
		ln -s /usr/share/nano/ ~/.nano
		{ set +x; } 2>/dev/null
		;;
esac
ask "Copy gdbinit?" && checked_copy .gdbinit ~/.gdbinit
ask "Copy clang-format?" && checked_copy .clang-format ~/.clang-format
ask "Copy gitconfig?" && checked_copy .gitconfig ~/.gitconfig
ask "Copy gitattributes?" && checked_copy .gitattributes ~/.gitattributes
ask "Copy tigrc?" && checked_copy .tigrc ~/.tigrc
if [ ! -d ~/.config ]; then
	set -x
	mkdir ~/.config || true
	{ set +x; } 2>/dev/null
fi
ask "Install iTerm shell integration?" && curl -L https://iterm2.com/misc/install_shell_integration.sh | bash
ask "Install git-ps1-status?" && checked_copy git-ps1-status ~/bin/git-ps1-status
ask "Install git-add-upstream?" && checked_copy git-add-upstream ~/bin/git-add-upstream
ask "Install git-_diff-pager?" && checked_copy git-_diff-pager ~/bin/git-_diff-pager
ask "Install stderred?" && install_stderred
ask "Install nano fixes?" && install_fixnano
