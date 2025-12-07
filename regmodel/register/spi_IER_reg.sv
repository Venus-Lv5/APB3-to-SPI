class spi_IER_reg extends uvm_reg;
   `uvm_object_utils(spi_IER_reg)

   uvm_reg_field        rsvd;
   rand uvm_reg_field   en_rx_fifo_full;
   rand uvm_reg_field   en_rx_fifo_empty;
   rand uvm_reg_field   en_tx_fifo_full;
   rand uvm_reg_field   en_tx_fifo_empty;

   function new(string name="spi_IER_reg");
      super.new(name, 32, UVM_NO_COVERAGE);
   endfunction

   virtual function void build();
      rsvd              = uvm_reg_field::type_id::create("rsvd");
      en_rx_fifo_full   = uvm_reg_field::type_id::create("en_rx_fifo_full");
      en_rx_fifo_empty  = uvm_reg_field::type_id::create("en_rx_fifo_empty");
      en_tx_fifo_full   = uvm_reg_field::type_id::create("en_tx_fifo_full");
      en_tx_fifo_empty  = uvm_reg_field::type_id::create("en_tx_fifo_empty");

      rsvd.configure                (this, 28, 4, "RO", 1'b0, 28'b0, 1, 1, 1);
      en_rx_fifo_full.configure     (this, 1, 3, "RW", 1'b0, 1'b0, 1, 1, 1);
      en_rx_fifo_empty.configure    (this, 1, 2, "RW", 1'b0, 1'b0, 1, 1, 1);
      en_tx_fifo_full.configure     (this, 1, 1, "RW", 1'b0, 1'b0, 1, 1, 1);
      en_tx_fifo_empty.configure    (this, 1, 0, "RW", 1'b0, 1'b0, 1, 1, 1);
   endfunction
endclass


