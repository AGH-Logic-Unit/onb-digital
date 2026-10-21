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

    localparam CLKS_PER_BIT = (CLK_FREQ_HZ + BAUD_RATE/2) / BAUD_RATE;

    logic [$clog2(CLKS_PER_BIT+1)-1:0] clk_cnt;
    logic [3:0] bit_cnt;

    localparam IDLE     = 2'b00;
    localparam START    = 2'b01;
    localparam DATA     = 2'b10;
    localparam STOP     = 2'b11;

    logic [1:0] state;
    logic [7:0] tx_data_buf;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            txd <= 1;
            tx_ready <= 1;
            bit_cnt <= 0;
            clk_cnt <= 0;
            state <= IDLE;
        end else begin
            case (state)
                IDLE: begin
                    if (tx_ready && tx_valid) begin
                        tx_data_buf <= tx_data;
                        tx_ready <= 0;
                        clk_cnt <= 0;
                        state <= START;
                    end
                end

                START: begin
                    if (clk_cnt == 0) begin
                        txd <= 0;
                        clk_cnt <= clk_cnt + 1;
                    end else if (clk_cnt == CLKS_PER_BIT-1) begin
                        clk_cnt <= 0;
                        bit_cnt <= 0;
                        state <= DATA;
                    end else begin
                        clk_cnt <= clk_cnt + 1;
                    end
                end

                DATA: begin
                    if (clk_cnt == 0) begin
                        txd <= tx_data_buf[0];
                        tx_data_buf <= tx_data_buf >> 1;
                        clk_cnt <= clk_cnt + 1;
                        bit_cnt <= bit_cnt + 1;
                    end else if (clk_cnt == CLKS_PER_BIT-1) begin
                        clk_cnt <= 0;
                        if (bit_cnt == 8) state <= STOP;
                    end else begin
                        clk_cnt <= clk_cnt + 1;
                    end
                end

                STOP: begin
                    if (clk_cnt == 0) begin
                        txd <= 1;
                        clk_cnt <= clk_cnt + 1;
                    end else if (clk_cnt == CLKS_PER_BIT-1) begin
                        if (tx_valid) begin
                            tx_data_buf <= tx_data;
                            tx_ready <= 0;
                            clk_cnt <= 0;
                            state <= START;
                        end
                        else begin
                            state <= IDLE;
                        end
                    end else if (clk_cnt == CLKS_PER_BIT-2) begin
                        tx_ready <= 1;
                        clk_cnt <= clk_cnt + 1;
                    end else begin
                        clk_cnt <= clk_cnt + 1;
                    end
                end
            endcase
        end
    end

endmodule