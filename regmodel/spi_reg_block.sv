class spi_reg_block extends uvm_reg_block;
   `uvm_object_utils(spi_reg_block)

   rand spi_DLR_reg DLR;
   rand spi_LCR_reg LCR;
   rand spi_IER_reg IER;
   rand spi_FSR_reg FSR;
   rand spi_TBR_reg TBR;
   rand spi_RBR_reg RBR;

   uvm_reg_map apb_map;

   function new(string name="spi_reg_block");
      super.new(name, UVM_NO_COVERAGE);
   endfunction

   virtual function void build();

      DLR = spi_DLR_reg::type_id::create("DLR");
      DLR.configure(this);
      DLR.build();

      LCR = spi_LCR_reg::type_id::create("LCR");
      LCR.configure(this);
      LCR.build();

      IER = spi_IER_reg::type_id::create("IER");
      IER.configure(this);
      IER.build();

      FSR = spi_FSR_reg::type_id::create("FSR");
      FSR.configure(this);
      FSR.build();

      TBR = spi_TBR_reg::type_id::create("TBR");
      TBR.configure(this);
      TBR.build();

      RBR = spi_RBR_reg::type_id::create("RBR");
      RBR.configure(this);
      RBR.build();


      apb_map = create_map("apb_map", 'h4000_2000, 4, UVM_LITTLE_ENDIAN);

      apb_map.add_reg(LCR, `UVM_REG_ADDR_WIDTH'h00, "RW");
      apb_map.add_reg(DLR, `UVM_REG_ADDR_WIDTH'h04, "RW");
      apb_map.add_reg(IER, `UVM_REG_ADDR_WIDTH'h08, "RW");
      apb_map.add_reg(FSR, `UVM_REG_ADDR_WIDTH'h0C, "RO");
      apb_map.add_reg(TBR, `UVM_REG_ADDR_WIDTH'h10, "RW");
      apb_map.add_reg(RBR, `UVM_REG_ADDR_WIDTH'h14, "RW");

      lock_model();
      endfunction
endclass
