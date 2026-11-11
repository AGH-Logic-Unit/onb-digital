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

    // TODO:
    // 1. Implement a clock prescaler generating bit clock ticks:
    //    CLKS_PER_BIT = (CLK_FREQ_HZ + BAUD_RATE/2) / BAUD_RATE.
    // 2. Build the state machine (FSM): IDLE, START, DATA, STOP.
    // 3. Transmit data bits in 8N1 format (LSB first).
    // 4. Manage the tx_ready flag to support back-to-back continuous transmission.

    typedef enum logic [1:0] {IDDLE, START, DATA,STOP} statetype;
    statetype state, nextstate;

    localparam CLKS_PER_BIT = (CLK_FREQ_HZ + BAUD_RATE/2) / BAUD_RATE;
    logic [$clog2(CLKS_PER_BIT)-1:0] cnt;
    logic [2:0] bit_ptr;
    logic [7:0] stored;
    //4a        0100101
    //a5 STOP 1 10100101 0 START
    
    

    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            tx_ready<= 1'b1;
            txd <= 1'b1;
            state <= IDDLE;
            cnt <= 0;
            bit_ptr <= 3'b0;
            stored <= '0;
        end else begin
            state <= nextstate;

            case(state) 
            IDDLE:  begin
                txd <= 1'b1;
                cnt <= '0;
                bit_ptr <= 3'b0;
                tx_ready <= 1'b1;
                if (tx_valid) begin 
                    tx_ready<=1'b0;
                    stored <= tx_data;    
                end                
            end
            START:  begin
                
                txd <= 1'b0;
                if (cnt == CLKS_PER_BIT[$clog2(CLKS_PER_BIT)-1:0] -1) begin
                    txd <= stored[0];
                    cnt <= '0;
                end else begin
                    cnt <= cnt + 1;
                end
            end
            DATA: begin
                if (cnt == CLKS_PER_BIT[$clog2(CLKS_PER_BIT)-1:0] -1) begin
                    cnt <= 0;
                    if (bit_ptr < 3'b111) begin
                        bit_ptr <= bit_ptr +1;
                        txd <= stored[bit_ptr+1];
                    end

                end else begin
                    cnt <= cnt + 1;
                end
            end   
            STOP:   begin
                txd <= 1'b1;
                if (cnt == CLKS_PER_BIT[$clog2(CLKS_PER_BIT)-1:0] -1) begin
                    cnt <= '0;
                    tx_ready <= 1'b1;
                end else begin
                    cnt <= cnt + 1;
                end
            end  
        endcase
        end

        
    end

    always_comb begin
        nextstate = state;
        case(state)
            IDDLE: if (tx_valid) nextstate=START;
            START: if (cnt == CLKS_PER_BIT[$clog2(CLKS_PER_BIT)-1:0] -1) nextstate=DATA;
            DATA: if (cnt == CLKS_PER_BIT[$clog2(CLKS_PER_BIT)-1:0] -1 && bit_ptr == 3'b111) nextstate= STOP;
            STOP: if (cnt == CLKS_PER_BIT[$clog2(CLKS_PER_BIT)-1:0] - 1) nextstate= IDDLE;
        endcase 
    end
endmodule

`ifdef COCOTB_SIM
initial begin
    $dumpfile("uart_tx.fst");
    $dumpvars(0, uart_tx);
end
`endif