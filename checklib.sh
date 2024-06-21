#!/bin/sh

# version 1.0.1

# kudos to Petri Kaukasoina
# from linuxquestions.org
#echo "usage: $0 <SONAME>"
#echo
#echo 'objdump -p /usr/lib64/libsoup-2.4.so.1.11.2 | grep SONAME'
#echo 'SONAME               libsoup-2.4.so.1'

[ $# -lt 1 ] && echo 'List packages with any binaries using the shared library' && echo 'Usage, for example: ' $0 'libavcodec.so.59' && exit 1
cd /var/adm/packages
for pkg in *; do
( cd /
  while read line; do
    [ "$line" == "FILE LIST:" ] && break
  done
  while read f; do
    [ -x "$f" -a -f "$f" -a -r "$f" ] && grep -Eq "$1" "$f" && echo "$pkg": /"$f"
  done 
) < $pkg
done
