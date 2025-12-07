class rsvd_sequence extends uvm_sequence #(apb_transaction);
   `uvm_object_utils(rsvd_sequence);

   int rsvd_addr;

   function new(string name = "rsvd_sequence");
      super.new(name);
   endfunction

   virtual task body();
      rsvd_addr   = $urandom_range(32'h4000_2018, 32'h4000_2FFF);
      req         = apb_transaction::type_id::create("req");

      start_item(req);

      if (req.randomize() with {
         addr        == rsvd_addr;
         xact_type   == apb_transaction::WRITE;
         })
         `uvm_info(get_type_name(), $sformatf("Send req to driver: \n%s", req.sprint()), UVM_LOW)
      else
         `uvm_fatal(get_type_name(), "Randomize Failed")

      finish_item(req);
      get_response(rsp);

      req = apb_transaction::type_id::create("req");
      start_item(req);

      if(req.randomize() with {
         addr        == rsvd_addr;
         xact_type   == apb_transaction::READ;
         })
         `uvm_info(get_type_name(), $sformatf("Send seq to driver: \n%s", req.sprint()), UVM_LOW)
      else
         `uvm_fatal(get_type_name(), "Randomize Failed")

      finish_item(req);
      get_response(rsp);
   endtask: body
         
endclass
