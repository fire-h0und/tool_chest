#!/bin/bash

tasks="nuc"
# e - change editor
# g - edit graylist
# b - edit blacklist
# n - install-new
# u - upgrade-all
# c - clean-system

Editor=/usr/bin/mcedit
# m - mcedit
# v - vim
# e - emacs
# n - nano

### END DEFAULTS
edcmd=(dialog --radiolist \"Tap_[esc]_twice_to_skip\" 13 40 4)
if [[ -x /usr/bin/mcedit ]]; then
  edcmd+=( m mcedit off)
fi
if [[ -x /usr/bin/vim ]]; then
  edcmd+=( v vim off)
fi
if [[ -x /usr/bin/emacs ]]; then
  edcmd+=( e emacs off)
fi
if [[ -x /usr/bin/nano ]]; then
  edcmd+=( n nano off)
fi

dialog --backtitle "SUP - System Update Processor" --title "Operatios" --separator "" \
--item-help --nocancel --ok-label "Process" --no-tags --checklist "Tap [esc] twice to abort." 13 40 6 \
e editor on "Change the editor used to modify lists and exit" \
g greylist 0 "Change what is not selected" \
b blacklist 0 "Change what is not listed" \
i install-new on "Select to install any newly added packages" \
u upgrade-all on "Select to upgrade any installed packages" \
c clean-system on "Select to remove any orphaned packages" 2> /tmp/task1.bin
rep1=$(cat /tmp/task1.bin)
echo $rep1

if slackpkg update; then
  case $rep1 in
  *e*)
    ${edcmd[@]} 2> /tmp/task2.bin
    rep2=$(cat /tmp/task2.bin)
    case $rep2 in
    m)
      echo "Selected mcedit"
      Editor=/usr/bin/mcedit
    ;;
    v)
      echo "Selected vim"
      Editor=/usr/bin/vim
    ;;
    e)
      echo "Selected emacs"
      Editor=/usr/bin/emacs
    ;;
    n)
      echo "Selected nano"
      Editor=/usr/bin/nano
    ;;
  esac
  ;;&
  *g*)
  $Editor /etc/slackpkg/greylist
  ;;&
  *b*)
  $Editor /etc/slackpkg/blacklist
  ;;&
  *i*)
    echo "Installing new packages:"
    slackpkg install-new
  ;;&
  *u*)
    echo "Upgrading all packages:"
    slackpkg upgrade-all
  ;;&
  *c*)
    echo "Cleaning up orphans:"
    slackpkg clean-system
  ;;
  esac
fi
echo "Checking for any remaining new configuration files:"
slackpkg new-config
echo "Cleanup:"
rm /tmp/task[12].bin
