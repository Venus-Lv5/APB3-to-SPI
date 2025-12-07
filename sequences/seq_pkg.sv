//=============================================================================
// Project       : SPI VIP
//=============================================================================
// Filename      : seq_pkg.sv
// Author        : Huy Nguyen
// Company       : NO
// Date          : 20-Dec-2021
//=============================================================================
// Description   : 
//
//
//
//=============================================================================
`ifndef GUARD_SPI_SEQ_PKG__SV
`define GUARD_SPI_SEQ_PKG__SV

package seq_pkg;
  import uvm_pkg::*;
  import spi_pkg::*;
  import apb_pkg::*;

  // Include your file
  `include "rsvd_sequence.sv"
  `include "slave_sequence.sv"

endpackage: seq_pkg

`endif


