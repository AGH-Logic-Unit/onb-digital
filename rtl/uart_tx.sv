`timescale 1ns / 1ps

typedef enum logic [1:0] {
    STATE_IDLE  = 2'b00,
    STATE_START = 2'b01,
    STATE_DATA  = 2'b10,
    STATE_STOP  = 2'b11
} uart_state_t;

module uart_tx #(
    parameter int unsigned CLK_FREQ_HZ = 50_000_000,
    parameter int unsigned BAUD_RATE   = 115_200,
    parameter int unsigned STOP_BITS = 1
) (
    input  logic       clk,
    input  logic       rst_n,

    // Data handshake
    input  logic [7:0] tx_data,
    input  logic       tx_valid,
    output logic       tx_ready, // ready to consume input data 

    // Physical line
    output logic       txd
);

    // TODO:
    // DONE - 1. Implement a clock prescaler generating bit clock ticks:
    //    CLKS_PER_BIT = (CLK_FREQ_HZ + BAUD_RATE/2) / BAUD_RATE.
    // DONE - 2. Build the state machine (FSM): IDLE, START, DATA, STOP.
    // DONE - 3. Transmit data bits in 8N1 format (LSB first).
    // DONE? - 4. Manage the tx_ready flag to support back-to-back continuous transmission.

    localparam int CLKS_PER_BIT = (CLK_FREQ_HZ + BAUD_RATE/2) / BAUD_RATE;

    logic [$clog2(CLKS_PER_BIT)-1:0] clk_counter;
    logic [3:0] bits_sent; // for state=2: count how many out of 8 bits are sent; for state=3 count how many out of 2 bits
    logic [1:0] state; // 0 - IDLE, 1 - START, 2 - DATA, 3 - STOP
    logic [7:0] tx_data_buffer;

    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            tx_ready <= 1'b1;
            txd <= 1'b1;
            state <= 1'b0;
            clk_counter <= 0;
            tx_data_buffer <= 0;
            bits_sent <= 0;
        end else begin
            if (state == STATE_IDLE) begin
                tx_ready <= 1'b1; 
                txd <= 1'b1;

                // Begin transfer
                if(tx_valid) begin
                    tx_data_buffer <= tx_data;
                    state <= STATE_START; 
                    bits_sent <= 0;
                end
            end else begin
                if (clk_counter < CLKS_PER_BIT) begin
                    if (clk_counter == 0) begin // State start
                        case (state) 
                            STATE_START: begin
                                tx_ready <= 1'b0;
                                txd <= 1'b0;
                            end
                            STATE_DATA: begin
                                tx_ready <= 1'b0;
                                txd <= tx_data_buffer[bits_sent];
                            end
                            STATE_STOP: begin
                                tx_ready <= 1'b0;
                                txd <= 1'b1;
                            end     
                        endcase
                    end else if(clk_counter == CLKS_PER_BIT-1) begin /// State end
                        case (state) 
                            STATE_START: begin
                                tx_ready <= 1'b0;
                                txd <= 1'b0;
                                state <= STATE_DATA;
                            end
                            STATE_DATA: begin
                                tx_ready <= 1'b0;
                                txd <= 1'b0;
                                if(bits_sent == 7) begin
                                    state <= STATE_STOP;
                                    bits_sent <= 0;
                                end else begin
                                    bits_sent <= bits_sent + 1;
                                end
                            end
                            STATE_STOP: begin
                                tx_ready <= 1'b0;
                                txd <= 1'b0;

                                if (bits_sent == (STOP_BITS-1)) begin // Send 1 (bits_sent == 0) or 2 (bits_sent == 1) stop bits
                                    state <= STATE_IDLE;
                                    bits_sent <= 0;
                                end else begin
                                    bits_sent <= bits_sent + 1;
                                end
                            end     
                        endcase
                    end
                    
                    clk_counter <= clk_counter + 1;
                end else begin // Handle unexpected clk_counter values
                    clk_counter <= 0;
                end   
            end
        end
    end

endmodule
