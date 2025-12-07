class spi_transaction extends uvm_sequence_item;
   rand bit [15:0] data;
   `uvm_object_utils_begin(spi_transaction)
      `uvm_field_int(data, UVM_ALL_ON | UVM_HEX);
   `uvm_object_utils_end

   function new(string name = "spi_transaction");
      super.new(name);
   endfunction

   
endclass


