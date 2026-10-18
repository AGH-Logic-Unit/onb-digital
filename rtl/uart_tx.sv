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

    parameter int unsigned CLKS_PER_BIT = (CLK_FREQ_HZ + BAUD_RATE/2) / BAUD_RATE;

    logic [$clog2(CLKS_PER_BIT+1)-1:0] clk_counter;

    always_ff @(posedge clk) begin
        if (!rst_n || (uart_packet == 0)) begin
            clk_counter <= 0;
            tx_ready <= 1;
        end else begin
            if (clk_counter == CLKS_PER_BIT) clk_counter <= 0;
            else clk_counter <= clk_counter + 1;
        end
    end

    logic [9:0] uart_packet;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            txd <= 1;
            uart_packet <= 0;
        end else begin
            if (tx_valid && (uart_packet == 0)) begin
                uart_packet <= {1'b1, tx_data, 1'b0};
                tx_ready <= 0;
            end else if (uart_packet != 0 && (clk_counter == 0)) begin
                txd <= uart_packet[0];
                uart_packet <= uart_packet >> 1;
            end
        end
    end

    // assign tx_ready = 1'b1;
    // assign txd      = 1'b1;

endmodule
