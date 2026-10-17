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
	
  localparam int unsigned CYCLES = (CLK_FREQ_HZ * STABLE_TIME_MS) / 1000;
  
  logic inter_synchro;
  logic sig_synchro;
  
  always_ff @(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
	  inter_synchro <= 1'b0;
      sig_synchro   <= 1'b0;
	end
	else begin
		inter_synchro <= sig_in;
		sig_synchro <= inter_synchro;
	end
  end
  
  

endmodule
