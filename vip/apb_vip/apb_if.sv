interface apb_if;

   logic                         PCLK;
   logic                         PRESETn;

   logic                         PSEL;
   logic                         PENABLE;
   logic                         PWRITE;
   logic[`APB_ADDR_WIDTH-1:0]    PADDR;
   logic[`APB_DATA_WIDTH-1:0]    PWDATA;
   logic[`APB_DATA_WIDTH-1:0]    PRDATA;
   logic                         PREADY;
   logic                         PSLVERR;
   
   logic									interrupt;

endinterface
