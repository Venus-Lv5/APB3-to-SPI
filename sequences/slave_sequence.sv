class slave_sequence extends uvm_sequence #(spi_transaction);
  `uvm_object_utils(slave_sequence)

  function new(string name = "slave_sequence");
    super.new(name);
  endfunction

	virtual task body();
		req = spi_transaction::type_id::create("req");  
      start_item(req);
      if(!req.randomize())
        `uvm_fatal(get_type_name(),$sformatf("Randomize failure"))
      `uvm_info(get_type_name(), $sformatf("Send frame from slave to dut: \n%s", req.sprint()), UVM_LOW) 
      finish_item(req);  
      get_response(rsp);
  endtask

endclass: slave_sequence
