#!/bin/sh

#
# kudos to armbian and tkaiser
#
# source:
# https://github.com/ThomasKaiser/Knowledge/blob/master/articles/Quick_Preview_of_ROCK_5B.md
#

echo "==============================="
echo "     Power source status:"
echo "==============================="

sensors tcpm_source_psy_4_0022-i2c-4-22

echo "==============================="
echo " Power source voltage readout:"
echo "==============================="

awk '{printf ("%0.2f\n",$1/172.5); }' </sys/devices/iio_sysfs_trigger/subsystem//devices/iio\:device0/in_voltage6_raw

echo "==============================="
