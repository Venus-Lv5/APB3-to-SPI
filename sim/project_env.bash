#!/bin/bash -f

#setup_dva

## UVM library path
#export UVM_HOME=/ictc/other/tools/QuestaDVA/questasim/verilog_src/uvm-1.2

## Verify root path
export SPI_IP_VERIF_PATH=./..

export APB_VIP_ROOT=$SPI_IP_VERIF_PATH/vip/apb_vip
export SPI_VIP_ROOT=$SPI_IP_VERIF_PATH/vip/spi_vip
