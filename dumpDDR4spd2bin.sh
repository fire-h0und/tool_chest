#!/bin/sh

 version="0.1-Alpha"
#
 appname="${0##*/}-${version}"
#
# Warning: possibly dangerous in unforeseen corner use cases
#
# 2025 cest73@ya.ru aka fire-h0und on github.com
#
# GPL v3 license applies (if no copy can be obtained find a way to contact me)
#
# Use at own risk, provided as is, no warranty, reasonable feedback is welcome
# This might be a good companion for the DD4XMPeditor (https://github.com/integralfx/DDR4XMPEditor)
# or not :-)
#
# strictly unauthorized to be used as training data for machine learning in any shape art or form

while true; do
  echo -ne "\nScanning:\n\n"
  #initialize the array iterator
  i=0
  # fill the array with acces data
  for dimm in $(ls -d /sys/bus/i2c/drivers/ee1004/0-005?); do
    echo -ne "DIMM${i}:" $dimm
    if [ -d $dimm ]; then
      echo -ne ": Present :["
      # first get name of the module
      a=$(dd if=$dimm/eeprom skip=329 count=20 bs=1 2>/dev/null)
      # process hane to be safe asa file name
      f=$(echo $a | sed "s/[[:space:]]//g" | sed 's/[^[:alnum:]]/_/g' )
      echo -ne $f"]"
      # presumably slot number
      n=$(($( echo $dimm | sed 's/.*\(.\)$/\1/') +1 ))
      echo " Slot:[${n}]"
      fname[i]=$f
      spde[i]=$dimm/eeprom
      menu[i]=$(echo $i $f "off")
      i=$((i+1))
    else
      echo ": None present, is the ee1004 eeprom driver module loaded?"
      break
    fi
  done

  # make a dialog to pick what to dump int bin files
  dialog --backtitle $appname --title "Detected DDR4 DIMMs" --checklist "Select the DIMMs to dump SPD from:" 18 40 8 ${menu[@]} 2> /tmp/tmp.bin
  l=$(cat /tmp/tmp.bin)
  # dump picked DIMM SPD data
  for e in $l; do
  echo "Dumping DIMM${e} to file [${fname[e]}.bin]"
  dd if=${spde[e]} of=${fname[e]}.bin 
  done
  
  # exit or repeat?
  if dialog --erase-on-exit --defaultno --backtitle $appname --title "Done" --yesno "Another Pass?" 5 40; then
    echo "Repeating"
  else
    echo "Current direcotry content:"
    ls -lh
    exit 0
  fi
done
