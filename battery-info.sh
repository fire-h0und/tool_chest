#!/bin/sh
# This program gets the battery info from PMU
# Voltage and current charging/discharging
#
# cest73:
# on Slackware needs:
# install: i2c-tools
# apply: modprobe i2c-dev
#
# Nota : temperature can be more than real because of self heating
#######################################################################
# Copyright (c) 2014 by RzBo, Bellesserre, France
# (P)atch by cest73@ya.ru 2017 (charge/discahrge registers swapped)
#
# Permission is granted to use the source code within this
# file in whole or in part for any use, personal or commercial,
# without restriction or limitation.
#
# No warranties, either explicit or implied, are made as to the
# suitability of this code for any purpose. Use at your own risk.
#######################################################################

# force ADC enable for battery voltage and current
i2cset -y -f 0 0x34 0x82 0xC3

################################
#read Power status register @00h
POWER_STATUS=$(i2cget -y -f 0 0x34 0x00)
#echo $POWER_STATUS

BAT_STATUS=$(($(($POWER_STATUS&0x02))/2))  # divide by 2 is like shifting rigth 1 times
#echo $(($POWER_STATUS&0x02))
echo " BAT_STATUS= "$BAT_STATUS
# echo $BAT_STATUS

################################
#read Power OPERATING MODE register @01h
POWER_OP_MODE=$(i2cget -y -f 0 0x34 0x01)
#echo $POWER_OP_MODE

CHARG_IND=$(($(($POWER_OP_MODE&0x40))/64))  # divide by 64 is like shifting rigth 6 times
#echo $(($POWER_OP_MODE&0x40))
echo " CHARG_IND= "$CHARG_IND
# echo $CHARG_IND

BAT_EXIST=$(($(($POWER_OP_MODE&0x20))/32))  # divide by 32 is like shifting rigth 5 times
#echo $(($POWER_OP_MODE&0x20))
echo " BAT_EXIST= "$BAT_EXIST
# echo $BAT_EXIST

################################
#read Charge control register @33h
CHARGE_CTL=$(i2cget -y -f 0 0x34 0x33)
echo " CHARGE_CTL= "$CHARGE_CTL
# echo $CHARGE_CTL

################################
#read Charge control register @34h
CHARGE_CTL2=$(i2cget -y -f 0 0x34 0x34)
echo " CHARGE_CTL2= "$CHARGE_CTL2
# echo $CHARGE_CTL2

################################
#read battery voltage    79h, 78h    0 mV -> 000h,    1.1 mV/bit    FFFh -> 4.5045 V
BAT_VOLT_LSB=$(i2cget -y -f 0 0x34 0x79)
BAT_VOLT_MSB=$(i2cget -y -f 0 0x34 0x78)

#echo $BAT_VOLT_MSB $BAT_VOLT_LSB

BAT_BIN=$(( $(($BAT_VOLT_MSB << 4)) | $(($(($BAT_VOLT_LSB & 0xF0)) >> 4)) ))

BAT_VOLT=$(echo " ($BAT_BIN*1.1) "|bc)
echo " Battery voltage = " $BAT_VOLT "mV "

###################
#read Battery Discharge Current    7Ch, 7Dh    0 mV -> 000h,    0.5 mA/bit    FFFh -> 4.095 V
BAT_IDISCHG_LSB=$(i2cget -y -f 0 0x34 0x7D)
BAT_IDISCHG_MSB=$(i2cget -y -f 0 0x34 0x7C)

#echo $BAT_IDISCHG_MSB $BAT_IDISCHG_LSB

BAT_IDISCHG_BIN=$(( $(($BAT_IDISCHG_MSB << 4)) | $(($(($BAT_IDISCHG_LSB & 0xF0)) >> 4)) ))

BAT_IDISCHG=$(echo " ($BAT_IDISCHG_BIN*0.5) "|bc)
echo " Battery discharge current = " $BAT_IDISCHG "mA "

###################
#read Battery Charge Current    7Ah, 7Bh    0 mV -> 000h,    0.5 mA/bit    FFFh -> 4.095 V
BAT_ICHG_LSB=$(i2cget -y -f 0 0x34 0x7B)
BAT_ICHG_MSB=$(i2cget -y -f 0 0x34 0x7A)

#echo $BAT_ICHG_MSB $BAT_ICHG_LSB

BAT_ICHG_BIN=$(( $(($BAT_ICHG_MSB << 4)) | $(($(($BAT_ICHG_LSB & 0xF0)) >> 4)) ))

BAT_ICHG=$(echo " ($BAT_ICHG_BIN*0.5) "|bc)
echo " Battery charge current = " $BAT_ICHG "mA "
