#!/bin/sh
V="0.3-rc1"
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
#default EFI path:
efi_path="/boot/efi/EFI/Slackware"
boot_path="/boot"
rk=$(uname -r)
echo "And we seem to be running on $rk kernel"
echo "========================================"

#TODO:
# check for other bootloaders too

#loop over the symlinks in /boot/
for k in $boot_path/$vmlinuz*
do
  #echo $k; file -b $k
#  if file -b $k | grep -q "symbolic link"
#    then echo "skipping the symlink (${k})"
#  fi
  if file -b $k | grep -q "Linux kernel"
    then echo "we have detected an kernel image:"
    s=${k#*-}
    v=${s#*-}
    t=${s%-*}
    echo "it is an " $t "version" $v
    if [ "X"$t == "Xgeneric" ]
      then
      echo "checking if the -generic needs any maintainence:"
      for i in $boot_path/initrd-$v*
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
                echo "initrd seems to be configured already."
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
            #we have appropriate mkintrd.conf now on
            #proceed to make a initrd for the orphan -generic kernel
            /sbin/mkinitrd -F
            new_initrd="${boot_path}/initrd-${v}.gz"
            ####
            cp -vu $new_initrd $efi_path
          fi
      done
    fi
    new_kernel="${boot_path}/vmlinuz-${s}"
    cp -vu $new_kernel $efi_path
    echo "done processing ${new_kernel} kernel."
    #not an -generic, no further action needed
  fi
  #not a krenel, but a symlink, no action needed
done

#TODO:
#
# check if grub, elilo or other supported bootloader is in use:
#

#letting grup overdo the config file now:
echo /usr/sbin/grub-mkconfig -o /boot/grub/grub.cfg

# preparing for UEFI bootloader 
# (by copying over the initrd and vmlinuz image)

echo "Please edit the elilo conf fille accordingly"


# here on we check if there is an binary nvidia blob installed:
echo "========================================"
nv_i=$(which nvidia-installer)
echo "found:"$nv_i
echo "========================================"

if [[ -x $nv_i ]]
  then
   echo "NVidia blob is present!"
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
         echo -e "can't locate the installer package, did you ran \n#updatedb\n recently?"
       fi
     else
       echo "both kernels match or no kernel detected in /boot (?)"
       $nv_i -K -k ${k_v}
     fi
  else
   echo "no NVidia blob detected."
fi
