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
    // DONE - 1. Implement a 2-stage synchronizer on the sig_in input.
    // DONE - 2. Calculate the required cycle count: CYCLES = (CLK_FREQ_HZ * STABLE_TIME_MS) / 1000.
    // DONE - 3. Implement a counter measuring the stability interval.
    // DONE? - 4. Update sig_debounced with the stable input state.
    // DONE? - 5. Generate 1-clock-cycle pulses for edge_rise and edge_fall.

    localparam CYCLES = (CLK_FREQ_HZ * STABLE_TIME_MS) / 1000;

    logic [$clog2(CYCLES)-1:0] counter;

    logic ff1;
    logic ff2;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sig_debounced <= 1'b0;
            edge_rise <= 1'b0;
            edge_fall <= 1'b0;
            ff1 <= 1'b0;
            ff2 <= 1'b0;
            counter <= 1'b0;
        end else begin
            ff1 <= sig_in;
            ff2 <= ff1;

            if (edge_rise) begin
                edge_rise <= 1'b0;
            end
            if (edge_fall) begin
                edge_fall <= 1'b0;
            end

            if (ff2) begin
                if (counter > CYCLES) begin
                    sig_debounced <= 1'b1;
                    edge_rise <= 1'b1;
                    edge_fall <= 1'b0;

                    counter <= 1'b0;
                end else begin
                    //sig_debounced <= 1'b0;
                    counter <= counter + 1;  
                end
            end else begin
                // Not sure when is the right time to rise the edge_fall signal?
                if (sig_debounced) begin
                    edge_fall <= 1'b1;
                end

                sig_debounced <= 1'b0;
                counter <= 1'b0;
            end
        end
    end

    // Not sure when is the right time to rise the edge_fall signal?
    // always_ff @(negedge clk) begin
    //     if (!ff2) begin
    //         edge_fall <= 1'b1;
    //     end 
    // end
endmodule
