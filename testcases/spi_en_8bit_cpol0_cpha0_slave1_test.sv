class spi_en_8bit_cpol0_cpha0_slave1_test extends spi_base_test;
   `uvm_component_utils(spi_en_8bit_cpol0_cpha0_slave1_test)

   function new(string name="spi_en_8bit_cpol0_cpha0_slave1_test", uvm_component parent);
      super.new(name, parent);
   endfunction

   virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      
      assert (apb_freq.randomize())
      else 
         `uvm_fatal(get_type_name(), "Failed to randomize apb_configuration")
      
      assert (cfg.randomize() with {
         mode == spi_configuration::SLAVE;
         word == 8;
         cpol == 0;
         cpha == 0;
         cdte == 1;
         freq inside {[(apb_freq.freq*1_000_000)/(2*256) : (apb_freq.freq*1_000_000)/2]};
         //freq == 10_000_000;
         slave_id == 1;
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

      phase.raise_objection(this);
      regmodel.DLR.write(status, config_dlr());
      regmodel.IER.write(status, 32'h0000_0000);
      regmodel.LCR.write(status, config_lcr());

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
endclass
