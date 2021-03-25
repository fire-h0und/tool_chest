#!/bin/bash

echo "setting keyboard switching options:"

setxkbmap -model pc104 -layout us,rs,rs -variant  ,yz,latinunicodeyz -option grp:lalt_lshift_toggle,altwin:menu,grp_led:scroll

