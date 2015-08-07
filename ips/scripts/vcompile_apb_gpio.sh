#!/bin/tcsh

source scripts/colors.sh

echo "${Green}--> Compiling APB GPIO INTERFACE... ${NC}"

echo "${Green}library: apb_gpio_lib ${NC}"
rm -rf ${MSIM_LIBS_PATH}/apb_gpio_lib

vlib ${MSIM_LIBS_PATH}/apb_gpio_lib
vmap apb_gpio_lib ${MSIM_LIBS_PATH}/apb_gpio_lib

echo "${Green}Compiling component:   ${Brown} axi_gpio ${NC}"
echo "${Red}"

vlog -work apb_gpio_lib -quiet -sv ${IPS_PATH}/apb/apb_gpio/apb_gpio.sv    || exit 1

echo "${Cyan}--> APB GPIO INTERFACE compilation complete! ${NC}"

