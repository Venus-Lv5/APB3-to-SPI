`ifndef GUARD_SPI_TEST_PKG__SV
`define GUARD_SPI_TEST_PKG__SV

package test_pkg;
	import uvm_pkg::*;
	import apb_pkg::*;
	import env_pkg::*;
	import seq_pkg::*;
	import spi_regmodel_pkg::*;
	import spi_pkg::*;

	`include "spi_base_test.sv"

   `include "reg_default_test.sv"
   `include "reg_rw_test.sv"
   `include "reg_rsvd_test.sv"

	`include "spi_non_8bit_cpol0_cpha0_test.sv"
endpackage
`endif
