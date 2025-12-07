class spi_RBR_reg extends uvm_reg;
   `uvm_object_utils(spi_RBR_reg)

   uvm_reg_field        rsvd;
   rand uvm_reg_field   rx_data;

   function new(string name="spi_RBR_reg");
      super.new(name, 32, UVM_NO_COVERAGE);
   endfunction

   virtual function void build();
      rsvd        = uvm_reg_field::type_id::create("rsvd");
      rx_data     = uvm_reg_field::type_id::create("rx_data");

      rsvd.configure       (this, 16, 16, "RO", 1'b0, 16'b0, 1, 1, 1);
      rx_data.configure    (this, 16, 0, "RO", 1'b0, 16'b0, 1, 1, 1);
   endfunction
endclass


