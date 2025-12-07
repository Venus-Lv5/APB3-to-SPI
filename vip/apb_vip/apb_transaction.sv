class apb_transaction extends uvm_sequence_item;

   typedef enum bit{
      WRITE = 1,
      READ  = 0
      } xact_type_enum;

    rand bit [`APB_ADDR_WIDTH-1:0] addr;
    rand bit [`APB_ADDR_WIDTH-1:0] data;
    		bit                       pslverr;

    rand xact_type_enum xact_type;

    `uvm_object_utils_begin(apb_transaction)
       `uvm_field_enum (xact_type_enum, xact_type, UVM_ALL_ON | UVM_HEX)
       `uvm_field_int  (addr                     , UVM_ALL_ON | UVM_HEX)
       `uvm_field_int  (data                     , UVM_ALL_ON | UVM_HEX)
       `uvm_field_int  (pslverr                  , UVM_ALL_ON | UVM_HEX)      
    `uvm_object_utils_end

    function new(string name="apb_transaction");
       super.new();
    endfunction
 
 endclass

