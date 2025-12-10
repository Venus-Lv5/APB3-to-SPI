class apb_driver extends uvm_driver #(apb_transaction);
   `uvm_component_utils(apb_driver)

   virtual apb_if apb_vif;
   apb_configuration apb_freq;

   function new (string name="apb_driver", uvm_component parent);
      super.new(name, parent);
   endfunction

   virtual function void build_phase (uvm_phase phase);
      super.build_phase(phase);

      if (!uvm_config_db#(virtual apb_if)::get(this, "", "apb_vif", apb_vif))
         `uvm_fatal(get_type_name(), $sformatf("Failed to get apb_if from uvm_config. Plz check!"))
      if (!uvm_config_db#(apb_configuration)::get(this, "", "apb_freq", apb_freq))
         `uvm_fatal(get_type_name(), $sformatf("Failed to get apb_configuration from uvm_config. Plz check!"))
   endfunction: build_phase


   virtual task run_phase(uvm_phase phase);
      apb_transaction seq, rsp;
      forever begin
         seq_item_port.get_next_item(seq);
                  	
         	wait(apb_vif.PRESETn == 1);
         	
         //SETUP PHASE
         @(posedge apb_vif.PCLK);
         apb_vif.PSEL            <= 1'b1;
         apb_vif.PADDR           <= seq.addr;
         apb_vif.PWRITE          <= seq.xact_type;
         apb_vif.PENABLE         <= 1'b0;

         if (seq.xact_type == apb_transaction::WRITE)
            apb_vif.PWDATA       <= seq.data;

         `uvm_info("run_phase", $sformatf("Start %s transaction - ADDR: 0x%0h", seq.xact_type? "WRITE" : "READ", seq.addr), UVM_LOW)

         //ACCESS PHASE
         @(posedge apb_vif.PCLK);
         apb_vif.PENABLE          <= 1;

         wait(apb_vif.PREADY == 1); #1;
         if (seq.xact_type == apb_transaction::READ)
            seq.data             = apb_vif.PRDATA;

         //IDLE phase 
         @(posedge apb_vif.PCLK);
         apb_vif.PSEL            <= 1'b0;
         apb_vif.PENABLE         <= 1'b0;
         apb_vif.PWRITE          <= 1'b0;
         apb_vif.PADDR           <= 32'b0;
         apb_vif.PWDATA          <= 32'b0;




         $cast(rsp, seq.clone());
         rsp.set_id_info(seq);

         seq_item_port.put(rsp);

         `uvm_info("run_phase", $sformatf("Completed %s transaction - ADDR: 0x%0h - DATA: 0x%0h", seq.xact_type? "WRITE" : "READ", seq.addr, seq.data), UVM_LOW)

         seq_item_port.item_done();
      end
   endtask: run_phase
endclass







