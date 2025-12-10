class reg_default_test extends spi_base_test;
   `uvm_component_utils(reg_default_test)

   uvm_reg_hw_reset_seq    default_seq;

   function new(string name="reg_default_test", uvm_component parent);
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
      default_seq = uvm_reg_hw_reset_seq::type_id::create("reset_seq");
      phase.raise_objection(this);
      default_seq.model    = regmodel;
      default_seq.start(null);
      phase.drop_objection(this);
   endtask
endclass
