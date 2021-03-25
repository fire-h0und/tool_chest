#!/bin/sh
# for cest73@gmail.com 2010 thru 2017 on Slackware
# ISC license applies
V="0.5.1"

#
# colors for output (GPL v3)
#
        _end="\033[0m"
  _dark_gray="\033[1;30m"
        _red="\033[1;31m"
      _green="\033[1;32m"
     _yellow="\033[1;33m"
       _blue="\033[1;34m"
     _purple="\033[1;35m"
       _cyan="\033[1;36m"
      _white="\033[1;37m"
      _black="\033[0;30m"
   _dark_red="\033[0;31m"
 _dark_green="\033[0;32m"
     _orange="\033[0;33m"
  _dark_blue="\033[0;34m"
     _violet="\033[0;35m"
  _dark_cyan="\033[0;36m"
       _gray="\033[0;37m"

#EXAMPLE:
# echo -e $_white"test"$_end


echo -e "usage: ${_dark_gray}m sdc1 ${_end} # to mount /dev/sdc1 on /mnt/hd"

device=${1:-sdb1}
mpoint=${2:-/mnt/hd}


mnt=/sbin/mount
umt=/sbin/umount
bi=/sbin/blkid

usr=$_yellow$(whoami | awk '{ print $1 }')$_end
grp=
case $usr in
root)
    echo  -e "run as root [$usr]"
    mnt="/sbin/mount"
    umt="/sbin/umount"
    ;;
*)
    echo -e "run as [$usr], we hope sudo is setup right?"
    mnt="sudo /sbin/mount"
    umt="sudo /sbin/umount"
    ;;
esac

echo -ne "Device:["${_green}$device${_end}"] (on behalf of ["$usr"]) "

if grep -q $device /proc/partitions
  then
    echo -ne "is present, "
  else
    echo -e "can not be found, ${_red}aborting${_end}."
    exit 2
fi


if grep -q $device /proc/mounts
  then
    echo "is mounted"
    if $umt /dev/$device
      then
      action="is now ${_green}unmounted${_end}"
      else
      action="unmount failed, try ${_dark_gray}cd${_end} out of the device fs?"
    fi
  else
    echo "is not mounted"
    TYP=$($bi -s TYPE | sed -e s/\"//g -e s/TYPE=// | grep $device | awk '{ print $2}' )
    echo "[$TYP]"
    case $TYP in
      ntfs)
        echo "It's ${_blue}NTFS!${_end} -umask to 0"
        $opts '-o umask=0'
        ;;
      *.fat|dosfs)
        echo "it's $TYP! -umasking all to 0"
        $opts '-o umask=0'
        ;;
      *)
        echo "it's just $TYP no special options."
        opts=''
        ;;
    esac
    if $mnt -t $TYP /dev/$device $mpoint $opts; then
      action="is now ${_red}mounted${_end} to [$mpoint]"
    else
      echo "NOTE for root:"
      echo "please append to end of sudoers file by visudo:"
      echo "# apped to file: /etc/sudoers"
      echo "# adder for /sur/bin/m utility"
      echo " %users  ALL= NOPASSWD: /sbin/mount,/sbin/umount"
      echo " %users  ALL= NOPASSWD: /usr/bin/m"
      action="${_red}not mounted${_end} to [$mpoint]"
    fi
  fi
echo -e "Device [${_green}$device${_end}] "$action"."
echo -e "thank You for using${_green} \"M\"${_end}"

exit 0
