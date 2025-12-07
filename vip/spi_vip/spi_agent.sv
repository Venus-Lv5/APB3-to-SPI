class spi_agent extends uvm_agent;
   `uvm_component_utils(spi_agent)

   virtual spi_if    	spi_vif;
   virtual apb_if		apb_vif;
   
   spi_configuration cfg;
   spi_driver        driver;
   spi_monitor       monitor;
   spi_sequencer     sequencer;

   function new(string name="spi_agent", uvm_component parent);
      super.new(name, parent);
   endfunction

   virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      
      if(!uvm_config_db #(virtual spi_if)::get(this,"","spi_vif", spi_vif))
         `uvm_fatal(get_type_name(), $sformatf("Failed to get spi_vif from uvm_config_db"))
      if(!uvm_config_db #(virtual apb_if)::get(this,"","apb_vif", apb_vif))
         `uvm_fatal(get_type_name(), $sformatf("Failed to get spi_vif from uvm_config_db"))
      if(!uvm_config_db #(spi_configuration)::get(this,"","cfg", cfg))
         `uvm_fatal(get_type_name(), $sformatf("Failed to get cfg from uvm_config_db"))
  
      if(is_active == UVM_ACTIVE) begin 
         `uvm_info(get_type_name(), $sformatf("Active agent is configured"), UVM_LOW)
         sequencer = spi_sequencer::type_id::create("sequencer", this);
         driver = spi_driver::type_id::create("driver", this);
         monitor = spi_monitor::type_id::create("monitor", this);
    
         uvm_config_db #(virtual spi_if)::set(this,"driver","spi_vif", spi_vif);
         uvm_config_db #(virtual spi_if)::set(this,"monitor","spi_vif", spi_vif);
         uvm_config_db #(virtual apb_if)::set(this,"monitor","apb_vif", apb_vif);
         uvm_config_db #(spi_configuration)::set(this,"driver","cfg", cfg);
         uvm_config_db #(spi_configuration)::set(this,"monitor","cfg", cfg);
      end
      else begin
         `uvm_info(get_type_name(), $sformatf("Passive agent is configured"), UVM_LOW)  
         monitor = spi_monitor::type_id::create("monitor", this);

         uvm_config_db #(virtual spi_if)::set(this,"monitor","spi_vif", spi_vif);
         uvm_config_db #(virtual apb_if)::set(this,"monitor","apb_vif", apb_vif);
         uvm_config_db #(spi_configuration)::set(this,"monitor","cfg", cfg);
      end
   endfunction : build_phase

   virtual function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      if(get_is_active() == UVM_ACTIVE)
         driver.seq_item_port.connect(sequencer.seq_item_export);
   endfunction: connect_phase

endclass: spi_agent
