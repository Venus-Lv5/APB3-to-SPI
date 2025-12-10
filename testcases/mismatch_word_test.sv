class mismatch_word_test extends spi_base_test;
   `uvm_component_utils(mismatch_word_test)

   function new(string name="mismatch_word_test", uvm_component parent);
      super.new(name, parent);
   endfunction

   virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      
      assert (apb_freq.randomize())
      else 
         `uvm_fatal(get_type_name(), "Failed to randomize apb_configuration")
      
      assert (cfg.randomize() with {
         mode == spi_configuration::SLAVE;
         freq inside {[(apb_freq.freq*1_000_000)/(2*256) : (apb_freq.freq*1_000_000)/2]};
         word == 8;
         })
      else 
         `uvm_fatal(get_type_name(), "Failed to randomize spi_configuration")

      config_spi(cfg);
      config_apb_freq(apb_freq);
   endfunction : build_phase

   virtual task run_phase(uvm_phase phase);
      uvm_status_e status;
      bit [31:0] data;
      bit [31:0] sdata;
      bit [31:0] lcr = 32'h0;

      phase.raise_objection(this);
      lcr = config_lcr();
      regmodel.DLR.write(status, config_dlr());
      regmodel.IER.write(status, 32'h0000_0000);
      regmodel.LCR.write(status, {lcr[31:1], ~lcr[0]});

		fork
      		begin
         		repeat (3) begin
            		seq = slave_sequence::type_id::create("seq");
            		seq.start(env.spi_agt.sequencer);
         		end
        		 `uvm_info("run_phase", "slave transfer DONE", UVM_LOW)
      		end
      		
      		begin 
      			repeat (3) begin
      				wait(env.spi_agt.monitor.frame_done);
   					@(posedge apb_vif.PCLK);
   					regmodel.RBR.read(status, data);
   				end
   			end

			begin
	         repeat (3) begin
	            sdata = $urandom_range(32'h0000_0000, 32'h0000_FFFF);
	            `uvm_info("run_phase", $sformatf("Send data %0h to slave", sdata), UVM_LOW)
	            regmodel.TBR.write(status, sdata);
	         end
	         
	         `uvm_info("run_phase", "APB transfer DONE", UVM_LOW)
			end
      join
   
      env.scoreboard.compare();
      phase.drop_objection(this);
   endtask : run_phase
   
   	virtual task main_phase(uvm_phase phase);
		phase.raise_objection(this);
		
		err_catcher.add_error_catcher_msg("Data transfer from dut to spi slaver mismatch");
		err_catcher.add_error_catcher_msg("Data receive from slaver to dut mismatch");
		
		if (cfg.word == 8)
			err_catcher.add_error_catcher_msg("The DUT released SS mismatch during non continuous mode");

		phase.drop_objection(this);
	endtask
endclass
