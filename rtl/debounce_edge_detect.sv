`timescale 1ns / 1ps

module debounce_edge_detect #(
    parameter int unsigned CLK_FREQ_HZ    = 50_000_000,
    parameter int unsigned STABLE_TIME_MS = 10
) (
    input  logic clk,
    input  logic rst_n,
    input  logic sig_in,
    output logic sig_debounced,
    output logic edge_rise,
    output logic edge_fall
);
    parameter int unsigned CYCLES = (CLK_FREQ_HZ * STABLE_TIME_MS) / 1000;
    parameter int unsigned CYCLES_BITS = $clog2(CYCLES + 1);

    logic sig_d, sig_new;

    always_ff @(posedge clk or negedge rst_n) begin
        sig_d   <= rst_n & sig_in;
        sig_new <= rst_n & sig_d;
    end

    logic [CYCLES_BITS-1:0] counter;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n || sig_new == sig_debounced) begin
            counter <= '0;
            edge_rise <= 0;
            edge_fall <= 0;
            if (!rst_n) sig_debounced <= 0;
        end else if (counter != CYCLES) begin
            counter <= counter + 1;
            edge_rise <= 0;
            edge_fall <= 0;
        end else begin
            counter <= 0;
            edge_rise <= sig_new;
            edge_fall <= !sig_new;
            sig_debounced <= sig_new;
        end
    end

endmodule
