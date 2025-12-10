`timescale 1ns / 1ps

module apb_spi_top(
    // Clock & reset
    input  wire        i_clk,
    input  wire        i_rst_n,
    
    // APB interface
    input  wire        i_psel,
    input  wire        i_pwrite,
    input  wire        i_penable,
    input  wire [31:0] i_paddr,
    input  wire [31:0] i_pwdata,
    output wire [31:0] o_prdata,
    output wire        o_pready,
    output wire        o_pslverr,
    
    // SPI external interface
    input  wire        i_MISO,
    output wire        o_MOSI,
    output wire        o_SCLK,

    // --- TÁCH RIÊNG SS ---
    output wire        o_SS0,
    output wire        o_SS1,
    output wire        o_SS2,
    output wire        o_SS3,
    
    // Interrupt ra ngoài
    output wire        o_int
);

    // ======================================================================
    // INTERNAL WIRES
    // ======================================================================

    // APB bus <-> register
    wire [11:0] w_addr;
    wire        w_wr_en;
    wire        w_rd_en;
    wire [31:0] w_wdata;
    wire        w_error;
    wire [31:0] w_rdata;

    // Register <-> spi_master
    wire [7:0]  w_div_val;
    wire        w_cpol;
    wire        w_cpha;
    wire        w_wls;
    wire        w_cdte;
    wire [1:0]  w_ss;          // ch?n slave
    wire        w_busy;

    // Register <-> FIFO
    wire        w_tx_empty;
    wire        w_tx_full;
    wire        w_tx_wr_en;
    wire [15:0] w_tx_data;

    wire        w_rx_empty;
    wire        w_rx_full;
    wire        w_rx_rd_en;
    wire [15:0] w_rx_fifo_dout;

    // FIFO <-> spi_master
    wire        w_tx_rd;
    wire        w_rx_wr;
    wire [15:0] w_tx_fifo_dout;
    wire [15:0] w_rx_spi_data;

    // Ng?t
    wire        w_en_tx_empty;
    wire        w_en_tx_full;
    wire        w_en_rx_empty;
    wire        w_en_rx_full;

    // SPI master outputs
    wire [3:0] w_SS_bus;

    // ======================================================================
    // APB BUS
    // ======================================================================
    apb_bus u_apb_bus (
        .i_clk     (i_clk),
        .i_rst_n   (i_rst_n),
        .i_psel    (i_psel),
        .i_pwrite  (i_pwrite),
        .i_penable (i_penable),
        .i_paddr   (i_paddr),
        .i_pwdata  (i_pwdata),
        .o_prdata  (o_prdata),
        .o_pready  (o_pready),
        .o_pslverr (o_pslverr),

        .i_error   (w_error),
        .i_rdata   (w_rdata),
        .o_addr    (w_addr),
        .o_wr_en   (w_wr_en),
        .o_rd_en   (w_rd_en),
        .o_wdata   (w_wdata)
    );

    // ======================================================================
    // REGISTER FILE
    // ======================================================================
    register u_register (
        .i_clk      (i_clk),
        .i_rst_n    (i_rst_n),

        .i_rd_en    (w_rd_en),
        .i_wr_en    (w_wr_en),
        .i_addr     (w_addr),
        .i_wdata    (w_wdata),
        .o_error    (w_error),
        .o_rdata    (w_rdata),

        .i_busy     (w_busy),
        .o_div_val  (w_div_val),
        .o_cpol     (w_cpol),
        .o_cpha     (w_cpha),
        .o_wls      (w_wls),
        .o_cdte     (w_cdte),
        .o_ss       (w_ss),

        .i_tx_empty (w_tx_empty),
        .i_tx_full  (w_tx_full),
        .o_tx_wr_en (w_tx_wr_en),
        .o_tx_data  (w_tx_data),

        .i_rx_empty (w_rx_empty),
        .i_rx_full  (w_rx_full),
        .i_rx_data  (w_rx_fifo_dout),
        .o_rx_rd_en (w_rx_rd_en),

        .o_en_tx_empty (w_en_tx_empty),
        .o_en_tx_full  (w_en_tx_full),
        .o_en_rx_empty (w_en_rx_empty),
        .o_en_rx_full  (w_en_rx_full)
    );

    // ======================================================================
    // TX FIFO
    // ======================================================================
    fifo u_tx_fifo (
        .i_clk       (i_clk),
        .i_rst_n     (i_rst_n),
        .i_wr_en     (w_tx_wr_en),
        .i_rd_en     (w_tx_rd),
        .i_data_in   (w_tx_data),
        .o_data_out  (w_tx_fifo_dout),
        .o_fifo_full (w_tx_full),
        .o_fifo_empty(w_tx_empty)
    );

    // ======================================================================
    // RX FIFO
    // ======================================================================
    fifo u_rx_fifo (
        .i_clk       (i_clk),
        .i_rst_n     (i_rst_n),
        .i_wr_en     (w_rx_wr),
        .i_rd_en     (w_rx_rd_en),
        .i_data_in   (w_rx_spi_data),
        .o_data_out  (w_rx_fifo_dout),
        .o_fifo_full (w_rx_full),
        .o_fifo_empty(w_rx_empty)
    );

    // ======================================================================
    // SPI MASTER
    // ======================================================================
    spi_master u_spi_master (
        .i_clk      (i_clk),
        .i_rst_n    (i_rst_n),

        .i_div_val  (w_div_val),
        .i_cpol     (w_cpol),
        .i_cpha     (w_cpha),
        .i_wls      (w_wls),
        .i_cdte     (w_cdte),
        .i_ss       (w_ss),
        .o_busy     (w_busy),

        .i_tx_data  (w_tx_fifo_dout),
        .i_tx_empty (w_tx_empty),
        .i_tx_full  (w_tx_full),
        .o_rx_data  (w_rx_spi_data),
        .i_rx_empty (w_rx_empty),
        .i_rx_full  (w_rx_full),
        .o_tx_rd    (w_tx_rd),
        .o_rx_wr    (w_rx_wr),

        .i_MISO     (i_MISO),
        .o_MOSI     (o_MOSI),
        .o_SCLK     (o_SCLK),
        .o_SS       (w_SS_bus)      // bus 4-bit
    );

    // ======================================================================
    // TÁCH SS RIÊNG
    // ======================================================================
    assign o_SS0 = w_SS_bus[0];
    assign o_SS1 = w_SS_bus[1];
    assign o_SS2 = w_SS_bus[2];
    assign o_SS3 = w_SS_bus[3];

    // ======================================================================
    // INTERRUPT
    // ======================================================================
    interrupt u_interrupt (
        .o_int        (o_int),
        .tx_empty     (w_tx_empty),
        .tx_full      (w_tx_full),
        .rx_empty     (w_rx_empty),
        .rx_full      (w_rx_full),
        .en_tx_empty  (w_en_tx_empty),
        .en_tx_full   (w_en_tx_full),
        .en_rx_empty  (w_en_rx_empty),
        .en_rx_full   (w_en_rx_full)
    );

endmodule
