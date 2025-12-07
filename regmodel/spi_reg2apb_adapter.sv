class spi_reg2apb_adapter extends uvm_reg_adapter;
   `uvm_object_utils(spi_reg2apb_adapter)

   function new(string name="spi_reg2apb_adapter");
      super.new(name);
      // Does the protocol the Agent is modeling support byte enables?
      // 0 = NO
      // 1 = YES
      supports_byte_enable = 0;

      // Does the Agent's Driver provide separate response sequence items?
      // i.e. Does the driver call seq_item_port.put()
      // and do the sequences call get_response()?
      // 0 = NO
      // 1 = YES
      provides_responses = 1;
   endfunction

   //--------------------------------------------------------------------
   // reg2bus
   //--------------------------------------------------------------------
   virtual function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
      apb_transaction apb = apb_transaction::type_id::create("apb");
      apb.xact_type = (rw.kind == UVM_WRITE)?apb_transaction::WRITE : apb_transaction::READ;
      apb.addr = rw.addr;
      apb.data = rw.data;
      `uvm_info(get_type_name(), $sformatf("reg2bus: address = 0x%0h, data = 0x%0h, kind = %0s", apb.addr, apb.data, apb.xact_type.name()), UVM_HIGH)
      return apb;
   endfunction 
  
   //--------------------------------------------------------------------
   // bus2reg
   //--------------------------------------------------------------------
   virtual function void bus2reg(uvm_sequence_item bus_item, ref uvm_reg_bus_op rw);
      apb_transaction apb;
      if (!$cast(apb, bus_item))
         `uvm_fatal(get_type_name(), $sformatf("Failed to cast bus item to apb transaction"))
      rw.kind = (apb.xact_type == apb_transaction::WRITE) ? UVM_WRITE : UVM_READ;
      rw.addr = apb.addr;
      rw.data = apb.data;
      `uvm_info(get_type_name(), $sformatf("bus2reg: address = 0x%0h, data = 0x%0h, kind = %0s, status = %0s", rw.addr, rw.data, rw.kind.name(), rw.status.name()), UVM_HIGH)

   endfunction 

endclass
