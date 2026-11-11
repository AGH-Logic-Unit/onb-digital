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

    localparam int unsigned CLKS_PER_BIT = (CLK_FREQ_HZ + BAUD_RATE / 2) / BAUD_RATE;
    localparam int unsigned COUNTER_BITS = $clog2(CLKS_PER_BIT);
    logic [COUNTER_BITS-1:0] counter;
    logic tx_clk;
    assign tx_clk = counter == 'b0;

    typedef enum {IDLE, WAIT, START, DATA, STOP} state_e;
    state_e state_d, state_q;

    logic [2:0] ptr_d, ptr_q;

    always_comb begin
        state_d = state_q;
        tx_ready = 1'b0;
        ptr_d = ptr_q;
        unique case (state_q)
            IDLE: begin
                if (tx_valid) begin
                    if (tx_clk) state_d = START;
                    else state_d = WAIT;
                end
                tx_ready = 1'b1;
                txd = 1'b1;
            end
            WAIT: begin
                if (tx_clk) state_d = START;
                txd = 1'b1;
            end
            START: begin
                if (tx_clk) state_d = DATA;
                txd = 1'b0;
            end
            DATA: begin
                if (tx_clk) begin
                    if (ptr_q == 7) state_d = STOP;
                    ptr_d = ptr_q + 1;
                end
                txd = tx_data[ptr_q];
            end
            STOP: begin
                if (tx_clk) state_d = IDLE;
                txd = 1'b1;
            end
        endcase
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_q <= IDLE;
            ptr_q <= 1'b0;
            counter <= 'b0;
        end else begin
            state_q <= state_d;
            ptr_q <= ptr_d;
            counter <= (counter != CLKS_PER_BIT - 1) ? counter + 1 : 0;
        end
    end

endmodule
