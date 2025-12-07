class apb_monitor extends uvm_monitor;
   `uvm_component_utils(apb_monitor)

   uvm_analysis_port #(apb_transaction) apb_observe_port;
   virtual apb_if apb_vif;

   function new (string name="apb_monitor", uvm_component parent);
      super.new(name, parent);
   endfunction

   virtual function void build_phase (uvm_phase phase);
      super.build_phase(phase);
      apb_observe_port = new("apb_observe_port", this);

      if(!uvm_config_db#(virtual apb_if)::get(this, "", "apb_vif", apb_vif))
         `uvm_fatal(get_type_name(), $sformatf("Failed to get apb_if from config_db"))

   endfunction: build_phase

   virtual task run_phase(uvm_phase phase);
   		`uvm_info("apb_monitor", "Start capture APB interface", UVM_LOW)

   		wait (apb_vif.PRESETn == 1);

   		forever begin
      		apb_transaction trans;

      		//SETUP
      		@(posedge apb_vif.PCLK iff (apb_vif.PSEL && !apb_vif.PENABLE));

      		trans = apb_transaction::type_id::create("trans", this);

      		trans.addr      = apb_vif.PADDR;
      		trans.xact_type = apb_vif.PWRITE ? apb_transaction::WRITE : apb_transaction::READ;
      		if (apb_vif.PWRITE)
         		trans.data = apb_vif.PWDATA;

      		// ACCESS: PSEL=1, PENABLE=1
      		@(posedge apb_vif.PCLK iff (apb_vif.PSEL && apb_vif.PENABLE));
      		if (!apb_vif.PWRITE)
         		trans.data = apb_vif.PRDATA;

      		trans.pslverr = apb_vif.PSLVERR;

      		`uvm_info("apb_monitor", "Finished", UVM_LOW)
      		`uvm_info("apb_monitor", $sformatf("Send trans from monitor to scoreboard: \n%s", trans.sprint()), UVM_LOW)

      		apb_observe_port.write(trans);
   		end
	endtask
endclass: apb_monitor
      
