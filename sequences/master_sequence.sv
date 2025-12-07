class master_sequence extends uvm_sequence #(spi_transaction);
  `uvm_object_utils(master_sequence)

  function new(string name = "master_sequence");
    super.new(name);
  endfunction

  virtual task body();
    for(int i = 1; i < 4; i++) begin 
      req = spi_transaction::type_id::create("req");  
      start_item(req);
      if(i!=3) begin
        forever begin
          if(!req.randomize())
            `uvm_fatal(get_type_name(),$sformatf("Randomize failure"))
          if(req.data[7:0] != 8'hFF)
            break;
        end
      end
      else
        req.data = 16'hFFFF;
      finish_item(req);  
      `uvm_info(get_type_name(),$sformatf("#%0d Send req to driver:\n%s", i, req.sprint()),UVM_LOW)
      get_response(rsp);
      if(rsp.data != req.data) begin
        `uvm_error(get_type_name(),$sformatf("#%0d Mismatch data between Sequencer and Driver", i))
        `uvm_info(get_type_name(), $sformatf("Request data: 16'h%0h, Response data: 16'h%0h", req.data, rsp.data),UVM_LOW)
      end 
      `uvm_info(get_type_name(), "master_sequence DONE", UVM_LOW)

    end
  endtask

endclass: master_sequence
