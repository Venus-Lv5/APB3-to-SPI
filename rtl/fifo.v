`timescale 1ns / 1ps
module fifo(
	input i_clk,
	input i_rst_n,
	input i_wr_en,
	input i_rd_en,
	input [15:0] i_data_in,
	output [15:0] o_data_out,
	output o_fifo_full,
	output o_fifo_empty
    );
    
    //Status
    reg [4:0] r_wptr, r_rptr;
    reg [15:0] r_mem[15:0];
    
    wire w_fifo_wr, w_fifo_rd, w_fbit_comp, w_pointer_equal;
    assign w_fifo_wr = (~o_fifo_full) & i_wr_en;
    assign w_fifo_rd = (~o_fifo_empty) & i_rd_en;
    assign w_fbit_comp = r_wptr[4] ^ r_rptr[4];
    assign w_pointer_equal = (r_wptr[3:0] - r_rptr[3:0])?0:1;
    
    assign o_fifo_full = w_fbit_comp & w_pointer_equal;
    assign o_fifo_empty = (~w_fbit_comp) & w_pointer_equal;
    
    //Write pointer
    always@(posedge i_clk or negedge i_rst_n) begin
    	if(!i_rst_n)
    		r_wptr <= 5'b00000;
    	else if(w_fifo_wr)
    		r_wptr <= r_wptr + 5'b00001;
    	else 
    		r_wptr <= r_wptr;
    end
    
    //Read pointer
    always@(posedge i_clk or negedge i_rst_n) begin
    	if(!i_rst_n)
    		r_rptr <= 5'b00000;
    	else if(w_fifo_rd)
    		r_rptr <= r_rptr + 5'b00001;
    	else 
    		r_rptr <= r_rptr;
    end
    
    //Memory
    always@(posedge i_clk) begin
    	if(w_fifo_wr) 
    		r_mem[r_wptr[3:0]] <= i_data_in;
    end
    assign o_data_out = r_mem[r_rptr[3:0]];
    
endmodule
