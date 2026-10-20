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
    // IN PROGRESS - 4. Implement an occupancy counter.
    // DONE - 5. Calculate flags: empty, full, almost_empty, almost_full.
    // 6. Handle simultaneous read and write.

    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    logic [$clog2(DEPTH):0] wr_ptr;
    logic [$clog2(DEPTH):0] rd_ptr;

    always_comb begin
        if (wr_ptr >= rd_ptr) begin
            assign occupancy = wr_ptr - rd_ptr;
        end else begin // e.g. rd_ptr is still at 14 and wr_ptr wrapped to 0
            assign occupancy = (DEPTH-1) - rd_ptr + wr_ptr + 1;
        end

        if (occupancy == (DEPTH-1)) begin
            assign full = 1'b1;
            assign almost_full = 1'b0;
            assign almost_empty = 1'b0;
            assign empty = 1'b0;
        end else if (occupancy >= ALMOST_FULL_THRESH) begin
            assign full = 1'b0;
            assign almost_full = 1'b1;
            assign almost_empty = 1'b0;
            assign empty = 1'b0;
        end else if (occupancy <= ALMOST_EMPTY_THRESH) begin
            assign full = 1'b0;
            assign almost_full = 1'b0;
            assign almost_empty = 1'b1;
            assign empty = 1'b0;
        end else if (occupancy == 0) begin
            assign full = 1'b0;
            assign almost_full = 1'b0;
            assign almost_empty = 1'b0;
            assign empty = 1'b1;
        end
    end

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            for (integer i = 0; i < DEPTH; i = i + 1) begin
                mem[i] <= 0;
            end

            wr_ptr <= 0;
            rd_ptr <= 0;
            // rd_data <= 0;
        end else begin
            if (wr_en) begin
                mem[wr_ptr] <= wr_data; 
                wr_ptr <= wr_ptr + 1;   
            end

            if (rd_en) begin
                rd_data <= mem[rd_ptr];
                rd_ptr <= rd_ptr + 1;
            end 
        end
    end
endmodule
