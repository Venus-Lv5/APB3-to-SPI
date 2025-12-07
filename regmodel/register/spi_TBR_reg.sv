class spi_TBR_reg extends uvm_reg;
   `uvm_object_utils(spi_TBR_reg)

   uvm_reg_field        rsvd;
   rand uvm_reg_field   tx_data;

   function new(string name="spi_TBR_reg");
      super.new(name, 32, UVM_NO_COVERAGE);
   endfunction

   virtual function void build();
      rsvd        = uvm_reg_field::type_id::create("rsvd");
      tx_data     = uvm_reg_field::type_id::create("tx_data");

      rsvd.configure       (this, 16, 16, "RO", 1'b0, 26'b0, 1, 1, 1);
      tx_data.configure    (this, 16, 0, "WO", 1'b0, 16'b0, 1, 1, 1);
   endfunction
endclass


