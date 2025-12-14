+incdir+${SPI_IP_VERIF_PATH}/sequences
+incdir+${SPI_IP_VERIF_PATH}/testcases
+incdir+${SPI_IP_VERIF_PATH}/tb
+incdir+${SPI_IP_VERIF_PATH}/regmodel
+incdir+${SPI_IP_VERIF_PATH}/regmodel/register

// Compilation VIP design (agent) list
-f ${SPI_VIP_ROOT}/spi_vip.f
-f ${APB_VIP_ROOT}/apb_vip.f

// Compilation Environment
${SPI_IP_VERIF_PATH}/regmodel/register/spi_register_pkg.sv
${SPI_IP_VERIF_PATH}/regmodel/spi_regmodel_pkg.sv
${SPI_IP_VERIF_PATH}/tb/env_pkg.sv
${SPI_IP_VERIF_PATH}/sequences/seq_pkg.sv
${SPI_IP_VERIF_PATH}/testcases/test_pkg.sv
${SPI_IP_VERIF_PATH}/tb/testbench.sv

