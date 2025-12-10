`timescale 1ns / 1ps
module spi_master(
    // Global
    input  wire        i_clk,
    input  wire        i_rst_n,

    // Config
    input  wire [7:0]  i_div_val,   
    input  wire        i_cpol,
    input  wire        i_cpha,
    input  wire        i_wls,      
    input  wire        i_cdte,
    input  wire [1:0]  i_ss,
    output wire        o_busy,

    // FIFO IF
    input  wire [15:0] i_tx_data,
    input  wire        i_tx_empty,
    input  wire        i_tx_full,  
    output wire [15:0] o_rx_data,
    input  wire        i_rx_empty,  
    input  wire        i_rx_full,
    output wire        o_tx_rd,
    output wire        o_rx_wr,

    // SPI pins
    input  wire        i_MISO,
    output wire        o_MOSI,
    output wire        o_SCLK,
    output wire [3:0]  o_SS         
);

    //==========================================================================
    // FSM
    //==========================================================================
    localparam [1:0]
        ST_IDLE     = 2'b00,
        ST_LOAD     = 2'b01,
        ST_TRANSFER = 2'b10,
        ST_DONE      = 2'b11; // ch? 4 clk khi cdte = 0

    reg [1:0] r_state, r_next_state;

    assign o_busy = (r_state != ST_IDLE);


    wire [4:0] w_bit_cnt    = i_wls ? 5'd16 : 5'd8;
    wire [5:0] w_edge_total = {w_bit_cnt, 1'b0};


    reg        c_tx_load;        
    reg        c_tx_rd;          
    reg        c_frame_init;     
    reg        c_in_transfer;    
    reg        c_shift_en;       
    reg        c_sample_en;      
    reg        c_rx_latch;       

    assign o_tx_rd = c_tx_rd;

    //==========================================================================
    // SCLK + edge counter
    //==========================================================================
    reg        r_sclk;
    reg  [8:0] r_div_cnt;
    reg  [5:0] r_edge_rem;
    reg        r_frame_active;
    reg        r_frame_done_reg;   

    assign o_SCLK       = r_sclk;
    wire   w_frame_done = r_frame_done_reg;

    wire w_sclk_toggle   = r_frame_active && (r_div_cnt == i_div_val);
    wire w_leading_edge  = w_sclk_toggle && (r_sclk == i_cpol);   // r?i idle
    wire w_trailing_edge = w_sclk_toggle && (r_sclk != i_cpol);   // v? idle


    wire w_sample_edge = i_cpha ? w_trailing_edge : w_leading_edge;
    wire w_shift_edge  = i_cpha ? w_leading_edge  : w_trailing_edge;

    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            r_sclk           <= 1'b0;
            r_div_cnt        <= 8'd0;
            r_edge_rem       <= 6'd0;
            r_frame_active   <= 1'b0;
            r_frame_done_reg <= 1'b0;
        end else begin
            r_frame_done_reg <= 1'b0;   // default

            // B?t ??u frame m?i
            if (c_frame_init) begin
                r_sclk         <= i_cpol;
                r_div_cnt      <= 8'd0;
                r_edge_rem     <= w_edge_total;
                r_frame_active <= 1'b1;

            // Không còn trong TRANSFER => ??a SCLK v? idle, d?ng frame
            end else if (!c_in_transfer) begin
                r_sclk         <= i_cpol;
                r_div_cnt      <= 8'd0;
                r_edge_rem     <= 6'd0;
                r_frame_active <= 1'b0;

            // ?ang trong frame
            end else if (r_frame_active) begin
                if (w_sclk_toggle) begin
                    r_div_cnt <= 8'd0;
                    r_sclk    <= ~r_sclk;

                    if (r_edge_rem != 0) begin
                        r_edge_rem <= r_edge_rem - 1'b1;

                        if (r_edge_rem == 6'd1) begin
                            // H?t 1 frame
                            r_frame_active   <= 1'b0;
                            r_frame_done_reg <= 1'b1;
                            r_sclk           <= i_cpol;
                        end
                    end
                end else begin
                    r_div_cnt <= r_div_cnt + 1'b1;
                end
            end
        end
    end

    //==========================================================================
    // TX / RX datapath
    //==========================================================================
    reg [15:0] r_tx_shift;
    reg [15:0] r_rx_shift;
    reg [4:0]  r_tx_idx;
    reg [3:0]  r_rx_idx;
    reg        r_mosi;

    reg [15:0] r_rx_data;
    reg        r_rx_wr;

    assign o_MOSI    = r_mosi;
    assign o_rx_data = r_rx_data;
    assign o_rx_wr   = r_rx_wr;

    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            r_tx_shift <= 16'h0;
            r_rx_shift <= 16'h0;
            r_tx_idx   <= 4'd0;
            r_rx_idx   <= 4'd0;
            r_mosi     <= 1'b0;
            r_rx_data  <= 16'h0;
            r_rx_wr    <= 1'b0;
        end else begin
            r_rx_wr <= 1'b0; // default

            if (c_tx_load) begin
                r_tx_shift <= i_wls ? i_tx_data
                                    : {8'h00, i_tx_data[7:0]};

                r_rx_shift <= 16'h0;
                r_rx_idx   <= 4'd0;

                if (!i_cpha) begin
                  r_tx_idx   <= w_bit_cnt - 1'b1;  
                  r_mosi <= (i_wls ? i_tx_data[w_bit_cnt-1]
                                     : i_tx_data[7]);
               end
               else 
                  r_tx_idx = w_bit_cnt;
            end

            // SHIFT TX (MOSI)
            if (c_shift_en && w_shift_edge && r_frame_active) begin
                if (r_tx_idx != 5'd0) begin
                    r_tx_idx <= r_tx_idx - 1'b1;
                    r_mosi   <= r_tx_shift[r_tx_idx-1];
                end
            end

            // SAMPLE RX (MISO)
            if (c_sample_en && w_sample_edge && r_frame_active) begin
                r_rx_shift <= {r_rx_shift[14:0], i_MISO};
                if (r_rx_idx != (w_bit_cnt - 1'b1))
                    r_rx_idx <= r_rx_idx + 1'b1;
            end

            // CH?T RX ra FIFO sau khi frame_done
            if (c_rx_latch) begin
                r_rx_data <= i_wls ? r_rx_shift
                                   : {8'h00, r_rx_shift[7:0]};
                r_rx_wr   <= 1'b1;
            end
        end
    end

    reg [2:0] r_gap_cnt;

    always @(*) begin
        
        r_next_state  = r_state;
        c_tx_load     = 1'b0;
        c_tx_rd       = 1'b0;
        c_frame_init  = 1'b0;
        c_in_transfer = 1'b0;
        c_shift_en    = 1'b0;
        c_sample_en   = 1'b0;
        c_rx_latch    = 1'b0;

        case (r_state)
            ST_IDLE: begin
                if (!i_tx_empty) begin
                    r_next_state = ST_LOAD;
                end
            end

            ST_LOAD: begin
                c_tx_rd      = 1'b1;
                c_tx_load    = 1'b1;
                c_frame_init = 1'b1;
                r_next_state = ST_TRANSFER;
            end

            ST_TRANSFER: begin
                c_in_transfer = 1'b1;
                c_shift_en    = 1'b1;
                c_sample_en   = 1'b1;

                if (w_frame_done) begin
                    c_rx_latch = 1'b1;  

                    if (!i_cdte) begin
                        r_next_state = ST_DONE;
                    end else begin
                        if (!i_tx_empty)
                            r_next_state = ST_LOAD; 
                        else
                            r_next_state = ST_IDLE;
                    end
                end
            end

            ST_DONE: begin
                if (r_gap_cnt == 3) begin
                     r_next_state = ST_IDLE; 
                end
            end

            default: r_next_state = ST_IDLE;
        endcase
    end

    //==========================================================================
    // FSM state register
    //==========================================================================
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            r_state   <= ST_IDLE;
            r_gap_cnt <= 3'd0;
        end else begin
            r_state <= r_next_state;

            // GAP counter: ch? ??m khi ? ST_DONE
            if (r_state == ST_DONE) begin
                if (r_gap_cnt != 3'd3)
                    r_gap_cnt <= r_gap_cnt + 1'b1;
            end else begin
                r_gap_cnt <= 3'd0;
            end
        end
    end

    //==========================================================================
    // Chip select (active low)
    //==========================================================================
    wire [3:0] w_ss_onehot =
        (i_ss == 2'd0) ? 4'b0001 :
        (i_ss == 2'd1) ? 4'b0010 :
        (i_ss == 2'd2) ? 4'b0100 :
                         4'b1000;

    assign o_SS =
        (r_state == ST_LOAD     ||
         r_state == ST_TRANSFER) ? ~w_ss_onehot : 4'b1111;

endmodule
