`timescale 1ns / 1ps
module interrupt(
	output int,
	
	//TX
	input tx_empty,
	input tx_full,
	
	//RX
	input rx_empty,
	input rx_full,
	
	//Register
	input en_tx_empty,
	input en_tx_full,
	input en_rx_empty,
	input en_rx_full
    );
    
    assign int_tx_empty = tx_empty & en_tx_empty;
    assign int_tx_full = tx_full & en_tx_full;
    assign int_rx_empty = rx_empty & en_rx_empty;
    assign int_rx_full = rx_full & en_rx_full;
    
    assign int = int_tx_empty | int_tx_full | int_rx_empty | int_rx_full;
endmodule
