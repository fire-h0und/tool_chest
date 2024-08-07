#!/bin/sh
V="0.5-rc1"

# changelog:
# ==============
# 0.5
# * - added upgrading the driver along with kernel module with sbottools
# TODO check for exact nvidia driver version prior to updating
#      and optionally ask user to pick the right one

echo -ne ".\n.\n.\n."
echo "   BOOT UPDATER-"$V
echo "========================================"
echo "adjusting boot to upgraded kernel"
echo "NOTE: this is just a helper, ensure that all the files are"
echo "properly configured beforehand!"
echo "========================================"
# checking for mandatory components:
for X in /usr/sbin/grub-mkconfig /sbin/mkinitrd
  do
  if [[ -x $X ]]
    then
    echo "found [$X]"
  else
    echo "[$X] not found, make sure it is installed."
    echo "-Fatal error, exiting."
    exit 2
  fi
done
#TODO:
# add bootloader discrimination
# add support for elilo and refind
# add suppport for sbopkg

if [[ -x /usr/sbin/sboinstall ]]
  then
  echo "-detected sbotools"
  sbo_i=/usr/sbin/sboinstall
  sbo_t()
  {
  True
  }
  echo "Refreshing sbo-tools cache just in case: (stand by please)..."
  /usr/sbin/sbocheck
else
  echo "-couldn't detect sbotools"
fi

rk=$(uname -r)
echo "And we seem to be running on $rk kernel"
echo "========================================"

#loop over the symlinks in /boot/
for k in /boot/vmlinuz*
do
  #echo $k; file -b $k
  if file -b $k | grep -q "symbolic link"
    then echo "we have detected an symlink, skippin the symlink"
  fi
  if file -b $k | grep -q "Linux kernel"
    then echo "we have detected an kernel:"
    s=${k#*-}
    v=${s#*-}
    t=${s%-*}
    echo "it is an " $t "version" $v
    if [ "X"$t == "Xgeneric" ]
      then
      echo "does the -generic we're just detected need some maintainence:"
      #check if initrd is needed!
      for i in /boot/initrd-$v*
      do
        if ( file -b $i | grep -q "data" )
          then
            echo "found apparently matching initrd, skipping further action!"
          else
            #check if mkinitrd has our kernel entry
            for kv in $(grep "KERNEL_VERSION=" /etc/mkinitrd.conf | grep -v "uname" | sed "s/KERNEL_VERSION=//" | sed 's/"//g')
              do
              if [ "X"$kv == "X"$v ] && [ "X"$kv != "X" ]
                then
                echo "initrd seems to be configured already"
                else
                echo "editing /etc/mkinitrd.conf!"
                #do it!
                oldline='KERNEL_VERSION="'$kv'"'
                newline='KERNEL_VERSION="'$v'"'
                echo "["$oldline"]-->["$newline"]"
                sed -i'.backup' "s/$oldline/$newline/" /etc/mkinitrd.conf
                grep $newline /etc/mkinitrd.conf
              fi
            done
            #a matching mkintrd.conf is present now on
            #proceed to make an initrd for the still orphan -generic kernel
            /sbin/mkinitrd -F
          fi
      done
    fi
    #not an -generic, no further action needed
  fi
  #not a krenel, but a symlink, no action needed
done
#letting grup ovedo the config file now:
echo "========================================"
echo "Setting up boot loader:"
echo "========================================"

#
#
#

/usr/sbin/grub-mkconfig -o /boot/grub/grub.cfg


# here on we check if there is an binary nvidia blob installed:
echo "========================================"
nv_i=$(which nvidia-installer)
echo "found:[${nv_i}]"
echo "========================================"

if [[ -x $nv_i ]]
  then
  echo "NVidia blob is present!"
  ##TODO detect if version is good or not
  #in grep -E "nvidia-kernel|nvidia-driver" /var/log/sbocheck.log
  # and check if any and wich legacy driver is used
  # currently we blindly steamroll with the default package
  if $sbo_t
    then
    #try let sbotools handle the Nvidia blob
    #(-driver and -kernel are split across two packages)
    KERNEL=$v $sbo_i --reinstall -R -r nvidia-kernel && KERNEL=$v $sbo_i --reinstall -R -r nvidia-driver
    # --reinstall    rebuild a package even if present (our case here)
    # -R perfrom no dependency resolution
    # -r skip interaction with the user
  else
    nv_v=`$nv_i -i | grep version | awk -F':' '{print $3}' | sed "s/)\.//"`

    k_v=$(uname -r)

    echo "Nvidia driver version:"${nv_v}" running kernel version:"${k_v}"; earlier kernel detected:"${v}
    if [ "X"$k_v != "X"$v ] && [ "X"$v != "X" ]
      then
      echo "kernel mismatch, we default to the "${v}" kernel detected kernel in /boot/"
      nv_d=`locate ${nv_v} | grep -E "NVIDIA|\.run"`
      if [ "X"$nv_d != "X" ]
        then
        echo "found downloaded installer:"
        echo "["${nv_d}"]"
        sh $nv_d -ui=none -K -k ${v}
      else
        echo -e "can't locate the installer package, did you run \n#updatedb\n recently?"
      fi
      else
        echo "both kernels match or no kernel detected in /boot (?)"
        $nv_i -K -k ${k_v}
      fi
    fi
else
  echo "no NVidia blob detected."
fi

