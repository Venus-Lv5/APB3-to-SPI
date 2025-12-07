`ifndef GUARD_APB_DEFINE__SV
`define GUARD_APB_DEFINE__SV

  `ifndef FORK_GUARD_BEGIN
    `define FORK_GUARD_BEGIN fork begin
  `endif

  `ifndef FORK_GUARD_END
    `define FORK_GUARD_END   fork end
  `endif
  `ifndef APB_ADDR_WIDTH
     `define APB_ADDR_WIDTH   32 
  `endif
  `ifndef APB_DATA_WIDTH
     `define APB_DATA_WIDTH   32 
  `endif
  `ifndef APB_MAX_PCLK_WAIT
     `define APB_MAX_PCLK_WAIT 50
  `endif 

`endif
