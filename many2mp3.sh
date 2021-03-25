#!/bin/bash

version=0.3
echo "Audio file converter version V${version}"
echo "frontend for mplayer from MplayerHQ.hu"

for TYPE in "wav" "ogg" "m4a" "avi" "mp4" "flv" "mpc"
  {
  echo "=====================testing [$TYPE] files:================================"
  for FILE in *.$TYPE
    {
    echo "testing file [${FILE}]"
    if  [ -f "${FILE}" ]; then
      rm -v audiodump.wav
      #ls -Q "${FILE}"
      mplayer -noconsolecontrols -msglevel all=0 -benchmark -vo null -vc null -ao pcm:fast "$FILE"
      OFIL=$(echo $FILE | awk -F. '{print $1".mp3"}' )
      lame -m s --preset insane audiodump.wav "$OFIL"
    fi
    }
  echo "========================================================================="
  }
rm -v audiodump.wav


