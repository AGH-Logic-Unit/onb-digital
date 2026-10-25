`timescale 1ns / 1ps

module sync_fifo #(
    parameter int unsigned DATA_WIDTH          = 8,
    parameter int unsigned DEPTH               = 16,
    parameter int unsigned ALMOST_FULL_THRESH  = 14,
    parameter int unsigned ALMOST_EMPTY_THRESH = 2
) (
    input  logic                    clk,
    input  logic                    rst_n,

    // Write interface
    input  logic                    wr_en,
    input  logic [DATA_WIDTH-1:0]   wr_data,
    output logic                    full,
    output logic                    almost_full,

    // Read interface
    input  logic                    rd_en,
    output logic [DATA_WIDTH-1:0]   rd_data,
    output logic                    empty,
    output logic                    almost_empty,

    // Diagnostics / occupancy
    output logic [$clog2(DEPTH):0]  occupancy
);

    // TODO:
    // DONE - 1. Declare the RAM memory array: logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    // DONE - 2. Implement write (wr_ptr) and read (rd_ptr) pointers.
    // DONE - 3. Implement synchronous registered read on rd_data when rd_en is asserted.
    // DONE - 4. Implement an occupancy counter.
    // DONE - 5. Calculate flags: empty, full, almost_empty, almost_full.
    // DONE - 6. Handle simultaneous read and write.

    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    logic [$clog2(DEPTH)-1:0] wr_ptr;
    logic [$clog2(DEPTH)-1:0] rd_ptr;

    assign simultaneous_rw = wr_en && rd_en;

    always_comb begin
        full = (occupancy == DEPTH);
        almost_full = (occupancy >= ALMOST_FULL_THRESH);
        empty = (occupancy == 0);
        almost_empty = (occupancy <= ALMOST_EMPTY_THRESH); 
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (integer i = 0; i < DEPTH; i = i + 1) begin
                mem[i] <= 0;
            end

            wr_ptr <= 0;
            rd_ptr <= 0;
            rd_data <= 0;
            occupancy <= 0;
        end else begin
            if (wr_en) begin 
                if (full) begin // allow for write if reading simultaneously
                    if (simultaneous_rw) begin
                        mem[wr_ptr] <= wr_data; 
                        wr_ptr <= wr_ptr + 1; // wrapping
                    end
                end else begin
                    mem[wr_ptr] <= wr_data; 
                    wr_ptr <= wr_ptr + 1;   

                    if(!simultaneous_rw) begin
                        occupancy <= occupancy + 1; 
                    end 
                end
            end

            if (rd_en && !empty) begin
                rd_data <= mem[rd_ptr];
                rd_ptr <= rd_ptr + 1;

                if(!simultaneous_rw) begin
                    occupancy <= occupancy - 1;
                end 
            end 
        end
    end
    
endmodule
