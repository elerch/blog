#!/bin/sh

# To run this without copy/paste the whole thing:
# curl https://gist.githubusercontent.com/elerch/88ea951c9c4ec4c3c1604b8fc9167e53/raw/bootstrap.sh | sh
# mr is just a perl script
myrepos="http://source.myrepos.branchable.com/?p=source.git;a=blob_plain;f=mr;hb=HEAD"

# vcsh is just a bash script
vcsh=https://raw.githubusercontent.com/RichiH/vcsh/master/vcsh

download() {
  cmd='curl -L "'"${1}"'" -o "'"${2}"'"'
  hash curl 2>/dev/null || \
    { hash wget 2>/dev/null && cmd='wget "'"${1}"'" -O "'"${2}"'"'; } || \
    install_package curl
  
  echo "Downloading with: ${cmd}"
  eval "${cmd}"
  chmod a+x "${2}"
}
runroot() {
  # if we don't have EUID variable and id doesn't exist, then we're going
  # to assume we're root
  euid=${EUID:-$(id -u 2>/dev/null || echo 0)}
  if [ "${euid}" = "0" ]; then
    eval "${*}"
  else
    hash sudo 2>/dev/null || \
      echo "you are not root and sudo is not installed. Please re-run as root"
    eval "sudo ${*}"
  fi
}

install_package() {
  pkgname=$1

  # This assumes the package name is the same on all package managers (big assumption)
  # and that sudo is on the system and user has sudo rights
  # yum - RPM-based distros (e.g. Red Hat, Amazon Linux, Centos)
  # apk - Alpine linux
  # pacman - Arch linux
  # apt-get - Debian and derivatives, notably ubuntu and raspbian
  # brew - commonly installed on OSX
  hash "${pkgname}" 2> /dev/null || \
    { hash yum 2>/dev/null && runroot yum install "${pkgname}"; } || \
    { hash apk 2> /dev/null && runroot apk update && runroot apk add "${pkgname}"; } || \
    { hash pacman 2> /dev/null && runroot pacman -S "${pkgname}"; } || \
    { hash apt-get 2> /dev/null && runroot apt-get update && runroot apt-get install -y "${pkgname}"; } || \
    { hash brew 2> /dev/null && brew install "${pkgname}"; }

  hash "${pkgname}" 2> /dev/null || \
    { echo "Could not install $pkgname on this system. Please fix and try again"; exit 1; }
  unset pkgname
}
if hash apk 2> /dev/null; then
  echo 'Looks like you are on Alpine. If this is a fresh install, type y to install ssl & perl'
  unset key && read -r key
  [ ${key} = "y" ] && apk update && \
    apk add ca-certificates && update-ca-certificates && apk add openssl && apk add perl
fi
if hash pacman 2> /dev/null; then
  echo 'Looks like you are on arch. If this is a fresh install, type y to update package dbs and install keyring'
  unset key && read -r key
  [ ${key} = "y" ] && pacman -Syy && pacman -S archlinux-keyring
fi
# Temporary directory - OSX or Linux. See http://unix.stackexchange.com/a/84980/140674
#mytmpdir=${mktemp -d 2>/dev/null || mktemp -d -t 'mytmpdir'}
mkdir -p "${HOME}"/bin
PATH="${HOME}/bin:${PATH}"
hash mr 2> /dev/null || \
  download "${myrepos}" "${HOME}"/bin/mr || \
  { echo "Could not download mr. Please fix and try again"; exit 1; }
hash perl 2> /dev/null || install_package perl
hash perl 2> /dev/null || \
  { echo "Could not find perl, which is required by mr. Please fix and try again"; exit 1; }
install_package git # vcsh is a git wrapper...
hash vcsh 2> /dev/null || download "${vcsh}" "${HOME}"/bin/vcsh || \
  { echo "Could not download vcsh. Please fix and try again"; exit 1; }
mkdir -p "${HOME}"/backup
# move all dotfiles into the backup directory
find "${HOME}" -maxdepth 1 -name '.*' -type f -exec mv {} "${HOME}"/backup \;
# now being done through mr/.commonrc
#download "https://raw.github.com/trapd00r/LS_COLORS/master/LS_COLORS" "${HOME}"/.dircolors
[ -f "${HOME}"/backup/.mrconfig ] && mv "${HOME}"/backup/.mrconfig "${HOME}"
vcsh list | grep -qF mr || vcsh clone https://github.com/elerch/mr.git mr
mr update || { echo "mr had some failures, double check output and enter to proceed"; read -r key; }
[ ! -z "$key" ] && unset key # make linter happy
[ "$(ls -A "${HOME}"/backup)" ] && mv -n "${HOME}"/backup/.* "${HOME}"
# If the directory was empty this will remove it, otherwise we'll show the message
# about backups
rmdir "${HOME}"/backup 2> /dev/null || \
  echo "Dotfiles that were touched by mr were placed in ${HOME}/backup in case you need them"
mkdir -p "${HOME}"/.vim/autoload
# Vimrc will do this for us. See https://github.com/junegunn/vim-plug/wiki/faq#automatic-installation
#[ -f "${HOME}"/.vim/autoload/plug.vim ] || \
#  download https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim "${HOME}"/.vim/autoload/plug.vim || \
#  { echo "Could not download vim-plug. Please fix and try again"; exit 1; }
#echo "complete. execute vim and :PlugInstall to get all vim goodness"
hash apk 2> /dev/null && [ -d "${HOME}"/.liquidprompt ] && apk add coreutils ncurses # 'who' is in there and needed