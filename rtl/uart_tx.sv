`timescale 1ns / 1ps

module uart_tx #(
    parameter int unsigned CLK_FREQ_HZ = 50_000_000,
    parameter int unsigned BAUD_RATE   = 115_200
) (
    input  logic       clk,
    input  logic       rst_n,

    // Data handshake
    input  logic [7:0] tx_data,
    input  logic       tx_valid,
    output logic       tx_ready,

    // Physical line
    output logic       txd
);

    // TODO:
    // 1. Implement a clock prescaler generating bit clock ticks:
    //    CLKS_PER_BIT = (CLK_FREQ_HZ + BAUD_RATE/2) / BAUD_RATE.
    // 2. Build the state machine (FSM): IDLE, START, DATA, STOP.
    // 3. Transmit data bits in 8N1 format (LSB first).
    // 4. Manage the tx_ready flag to support back-to-back continuous transmission.
    
    int unsigned CLKS_PER_BIT = (CLK_FREQ_HZ + BAUD_RATE/2) / BAUD_RATE;
    
    //assign tx_ready = 1'b1;
    //assign txd      = 1'b1;
    logic int_clk = 1'b0;

    reg[9:0] counter = 0;
    reg[2:0] fsm_state = 0;
    reg[3:0] bit_index = 0;
    reg[1:0] valid_reg = 0;
    reg[7:0] data_reg = 0;

    //Generating bit clock ticks 
    always_ff @ (posedge clk or negedge rst_n) begin
	    if(!rst_n) begin
		fsm_state <= 0;
		tx_ready <= 1;
		txd <= 1;
		int_clk <= 0;
		counter <= 0;
		bit_index <= 0;
		data_reg <= 0;
	    end
	    
	    else begin
		    if(counter < CLKS_PER_BIT) begin
			    counter <= counter + 1;
			    int_clk <= 0;
		    end
		    
		    else begin
			    counter <= 0;
			    int_clk <= 1;
		    end

		    if(fsm_state == 0) begin
			    if(tx_valid == 1) begin
				    valid_reg <= 1;
			    end

			    if(valid_reg && int_clk) begin
				    fsm_state <= 1;
				    txd <= 0;
				    tx_ready <= 0;
				    valid_reg <= 0;
				    data_reg <= tx_data;
				    bit_index <= 0;
			    end
		     end

		     else if(fsm_state == 1 && int_clk) begin
			     txd <= data_reg[bit_index];
			     fsm_state <= 2;
			     bit_index <= bit_index + 1;
		     end
		     
		     else if(fsm_state == 2 && int_clk) begin
			     if(bit_index < 8) begin
				     txd <= data_reg[bit_index];
				     bit_index <= bit_index + 1;
				     int_clk <= 0;
			     end
			     else begin
				     fsm_state <= 3;
				     bit_index <= 0;
				     txd <= 1;
				     int_clk <= 0;
			     end
		     end

		     else if(fsm_state == 3 && int_clk) begin
			     fsm_state <= 0;
			     tx_ready <= 1;
			     int_clk <= 0;
		     end

	end
    end
      
    

endmodule
