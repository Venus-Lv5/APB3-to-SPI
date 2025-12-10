`timescale 1ns/1ps
module testbench;
   import uvm_pkg::*;
   import test_pkg::*;
   import spi_pkg::*;
   import apb_pkg::*;

   apb_if apb_vif();
   spi_if spi_vif();
   apb_configuration apb_freq;

   apb_spi_top u_dut(
      .i_clk(apb_vif.PCLK),
      .i_rst_n(apb_vif.PRESETn),
      .i_psel(apb_vif.PSEL),
      .i_penable(apb_vif.PENABLE),
      .i_pwrite(apb_vif.PWRITE),
      .i_paddr(apb_vif.PADDR),
      .i_pwdata(apb_vif.PWDATA),
      .o_prdata(apb_vif.PRDATA),
      .o_pready(apb_vif.PREADY),
      .o_pslverr(apb_vif.PSLVERR),
      .o_int(apb_vif.interrupt),

      .o_SCLK(spi_vif.SCLK),
      .o_MOSI(spi_vif.MOSI),
      .i_MISO(spi_vif.MISO),
      .o_SS0(spi_vif.SS[0]),
      .o_SS1(spi_vif.SS[1]),
      .o_SS2(spi_vif.SS[2]),
      .o_SS3(spi_vif.SS[3])
   );

   initial begin
      apb_vif.PRESETn = 0;
      #100ns; apb_vif.PRESETn = 1;
   end
   
	initial begin : gen_pclk
	   apb_freq = apb_configuration::type_id::create("apb_freq");
	   while (!uvm_config_db#(apb_configuration)::get(null, "*", "apb_freq", apb_freq)) begin
         #0;
      end
	   apb_vif.PCLK = 0;
	   forever begin
	      #(apb_freq.period/2);
	      apb_vif.PCLK = ~apb_vif.PCLK;
	   end
	end

   initial begin
      uvm_config_db#(virtual apb_if)::set(uvm_root::get(), "uvm_test_top", "apb_vif", apb_vif);
      uvm_config_db#(virtual spi_if)::set(uvm_root::get(), "uvm_test_top", "spi_vif", spi_vif);
      uvm_config_db#(apb_configuration)::get(null, "*", "apb_freq", apb_freq);
         

      run_test();
   end
   
endmodule
