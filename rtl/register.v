`timescale 1ns / 1ps

module register(
    input i_clk,
    input i_rst_n,
    
    //To APB Bus
    input i_rd_en,
    input i_wr_en,
    input [11:0] i_addr,
    input [31:0] i_wdata,
    output o_error,
    output reg [31:0] o_rdata,
    
    //To SPI Slave
    input i_busy,
    output [7:0] o_div_val,
    output o_cpol,
    output o_cpha,
    output o_wls,
    output o_cdte,
    output [1:0] o_ss,
    
    // To TX FIFO
    input i_tx_empty,
    input i_tx_full,
    output reg o_tx_wr_en,
    output [15:0] o_tx_data,
    
    // To RX FIFO
    input i_rx_empty,
    input i_rx_full,
    input [15:0] i_rx_data,
    output reg o_rx_rd_en,
    
    // To Interrupt
    output o_en_tx_empty,
    output o_en_tx_full,
    output o_en_rx_empty,
    output o_en_rx_full
    );
    
    parameter DEFAULT_LCR   = 32'h0000_0000;
    parameter DEFAULT_DLR   = 32'h0000_0000;
    parameter DEFAULT_IER   = 32'h0000_0000;
    parameter DEFAULT_FSR   = 32'h0000_000A;
    parameter DEFAULT_TBR   = 32'h0000_0000;
    parameter DEFAULT_RBR   = 32'hxxxx_xxxx;
    
    reg [31:0] r_LCR;
    reg [31:0] r_DLR;
    reg [31:0] r_IER;
    reg [31:0] r_FSR;
    reg [31:0] r_TBR;
    reg [31:0] r_RBR;
    
    reg [6:0] r_sel;
    reg r_LCR_change, r_div_val_change, r_div_val_limit;
    
    //Address process
    always@(i_addr) begin
        case(i_addr)
            12'h000: r_sel = 6'b00_0001;     //LCR
            12'h004: r_sel = 6'b00_0010;     //DLR
            12'h008: r_sel = 6'b00_0100;     //IER
            12'h00C: r_sel = 6'b00_1000;     //FSR
            12'h010: r_sel = 6'b01_0000;     //TBR
            12'h014: r_sel = 6'b10_0000;     //RBR
            default: r_sel = 6'b00_0000;
        endcase
     end
     
     //Error handling
     always@(*) begin
        if(!i_rst_n) begin
            r_LCR_change = 0;
            r_div_val_change = 0;
            r_div_val_limit = 0;
        end
        else if (i_wr_en) begin
            r_div_val_change = r_sel[1] && i_busy && i_wdata[7:0]!=r_DLR[7:0];
            r_LCR_change = r_sel[0] && i_busy && i_wdata[5:0]!=r_LCR[5:0];
            r_div_val_limit = r_sel[1] && (i_wdata[7:0] == 8'd0);
        end
        else begin
            r_LCR_change = 0;
            r_div_val_change = 0;
            r_div_val_limit = 0;
        end 
     end 
     
     assign o_error = r_LCR_change | r_div_val_change;
     
     //LCR
     always@(posedge i_clk, negedge i_rst_n) begin
        if (!i_rst_n)
            r_LCR <= DEFAULT_LCR;
        else if(i_wr_en && r_sel[0] && !i_rd_en && ~o_error)
            r_LCR[5:0] <= i_wdata[5:0];
        else
            r_LCR <= r_LCR;
     end
     
     assign o_wls    	= r_LCR[0];
     assign o_cpol    	= r_LCR[1];
     assign o_cpha    	= r_LCR[2];
     assign o_cdte    	= r_LCR[3];
     assign o_ss      	= r_LCR[5:4];
     
     //DL
     always@(posedge i_clk, negedge i_rst_n) begin
        if (!i_rst_n)
            r_DLR <= DEFAULT_DLR;
        else if (i_wr_en && r_sel[1] && !i_rd_en && ~o_error)
            r_DLR <= i_wdata[7:0];
        else
            r_DLR <= r_DLR;
     end
     
     assign o_div_val = r_DLR[7:0];
     
     //IE
     always@(posedge i_clk, negedge i_rst_n) begin
        if (!i_rst_n)  
            r_IER <= DEFAULT_IER;
        else if (i_wr_en && r_sel[2] && !i_rd_en && ~o_error)
            r_IER <= i_wdata[3:0];
        else
            r_IER <= r_IER;
     end
     
     assign o_en_tx_empty = r_IER[0];
     assign o_en_tx_full = r_IER[1]; 
     assign o_en_rx_empty = r_IER[2];
     assign o_en_rx_full = r_IER[3];
     
     //FSR  
     always@(posedge i_clk, negedge i_rst_n) begin
     	if (!i_rst_n)
     		r_FSR <= DEFAULT_FSR;
     	else
     		r_FSR <= r_FSR;
     end
     
     
     //TBR
     always@(posedge i_clk, negedge i_rst_n) begin
     	if (!i_rst_n)
     		r_TBR <= DEFAULT_TBR;
     	else if (i_wr_en && r_sel[4] && !i_rd_en && ~o_error)
     		r_TBR <= i_wdata[15:0];
     	else
     		r_TBR <= r_TBR;
     end
     
     assign o_tx_data = r_TBR;
     
     //RBR
     always@(posedge i_clk, negedge i_rst_n) begin
     	if(!i_rst_n)
     		r_RBR <= DEFAULT_RBR;
     	else
     		r_RBR <= r_RBR;
     end
     
     //Read
     always@(*) begin
     	if (i_rd_en)
     		case(r_sel) 
     			6'b00_0001: o_rdata = r_LCR;												//LCR
     			6'b00_0010: o_rdata = r_DLR;												//DLR
     			6'b00_0100: o_rdata = r_IER;												//IER
     			6'b00_1000: o_rdata = {28'h0, i_rx_full, i_rx_empty, i_tx_full, i_tx_empty};//FSR
     			6'b01_0000: o_rdata = 32'h0000_0000;										//TBR
     			6'b10_0000: o_rdata = {16'h0000, i_rx_data};											//RBR
     			default:	o_rdata = 32'hFFFF_FFFF;										//rsvd
     		endcase
     	else
     		o_rdata = 0;
     end
     
     //Send data to TX FIFO
     always@(posedge i_clk or negedge i_rst_n) begin
     	if(!i_rst_n) 
     		o_tx_wr_en <= 1'b0;
     	else if (~i_tx_full & i_wr_en & r_sel[4])
     		o_tx_wr_en <= 1'b1;
     	else
     		o_tx_wr_en <= 1'b0;
     end
     
     //Get data from RX FIFO
     always@(posedge i_clk or negedge i_rst_n) begin
     	if (!i_rst_n)
     		o_rx_rd_en <= 1'b0;
     	else if (~i_rx_empty & i_rd_en & r_sel[5])
     		o_rx_rd_en <= 1'b1;
     	else 
     		o_rx_rd_en <= 1'b0;
     end     
endmodule
