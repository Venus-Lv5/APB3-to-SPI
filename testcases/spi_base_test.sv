class spi_base_test extends uvm_test;
   `uvm_component_utils(spi_base_test)

   uvm_report_server    svr;
   spi_environment      env;

   spi_reg_block        regmodel;
   slave_sequence       seq;

   virtual apb_if       apb_vif;
   virtual spi_if       spi_vif;

   spi_configuration    cfg, cfg2;
   apb_configuration		apb_freq;
   spi_error_catcher    err_catcher;

   time usr_timeout     = 1s;

   function new (string name="spi_base_test", uvm_component parent);
      super.new(name, parent);
   endfunction: new

   virtual function void config_spi (spi_configuration c);
      cfg.mode       = c.mode;
      cfg.word       = c.word;
      cfg.cpha       = c.cpha;
      cfg.cpol       = c.cpol;
      cfg.cdte       = c.cdte;
      cfg.slave_id  = c.slave_id;
      cfg.freq       = c.freq;

      cfg.div_val    = (apb_freq.freq * 1_000_000) / (2*cfg.freq);
      cfg.div_val 		= cfg.div_val - 1;
      cfg.freq			= (apb_freq.freq * 1_000_000) / (2*(cfg.div_val+1));
      `uvm_info(get_type_name(), $sformatf("Completed config spi: \n%s", cfg.sprint()), UVM_LOW)
   endfunction
   
   virtual function void config_apb_freq(apb_configuration c);
   		apb_freq.freq  	= c.freq;
   		apb_freq.period	= time'(1000/apb_freq.freq);
   		`uvm_info(get_type_name(), $sformatf("Completed config apb freq: \n%s", apb_freq.sprint()), UVM_LOW)
   	endfunction

   virtual function bit[31:0] config_lcr();
      bit [31:0] lcr = 32'h0;

      lcr[5:4]  = cfg.slave_id;
      lcr[3]    = cfg.cdte;
      lcr[2]    = cfg.cpha;
      lcr[1]    = cfg.cpol;
      case (cfg.word)
         8  : lcr[0] = 0;
         16 : lcr[0] = 1;
         default : `uvm_fatal(get_type_name(), "Config wls error, word size not support")
      endcase

      return lcr;
   endfunction

   virtual function bit [31:0] config_dlr();
      bit [31:0] dlr = 32'h0;
      dlr [7:0] = cfg.div_val;

      return dlr;
   endfunction

   virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      `uvm_info("build_phase", "Entered....", UVM_HIGH)

      if(!uvm_config_db#(virtual apb_if)::get(this, "", "apb_vif", apb_vif))
         `uvm_fatal(get_type_name(), $sformatf("Failed to get apb_if"))
      if(!uvm_config_db#(virtual spi_if)::get(this, "", "spi_vif", spi_vif))
         `uvm_fatal(get_type_name(), $sformatf("Failed to get spi_vif"))

      env            = spi_environment::type_id::create("env", this);
      err_catcher    = spi_error_catcher::type_id::create("err_catcher");
      cfg            = spi_configuration::type_id::create("cfg", this);
      apb_freq		  	= apb_configuration::type_id::create("apb_freq", this);
      uvm_report_cb::add(null, err_catcher);

      uvm_config_db#(virtual apb_if)::set(this, "env", "apb_vif", apb_vif);
      uvm_config_db#(virtual spi_if)::set(this, "env", "spi_vif", spi_vif);
      uvm_config_db#(spi_configuration)::set(this, "env", "cfg", cfg);
		uvm_config_db#(apb_configuration)::set(this, "env", "apb_freq", apb_freq);
		uvm_config_db#(apb_configuration)::set(null, "*", "apb_freq", apb_freq);

      uvm_top.set_timeout(usr_timeout);
      `uvm_info("build_phase", "Exitting....", UVM_HIGH)
   endfunction : build_phase

   virtual function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      this.regmodel = env.regmodel;
   endfunction : connect_phase

	virtual function void end_of_elaboration_phase(uvm_phase phase);
		super.end_of_elaboration_phase(phase);
		uvm_top.print_topology();
	endfunction

	virtual function void final_phase(uvm_phase phase);
		super.final_phase(phase);
		`uvm_info("final_phase", "Entered...", UVM_HIGH)
		svr = uvm_report_server::get_server();
		if(svr.get_severity_count(UVM_FATAL) + svr.get_severity_count(UVM_ERROR)) begin
			`uvm_info(get_type_name(), "--------------------------------", UVM_NONE)
			`uvm_info(get_type_name(), "----	TEST FAILED	----", UVM_NONE)
			`uvm_info(get_type_name(), "--------------------------------", UVM_NONE)
		end
		else begin
			`uvm_info(get_type_name(), "--------------------------------", UVM_NONE)
			`uvm_info(get_type_name(), "----	TEST PASSED	----", UVM_NONE)
			`uvm_info(get_type_name(), "--------------------------------", UVM_NONE)
		end

		`uvm_info("final_phase", "Exitting...", UVM_HIGH)
	endfunction
endclass
