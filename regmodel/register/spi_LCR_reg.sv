class spi_LCR_reg extends uvm_reg;
   `uvm_object_utils(spi_LCR_reg)

   uvm_reg_field        rsvd;
   rand uvm_reg_field   SS;
   rand uvm_reg_field   CDTE;
   rand uvm_reg_field   CPHA;
   rand uvm_reg_field   CPOL;
   rand uvm_reg_field   WLS;

   function new(string name="spi_LCR_reg");
      super.new(name, 32, UVM_NO_COVERAGE);
   endfunction

   virtual function void build();
      rsvd  = uvm_reg_field::type_id::create("rsvd");
      SS    = uvm_reg_field::type_id::create("SS");
      CDTE  = uvm_reg_field::type_id::create("CDTE");
      CPHA  = uvm_reg_field::type_id::create("CPHA");
      CPOL  = uvm_reg_field::type_id::create("CPOL");
      WLS   = uvm_reg_field::type_id::create("WLS");

      rsvd.configure (this, 26, 7, "RO", 1'b0, 26'b0, 1, 1, 1);
      SS.configure   (this, 2, 4, "RW", 1'b0, 1'b0, 1, 1, 1);
      CDTE.configure (this, 1, 3, "RW", 1'b0, 1'b0, 1, 1, 1);
      CPHA.configure (this, 1, 2, "RW", 1'b0, 1'b0, 1, 1, 1);
      CPOL.configure (this, 1, 1, "RW", 1'b0, 1'b0, 1, 1, 1);
      WLS.configure  (this, 1, 0, "RW", 1'b0, 1'b0, 1, 1, 1);
   endfunction
endclass


