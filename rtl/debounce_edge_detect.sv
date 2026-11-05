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

    //assign sig_debounced = 1'b0;
    //assign edge_rise     = 1'b0;
    //assign edge_fall     = 1'b0;

    localparam CYCLES_REQ = (CLK_FREQ_HZ*STABLE_TIME_MS)/1000;
    
    logic n1,n2;
    logic [31:0] cycles;

    always_ff @(posedge clk, negedge rst_n) begin
            if (!rst_n) begin
                cycles <= 0;
                n2 <= 1'b0;            
                n1 <= 1'b0;
                sig_debounced <= 1'b0;
                edge_rise <= 1'b0;
                edge_fall <= 1'b0;

            end else begin
   
                n1 <= sig_in;
                n2 <=  n1;


                edge_rise <= 1'b0;
                edge_fall <= 1'b0;


                if (n2!=sig_debounced) begin
                    cycles <= cycles+1;
                    
                    if (cycles>=CYCLES_REQ) begin
                        sig_debounced <= n2;
                        cycles <= 0;
                        if (n2) begin
                                edge_rise <= 1'b1;
                        end else begin
                                edge_fall <= 1'b1;
                        end

                    end      
                end else begin
                    cycles <= 0;
                end  
            end      
    end
endmodule


`ifdef COCOTB_SIM
initial begin
    $dumpfile("debounce.fst");
    $dumpvars(0, debounce_edge_detect);
end
`endif