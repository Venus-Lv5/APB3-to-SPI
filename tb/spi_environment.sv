class spi_environment extends uvm_env;
   `uvm_component_utils(spi_environment);

   virtual apb_if apb_vif;
   virtual spi_if spi_vif;

   spi_configuration cfg;
   apb_configuration apb_freq;

   spi_scoreboard       scoreboard;
   spi_agent            spi_agt;
   apb_agent            apb_agt;

   spi_reg_block                          	regmodel;
   spi_reg2apb_adapter                    	apb_adapter;
   uvm_reg_predictor #(apb_transaction)  	apb_predictor;

   function new(string name = "spi_environment", uvm_component parent);
      super.new(name, parent);
   endfunction

   virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      `uvm_info("build_phase", "Entered.....", UVM_HIGH)

      if(!uvm_config_db#(virtual apb_if)::get(this, "", "apb_vif", apb_vif))
         `uvm_fatal(get_type_name(), "Failed to get apb_if")
      if (!uvm_config_db#(virtual spi_if)::get(this, "", "spi_vif", spi_vif))
         `uvm_fatal(get_type_name(), "Failed to get spi_vif")
      if(!uvm_config_db#(spi_configuration)::get(this, "", "cfg", cfg))
         `uvm_fatal(get_type_name(), "Failed to get spi_configuration")
      if(!uvm_config_db#(apb_configuration)::get(this, "", "apb_freq", apb_freq))
         `uvm_fatal(get_type_name(), "Failed to get apb_configuration")

      apb_agt     = apb_agent::type_id::create("apb_agt", this);
      spi_agt     = spi_agent::type_id::create("spi_agt", this);
      scoreboard  = spi_scoreboard::type_id::create("scoreboard", this);

      apb_adapter = spi_reg2apb_adapter::type_id::create("apb_adapter", this);
      regmodel    = spi_reg_block::type_id::create("regmodel", this);
      regmodel.build();

      apb_predictor = uvm_reg_predictor #(apb_transaction)::type_id::create("apb_predictor", this);

      uvm_config_db#(virtual spi_if)::set(this, "spi_agt", "spi_vif", spi_vif);
      uvm_config_db#(virtual apb_if)::set(this, "apb_agt", "apb_vif", apb_vif);
		uvm_config_db#(virtual apb_if)::set(this, "spi_agt", "apb_vif", apb_vif);
      uvm_config_db#(spi_configuration)::set(this, "spi_agt", "cfg", cfg);
      uvm_config_db#(spi_configuration)::set(this, "scoreboard", "cfg", cfg);
      uvm_config_db#(apb_configuration)::set(this, "apb_agt", "apb_freq", apb_freq);
      uvm_config_db#(apb_configuration)::set(this, "scoreboard", "apb_freq", apb_freq);

      `uvm_info("build_phase", "Exiting....", UVM_HIGH)
   endfunction : build_phase

   virtual function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      `uvm_info("connect_phase", "Entered.....", UVM_HIGH)
      if (regmodel.get_parent() == null)
         regmodel.apb_map.set_sequencer(apb_agt.sequencer, apb_adapter);

      apb_predictor.map       = regmodel.apb_map;
      apb_predictor.adapter   = apb_adapter;

      apb_agt.monitor.apb_observe_port.connect(apb_predictor.bus_in);
      spi_agt.monitor.spi_observe_port_mosi.connect(scoreboard.mosi_export);
      spi_agt.monitor.spi_observe_port_miso.connect(scoreboard.miso_export);
      apb_agt.monitor.apb_observe_port.connect(scoreboard.apb_export);
      spi_agt.monitor.spi_observe_port_ss.connect(scoreboard.ss_export);
      spi_agt.monitor.spi_observe_port_sclk_freq.connect(scoreboard.sclk_freq_export);

      `uvm_info("connect_phase", "Exitting....", UVM_HIGH)
   endfunction : connect_phase

   
endclass
