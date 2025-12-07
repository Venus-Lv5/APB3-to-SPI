
`ifndef GUARD_SPI_PKG__SV
`define GUARD_SPI_PKG__SV

package spi_pkg;
  import uvm_pkg::*;

  // Include your file
  `include "spi_error_catcher.sv"
  `include "spi_configuration.sv"
  `include "spi_transaction.sv"
  `include "spi_sequencer.sv"
  `include "spi_driver.sv"
  `include "spi_monitor.sv"
  `include "spi_agent.sv"

endpackage: spi_pkg

`endif

