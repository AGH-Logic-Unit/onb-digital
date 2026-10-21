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

    // TODO:
    // 1. Implement a 2-stage synchronizer on the sig_in input.
    // 2. Calculate the required cycle count: CYCLES = (CLK_FREQ_HZ * STABLE_TIME_MS) / 1000.
    // 3. Implement a counter measuring the stability interval.
    // 4. Update sig_debounced with the stable input state.
    // 5. Generate 1-clock-cycle pulses for edge_rise and edge_fall.
    
    parameter int unsigned CYCLES_REQUIRED = (CLK_FREQ_HZ * STABLE_TIME_MS) / 1000; // 500_000

    logic ff1, sig_sync;
    logic prev_sig_debounced;
    logic [$clog2(CYCLES_REQUIRED) - 1:0] count;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            ff1 <= 0;
            sig_sync <= 0;
            count <= 0;
            edge_rise <= 0;
            edge_fall <= 0;
            sig_debounced <= 0;
        end else begin
            ff1 <= sig_in;
            sig_sync <= ff1;

            edge_rise <= 0;
            edge_fall <= 0;

            if (sig_sync == sig_debounced) begin
                count <= 0;
            end else if (count == CYCLES_REQUIRED-1) begin
                count <= 0;
                sig_debounced <= sig_sync;
                if (sig_sync) edge_rise <= 1;
                else edge_fall <= 1;
            end else begin
                count <= count + 1;
            end
        end
    end

endmodule
