`timescale 1ns / 1ps

module uart_tx #(
    parameter int unsigned CLK_FREQ_HZ  = 50_000_000,
    parameter int unsigned BAUD_RATE    = 115_200,
    parameter int unsigned CLKS_PER_BIT = (CLK_FREQ_HZ + BAUD_RATE/2) / BAUD_RATE
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
    // DONE: 1. Implement a clock prescaler generating bit clock ticks:
    //          CLKS_PER_BIT = (CLK_FREQ_HZ + BAUD_RATE/2) / BAUD_RATE.
    // DONE: 2. Build the state machine (FSM): IDLE, START, DATA, STOP.
    // DONE: 3. Transmit data bits in 8N1 format (LSB first).
    // DONE: 4. Manage the tx_ready flag to support back-to-back continuous transmission.

    typedef enum logic [1:0] {
        IDLE,
        START,
        DATA,
        STOP
    } state_t;

    state_t state;

    logic [7:0]                      data_reg;
    logic [$clog2(CLKS_PER_BIT)-1:0] clk_count;
    logic [2:0]                      bit_idx;

    assign tx_ready = (state == IDLE) | ((state == STOP) && (clk_count == CLKS_PER_BIT - 1));

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            clk_count <= '0;
            bit_idx <= '0;
            data_reg <= '0;
            txd <= 1'b1;
        end else begin
            case (state)
                IDLE: begin
                    txd <= 1'b1;
                    clk_count <= '0;
                    bit_idx <= '0;

                    if (tx_valid) begin
                        data_reg <= tx_data;
                        state <= START;
                    end
                end

                START: begin
                    txd <= 1'b0; // start transmission with one 0 bit

                    if (clk_count == CLKS_PER_BIT - 1) begin
                        clk_count <= '0;
                        state <= DATA;
                        bit_idx <= '0;
                    end else begin
                        clk_count <= clk_count + 1;
                    end
                end

                DATA: begin
                    txd <= data_reg[bit_idx];

                    if (clk_count == CLKS_PER_BIT - 1) begin
                        clk_count <= '0;
                        if (bit_idx == 3'd7) begin
                            state <= STOP;
                        end else begin
                            bit_idx <= bit_idx + 1;
                        end
                    end else begin
                        clk_count <= clk_count + 1;
                    end
                end

                STOP: begin
                    txd <= 1'b1; // end transmission with 1 bit

                    if (clk_count == CLKS_PER_BIT - 1) begin
                        clk_count <= '0;
                        if (tx_valid) begin
                            data_reg <= tx_data;
                            state <= START;
                        end else begin
                            state <= IDLE;
                        end
                    end else begin
                        clk_count <= clk_count + 1;
                    end
                end

                // redundant, but linter won't shut up about a missing default
                default: state <= IDLE;
            endcase
        end
    end
endmodule
