`ifndef GUARD_SPI_ENV_PKG__SV
`define GUARD_SPI_ENV_PKG__SV

package env_pkg;
	import uvm_pkg::*;
	import spi_pkg::*;
	import apb_pkg::*;
	import spi_regmodel_pkg::*;

	`include "spi_scoreboard.sv"
	`include "spi_environment.sv"
endpackage 

`endif
