#!/bin/bash

tasks="nukc"
# n - install-new
# u - upgrade-all
# k - upgrade kernel
# c - clean-system

### END DEFAULTS

dialog --backtitle "SUP - System Update Processor" --title "Operations" --separator "" \
--item-help --nocancel --ok-label "Process" --no-tags --erase-on-exit \
--checklist "Tap [esc] twice to abort." 13 40 6 \
i install-new on "Select to install any newly added packages" \
u upgrade-all on "Select to upgrade any installed packages" \
k "upgrade kernel" on "Upgrade kernel" \
c clean-system on "Select to remove any orphaned packages" 2> /tmp/task.bin
rep1=$(cat /tmp/task.bin)
#echo $rep1

if slackpkg update; then
  case $rep1 in
  *i*)
    echo "Installing new packages:"
    slackpkg install-new
  ;;&
  *u*)
    echo "Upgrading all packages:"
    slackpkg upgrade-all
  ;;&
  *k*)
    echo "Upgrading Kernel:"
    klist=""
    klist=$(slackpkg search kernel.* | grep "^\[.*\]" | awk -F: '{print $2;}') 
    #echo "Kernel list: [${klist}]"
    slackpkg upgrade $klist
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
rm /tmp/task.bin
