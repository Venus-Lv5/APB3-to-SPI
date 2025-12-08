class spi_configuration extends uvm_object;   
   typedef enum {
      MASTER,
      SLAVE
      } spi_mode_enum;

      rand spi_mode_enum   mode;
      rand int             freq;
      rand int             word;
      rand bit             cpha;
      rand bit             cpol;
      rand bit             cdte;
      rand int             slave_id;
      
      		  bit [7:0]			div_val;

      constraint c_mode 			{ mode 		inside {MASTER, SLAVE};}
      constraint c_word 			{ word 		inside {8, 16};}
      constraint c_slave_id 	{ slave_id 	inside {[0:3]};}

      `uvm_object_utils_begin(spi_configuration)
         `uvm_field_enum(spi_mode_enum, mode,      UVM_ALL_ON | UVM_STRING)
         `uvm_field_int(freq,                      UVM_ALL_ON | UVM_DEC)
         `uvm_field_int(word,                      UVM_ALL_ON | UVM_DEC)
         `uvm_field_int(cpha,                      UVM_ALL_ON | UVM_BIN)
         `uvm_field_int(cpol,                      UVM_ALL_ON | UVM_BIN)
         `uvm_field_int(cdte,                      UVM_ALL_ON | UVM_BIN)
         `uvm_field_int(slave_id,                 UVM_ALL_ON | UVM_DEC)
         `uvm_field_int(div_val,						  UVM_ALL_ON | UVM_HEX)
      `uvm_object_utils_end

   function new(string name = "spi_configuration");
      super.new(name);
   endfunction

   
endclass
