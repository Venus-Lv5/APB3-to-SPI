class spi_DLR_reg extends uvm_reg;
   `uvm_object_utils(spi_DLR_reg)

   uvm_reg_field        rsvd;
   rand uvm_reg_field   div_val;

   function new(string name="spi_DLR_reg");
      super.new(name, 32, UVM_NO_COVERAGE);
   endfunction

   virtual function void build();
      rsvd  = uvm_reg_field::type_id::create("rsvd");
      div_val    = uvm_reg_field::type_id::create("div_val");

      rsvd.configure       (this, 24, 8, "RO", 1'b0, 24'b0, 1, 1, 1);
      div_val.configure    (this, 8, 0, "RW", 1'b0, 8'b0, 1, 1, 1);
   endfunction
endclass


