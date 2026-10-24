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
  
  logic [$clog2(CYCLES)-1:0] counter;
  logic sig_saved;
  logic ena_counter;
  
  always_comb begin
    ena_counter = 1'b0;
    if ((sig_saved == sig_synchro) && (sig_synchro != sig_debounced)) begin
      ena_counter = 1'b1;
    end
  end
  
  logic sig_debounced_saved;
  
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      sig_saved             <= 1'b0;
      sig_debounced         <= 1'b0;
      sig_debounced_saved   <= 1'b0;
      counter               <= '0;
    end else begin
      sig_saved <= sig_synchro;
	  sig_debounced_saved <= sig_debounced;
      if (ena_counter && (counter < CYCLES - 1)) begin
        counter <= counter + 1;
      end
      else if ((ena_counter) && (counter == CYCLES - 1)) begin
        sig_debounced       <= sig_synchro;
        counter             <= '0;
      end
      else begin
        counter <= '0;
      end
    end
  end
  
  always_comb begin
    edge_rise = 1'b0;
    edge_fall = 1'b0;
    if ((sig_debounced_saved == 1'b1) && (sig_debounced == 1'b0)) begin
      edge_fall = 1'b1;
    end
    else if ((sig_debounced_saved == 1'b0) && (sig_debounced == 1'b1)) begin
      edge_rise = 1'b1;
    end
  end

endmodule
