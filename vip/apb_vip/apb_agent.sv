class apb_agent extends uvm_agent;
   `uvm_component_utils(apb_agent)

   apb_monitor    monitor;
   apb_driver     driver;
   apb_sequencer  sequencer;

   virtual apb_if apb_vif;
	apb_configuration apb_freq;
   function new (string name="apb_agent", uvm_component parent);
      super.new(name, parent);
   endfunction: new

   virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      
      if(!uvm_config_db#(virtual apb_if)::get(this, "", "apb_vif", apb_vif))
         `uvm_fatal(get_type_name(), $sformatf("Failed to get apb_if"))
      if(!uvm_config_db #(apb_configuration)::get(this,"","apb_freq", apb_freq))
         `uvm_fatal(get_type_name(), $sformatf("Failed to get apb configuration from uvm_config_db"))

      if (is_active == UVM_ACTIVE) begin
         `uvm_info(get_type_name(), $sformatf("Active APB agent is configured"), UVM_LOW)

         driver      = apb_driver::type_id::create("driver", this);
         monitor     = apb_monitor::type_id::create("monitor", this);
         sequencer   = apb_sequencer::type_id::create("sequencer", this);

         uvm_config_db#(virtual apb_if)::set(this, "driver", "apb_vif", apb_vif);
         uvm_config_db#(apb_configuration)::set(this, "driver", "apb_freq", apb_freq);
         uvm_config_db#(virtual apb_if)::set(this, "monitor", "apb_vif", apb_vif);
      end
      else begin
         `uvm_info(get_type_name(), $sformatf("Passive APB agent is configured"), UVM_LOW)

         monitor     = apb_monitor::type_id::create("monitor", this);
         uvm_config_db#(virtual apb_if)::set(this, "monitor", "apb_vif", apb_vif);
      end

   endfunction : build_phase

   virtual function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      
      if (get_is_active() == UVM_ACTIVE) begin
         driver.seq_item_port.connect(sequencer.seq_item_export);
      end
   endfunction : connect_phase

endclass: apb_agent
