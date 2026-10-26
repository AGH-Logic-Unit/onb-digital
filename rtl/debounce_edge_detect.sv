`timescale 1ns / 1ps

module synchroniser (
    input  logic clk,
    input  logic rst_n,
    input  logic sig_in,
    output logic sig_out
);
    logic ff1, ff2;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ff1 <= 0;
            ff2 <= 0;
        end else begin
            ff1 <= sig_in;
            ff2 <= ff1;
        end
    end
endmodule

module debouncer #(
    parameter int unsigned CYCLES
) (
    input  logic  clk,
    input  logic  rst_n,
    input  logic  sig_in,
    output logic  sig_debounced
);
    logic [$clog2(CYCLES):0] counter;
    logic                    debounced;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= '0;
            debounced <= 1'b0;
        end else begin
            if (sig_in != debounced) begin
                if (counter > CYCLES) begin
                    debounced <= sig_in;
                    counter <= '0;
                end
                else begin
                    counter <= counter + 1'b1;
                end
            end else begin
                counter <= '0;
            end
        end
    end

    assign sig_debounced = debounced;
endmodule

module debounce_edge_detect #(
    parameter int unsigned CLK_FREQ_HZ = 50_000_000,
    parameter int unsigned STABLE_TIME_MS = 10,
    parameter int unsigned CYCLES = (CLK_FREQ_HZ * STABLE_TIME_MS) / 1000
) (
    input  logic clk,
    input  logic rst_n,
    input  logic sig_in,
    output logic sig_debounced,
    output logic edge_rise,
    output logic edge_fall
);

    // TODO:
    // DONE: 1. Implement a 2-stage synchronizer on the sig_in input.
    // DONE: 2. Calculate the required cycle count: CYCLES = (CLK_FREQ_HZ * STABLE_TIME_MS) / 1000.
    // DONE: 3. Implement a counter measuring the stability interval.
    // DONE: 4. Update sig_debounced with the stable input state.
    // 5. Generate 1-clock-cycle pulses for edge_rise and edge_fall.

    logic sig_sync;
    synchroniser sync(
        .clk(clk),
        .rst_n(rst_n),
        .sig_in(sig_in),
        .sig_out(sig_sync)
    );

    debouncer #(
        .CYCLES(CYCLES)
    ) deb (
        .clk(clk),
        .rst_n(rst_n),
        .sig_in(sig_in),
        .sig_debounced(sig_debounced)
    );

    assign edge_rise = 1'b0;
    assign edge_fall = 1'b0;

endmodule
