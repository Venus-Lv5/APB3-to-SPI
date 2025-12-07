`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/22/2025 02:19:04 PM
// Design Name: 
// Module Name: apb_bus
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module apb_bus(
	input i_clk,
	input i_rst_n,
	input i_psel,
	input i_pwrite,
	input i_penable,
	input [31:0] i_paddr,
	input [31:0] i_pwdata,
	output[31:0] o_prdata,
	output o_pready, 
	output o_pslverr,
	//To Register
	input i_error,
	input [31:0] i_rdata,
	output [11:0] o_addr,
	output o_wr_en, 
	output o_rd_en,
	output [31:0] o_wdata
);

assign o_wr_en = i_psel & i_pwrite & i_penable & o_pready & (i_paddr[31:12] == 20'h40002);
assign o_addr =  (i_paddr[31:12] == 20'h40002)?i_paddr[11:0]:0;
assign o_wdata = i_pwdata;

//read
assign o_rd_en = i_psel & !i_pwrite & i_penable & o_pready & (i_paddr[31:12] == 20'h40002);
assign o_prdata = o_pready? i_rdata: 32'b0;



assign o_pready = 1'b1;
//pslverr
assign o_pslverr = o_pready & (i_error | (i_psel & i_penable & (i_paddr[31:0] >= 32'h40002018 & i_paddr[31:0] <= 32'h40002FFF)));  

endmodule

