class apb_configuration extends uvm_object; 

      rand int             freq;
      time						period;

      constraint c_freq 			{ freq 		inside {20, 50, 100};}

      `uvm_object_utils_begin(apb_configuration)
         `uvm_field_int(freq,                      UVM_ALL_ON | UVM_DEC)
         `uvm_field_int(period,                    UVM_ALL_ON | UVM_DEC)
      `uvm_object_utils_end

   function new(string name = "apb_configuration");
      super.new(name);
      freq 		= 100;
      period		= 10ns;
   endfunction

   
endclass
