class spi_busy_cfg_LCR_test extends spi_base_test;
   `uvm_component_utils(spi_busy_cfg_LCR_test)
   
   apb_transaction lcr_tr1, lcr_tr2;

   function new(string name="spi_busy_cfg_LCR_test", uvm_component parent);
      super.new(name, parent);
   endfunction

   virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      
      assert (apb_freq.randomize())
      else 
         `uvm_fatal(get_type_name(), "Failed to randomize apb_configuration")
      
      assert (cfg.randomize() with {
         mode == spi_configuration::SLAVE;
         freq == (apb_freq.freq*1_000_000)/(2*256);
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
      regmodel.LCR.write(status, config_lcr());
      
      while (env.scoreboard.apb_lcr_queue.size()>0)
      		lcr_tr1 = env.scoreboard.apb_lcr_queue.pop_front();

      fork
      		begin
         		repeat (1) begin
            		seq = slave_sequence::type_id::create("seq");
            		seq.start(env.spi_agt.sequencer);
            		wait(env.spi_agt.monitor.miso_capture_done);
         		end
        		 `uvm_info("run_phase", "slave transfer DONE", UVM_LOW)
      		end

			begin
	         repeat (1) begin
	            sdata = $urandom_range(32'h0000_0000, 32'h0000_FFFF);
	            `uvm_info("run_phase", $sformatf("Send data %0h to slave", sdata), UVM_LOW)
	            regmodel.TBR.write(status, sdata);
	         end
	         
	         wait(spi_vif.SS != 4'b1111);
	         regmodel.LCR.write(status, {lcr[31:6], ~lcr[5:0]});
	         while (env.scoreboard.apb_lcr_queue.size()>0)
      				lcr_tr2 = env.scoreboard.apb_lcr_queue.pop_front();
      			
      			regmodel.LCR.read(status, data);
      
				if (lcr_tr1.pslverr != 0)
					`uvm_error(get_type_name(), "PSLVERR trigger error")
				if (lcr_tr2.pslverr != 1)
					`uvm_error(get_type_name(), "PSLVERR not trigger when write LCR with SPI master busy")
				if (data == lcr_tr2.data && data != lcr_tr1.data)
					`uvm_error(get_type_name(), $sformatf("LCR overwrite when SPI busy %0h %0h %0h", data, lcr_tr1.data, lcr_tr2.data))
	         
	         `uvm_info("run_phase", "APB transfer DONE", UVM_LOW)
			end
      join
      

      
      phase.drop_objection(this);
   endtask : run_phase
endclass
