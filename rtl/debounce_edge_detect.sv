`timescale 1ns / 1ps

module d_ff(
	input logic clk,
	input logic sig_in,
	input logic rst_n,
	output reg q);

	always @ (posedge clk) begin
		if(rst_n)
			q <= 0;
		else
			q <= sig_in;
	end

endmodule

module debouncer #(
	parameter int unsigned CYCLES
)  (
	input logic clk,
	input logic rst_n,
	input logic q1 
	output reg out);

	reg[18:0] counter = 0;

	always @(posedge clk) begin
		if(rst_n)
			out <= 0;
			counter <= 0;
		else
			if(q1 == out)
				counter <= 0;
			else if(counter >= CYCLES)
				out <= q1;
			else
				counter <= counter + 1;
	end
endmodule

module edge_detect (
	input logic clk,
	input sig_in,
	input rst_n,
	output logic edge_rise,
	output logic edge_fall );
	
	reg prev = 0;
	d_ff(clk, rst_n, sig_in, prev);

	always @(posedge clk) begin
		if(sig_in & (~prev))
			edge_rise <= 1;
		else if(!(sig_in & (~prev)))
			edge_rise <= 0;
		if((~sig_in) & prev)
			edge_fail <= 1;
		else if(!((~sig_in) & prev))
			edge_fail <= 0;
	end
endmodule

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
    assign sig_debounced = 1'b0;
    assign edge_rise      = 1'b0;
    assign edge_fall      = 1'b0;

    assign q0 = 1'b0;
    assign q1 = 1'b0;

    d_ff f0(clk, sig_in, rst_n, q0);
    d_ff f1(clk, q0, rst_n, q1);
    
    int unsigned CYCLES = (CLK_FREQ_HZ * STABLE_TIME_MS) / 1000;
     
    // TODO:
    // 1. Implement a 2-stage synchronizer on the sig_in input.
    // 2. Calculate the required cycle count: CYCLES = (CLK_FREQ_HZ * STABLE_TIME_MS) / 1000.
    // 3. Implement a counter measuring the stability interval.
    // 4. Update sig_debounced with the stable input state.
    // 5. Generate 1-clock-cycle pulses for edge_rise and edge_fall.

    debouncer deb(CYCLES, clk, rst_n, q1, sig_debounced);
    edge_detect edg(clk, sig_debounced, rst_n, edge_rise, edge_fail);	

endmodule
