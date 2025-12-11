class interrupt_tx_empty_dis_test extends spi_base_test;
   `uvm_component_utils(interrupt_tx_empty_dis_test)
   

   function new(string name="interrupt_tx_empty_dis_test", uvm_component parent);
      super.new(name, parent);
   endfunction

   virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      
      assert (apb_freq.randomize())
      else 
         `uvm_fatal(get_type_name(), "Failed to randomize apb_configuration")
      
      assert (cfg.randomize() with {
         mode == spi_configuration::SLAVE;
         freq == (apb_freq.freq*1_000_000)/255;
         //freq == 10_000_000;
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
   		bit [31:0] rdata;

      phase.raise_objection(this);
      regmodel.DLR.write(status, config_dlr());
      regmodel.IER.write(status, 32'h0000_0000);
      regmodel.LCR.write(status, config_lcr());

      fork
      		begin
      			repeat (2) begin
		         	seq = slave_sequence::type_id::create("seq");
		         	seq.start(env.spi_agt.sequencer);
				end
         		`uvm_info("run_phase", "slave transfer DONE", UVM_LOW)
      		end

			begin
	         repeat (2) begin
	            sdata = $urandom_range(32'h0000_0000, 32'h0000_FFFF);
	            `uvm_info("run_phase", $sformatf("Send data %0h to slave", sdata), UVM_LOW)
	            regmodel.TBR.write(status, sdata);
	         end
	         
	         	`uvm_info(get_type_name(), "Check first time", UVM_LOW)
				regmodel.FSR.read(status, data);
			
				case ({data[0], apb_vif.interrupt})
					2'b01 : `uvm_error(get_type_name(), "Interrupt rise, FSR record correct status")
					2'b10 : `uvm_error(get_type_name(), "FSR record incorrect status")
					2'b11 : `uvm_error(get_type_name(), "Interrupt rise, FSR record incorrect status")
				endcase	
	
				repeat (2) begin
					wait(env.spi_agt.monitor.frame_done);
					#1;
				end

				`uvm_info(get_type_name(), "Check second time", UVM_LOW)
				regmodel.FSR.read(status, data);
		
				case ({data[0], apb_vif.interrupt})
					2'b01 : `uvm_error(get_type_name(), "Interrupt rise, FSR record incorrect status")
					2'b11 : `uvm_error(get_type_name(), "Interrupt rise, FSR record correct status")
					2'b00 : `uvm_error(get_type_name(), "FSR record incorrect status")
				endcase
	         
	         `uvm_info("run_phase", "APB transfer DONE", UVM_LOW)
			end
      join
   
      //env.scoreboard.compare();
      phase.drop_objection(this);
   endtask : run_phase
endclass
