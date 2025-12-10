class reg_rsvd_test extends spi_base_test;
   `uvm_component_utils(reg_rsvd_test)

   rsvd_sequence  seq;

   function new(string name="reg_rsvd_test", uvm_component parent);
      super.new(name, parent);
   endfunction
   
	virtual function void build_phase(uvm_phase phase);
	   super.build_phase(phase);
	   
	   assert (apb_freq.randomize())
	   else 
	      `uvm_fatal(get_type_name(), "Failed to randomize apb_configuration")
	   config_apb_freq(apb_freq);
	endfunction : build_phase

   virtual task run_phase(uvm_phase phase);
      phase.raise_objection(this);
      
      repeat(10) begin
         seq = rsvd_sequence::type_id::create("seq");
         seq.start(env.apb_agt.sequencer);
      end

      phase.drop_objection(this);
   endtask : run_phase
endclass
