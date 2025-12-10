class spi_FSR_reg extends uvm_reg;
   `uvm_object_utils(spi_FSR_reg)

   uvm_reg_field        rsvd;
   rand uvm_reg_field   rx_full_status;
   rand uvm_reg_field   rx_empty_status;
   rand uvm_reg_field   tx_full_status;
   rand uvm_reg_field   tx_empty_status;

   function new(string name="spi_FSR_reg");
      super.new(name, 32, UVM_NO_COVERAGE);
   endfunction

   virtual function void build();
      rsvd              = uvm_reg_field::type_id::create("rsvd");
      rx_full_status    = uvm_reg_field::type_id::create("rx_full_status");
      rx_empty_status   = uvm_reg_field::type_id::create("rx_empty_status");
      tx_full_status    = uvm_reg_field::type_id::create("tx_full_status");
      tx_empty_status   = uvm_reg_field::type_id::create("tx_empty_status");

      rsvd.configure             	(this, 28, 4, "RO", 1'b1, 28'b0, 1, 1, 1);
      rx_full_status.configure  	(this, 1, 3, "RO", 1'b1, 1'b1, 1, 1, 1);
      rx_empty_status.configure  	(this, 1, 2, "RO", 1'b1, 1'b0, 1, 1, 1);
      tx_full_status.configure  	(this, 1, 1, "RO", 1'b1, 1'b1, 1, 1, 1);
      tx_empty_status.configure  	(this, 1, 0, "RO", 1'b1, 1'b0, 1, 1, 1);
   endfunction
endclass


