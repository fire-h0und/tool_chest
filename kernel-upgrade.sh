#!/bin/sh
V="0.6-rc2"

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
boottech=$([ -d /sys/firmware/efi ] && echo UEFI || echo BIOS)

echo "Boot technology [${boottech}] detected."

# checking for mandatory components:
for X in /sbin/mkinitrd /sbin/blkid /usr/sbin/efibootmgr 
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

bootorder=$(/usr/sbin/efibootmgr | grep "BootOrder:" | sed "s/BootOrder://" )
bootloader=$(/usr/sbin/efibootmgr | grep "BootOrder:" | sed "s/BootOrder://" | awk -F',' '{print $1}' | sed "s/ //g" )
bootentry=$(/usr/sbin/efibootmgr | grep "Boot${bootloader}" )
bootpath=$(/usr/sbin/efibootmgr | grep "Boot${bootloader}" | awk -F'\t' '{print $2}')
bootpartition=$(/sbin/blkid | grep $(/usr/sbin/efibootmgr | grep "Boot${bootloader}" | awk -F'\t' '{print $2}' | awk -F',' '{print $3}') | awk -F':' '{print $1}' )
mountpoint=$(grep $bootpartition /etc/mtab | awk '{print $2}' )
bootfile=$(/usr/sbin/efibootmgr | grep "Boot${bootloader}" | awk -F'/' '{print $2}' | sed -e "s/File(//" -e "s/)//" -e 's/\\/\//g' )


if echo $bootfile | grep "refind_x64.efi"; then 
bootmanager="refind" 
fi
if echo $bootfile | grep "elilo.efi"; then 
bootmanager="elilo" 
fi
if echo $bootfile | grep "grubx64.efi"; then 
bootmanager="grub" 
fi
if echo $bootfile | grep -I "bootx64.efi"; then 
bootmanager="unknown" 
fi

case $bootmanager in
  "grub")
     -o /boot/grub/grub.cfg
  if [[ -x /usr/sbin/grub-mkconfig ]]; then
    echo "[/usr/sbin/grub-mkconfig] detected."
  else
    echo "[/usr/sbin/grub-mkconfig] not found, make sure it is installed."
    echo "-Fatal error, exiting."
    exit 2
  fi
  ;;
  "refind")
  if [[ -x /usr/sbin/refind-install ]]; then
    echo "[/usr/sbin/refind-install] detected."
  else
    echo "[/usr/sbin/refind-install] not found, make sure it is installed."
    echo "-Fatal error, exiting."
    exit 2
  fi
  ;;
  "elilo")
  echo "Sorry, [elilo] not implemented yet!"
  ;;
  *)
  echo "Sorry, not implemented yet!"
esac


#TODO:
# add support for elilo

if [[ -x /usr/sbin/sboinstall ]]
  then
  echo "-detected sbotools"
  sbo_i=/usr/sbin/sboinstall
  sbo_t()
  {
  True
  }
  #echo "Refreshing sbo-tools cache just in case: (stand by please)..."
  #/usr/sbin/sbocheck
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

case $bootmanager in
  "grub")
    echo "processing for grub:"
    /usr/sbin/grub-mkconfig -o /boot/grub/grub.cfg
  ;;
  "refind")
  conffile=$(echo $mountpoint$bootfile | sed 's/refind_x64.efi/refind.conf/' )
    echo "processing for rEFInd [${conffile}] and [${rk}]>[$v]:"
    erk=$(echo $rk | sed 's/\./\\./g' )
    ev=$(echo $v | sed 's/\./\\./g' )

    grep "$rk" $conffile

    # find the recent kernels boot entry
    oldkernelline=$( grep "vmlinuz-" $conffile | grep "$rk" )
    eoldkernelline=$( echo "${oldkernelline}" | sed 's/\//\\\//g')
    echo -n "[${oldkernelline}]>"
    if [ "X${oldkernelline}" != "X" ]; then
      newkernelline=$( echo "$oldkernelline" | sed "s/${erk}/${ev}/" )
      enewkernelline=$( echo "${newkernelline}" | sed 's/\//\\\//g')
      echo "[${newkernelline}]"
      # edit in place to match the new kernel
      sed -i'.backup' "s/${eoldkernelline}/${enewkernelline}/" $conffile
    fi
    oldinitrdline=$( grep "initrd-" $conffile | grep "$rk" )
    eoldinitrdline=$( echo "${oldinitrdline}" | sed 's/\//\\\//g')
    echo -n "[${oldinitrdline}]>"
    if [ "X${oldinitrdline}" != "X" ]; then
      newinitrdline=$( echo "$oldinitrdline" | sed "s/${erk}/${ev}/" )
      enewinitrdline=$( echo "${newinitrdline}" | sed 's/\//\\\//g')
      echo "[${newinitrdline}]"
      # edit in place to match the new kernel
      sed -i'.backup' "s/${eoldinitrdline}/${enewinitrdline}/" $conffile
    fi
    grep "$v" $conffile
  ;;
  *)
  echo "Sorry, processing for this not implemented yet!"
esac

# here on we check if there is an binary nvidia blob installed:
echo "========================================"
if locate nvidia-installer | grep "bin/"; then
  nv_i=$(which nvidia-installer)
  echo "found:[${nv_i}]"
else
  echo "no NVidia blob detected."
fi
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
fi
