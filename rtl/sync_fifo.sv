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
    // 1. Declare the RAM memory array: logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    // 2. Implement write (wr_ptr) and read (rd_ptr) pointers.
    // 3. Implement an occupancy counter.
    // 4. Calculate flags: empty, full, almost_empty, almost_full.
    // 5. Handle simultaneous read and write.

    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    logic [$clog2(DEPTH)-1:0] wr_ptr, rd_ptr;

    assign empty = (occupancy == 0) ? 1 : 0;
    assign full = (occupancy == DEPTH) ? 1 : 0;

    assign almost_empty = (occupancy <= ALMOST_EMPTY_THRESH) ? 1 : 0;
    assign almost_full  = (occupancy >= ALMOST_FULL_THRESH) ? 1 : 0;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            occupancy <= 0;
            for (int i = 0; i < DEPTH; i = i + 1) mem[i] <= 0;
        end else begin
            if (wr_en && rd_en) begin
                if (wr_ptr == DEPTH-1) begin // it can be just "wr_ptr <= wr_ptr + 1;" if depth is a power of 2
                    wr_ptr <= 0;
                end else begin
                    wr_ptr <= wr_ptr + 1;
                end
                if (rd_ptr == DEPTH-1) begin // it can be just "rd_ptr <= rd_ptr + 1;" if depth is a power of 2
                    rd_ptr <= 0;
                end else begin
                    rd_ptr <= rd_ptr + 1;
                end
                mem[wr_ptr] <= wr_data;
                // rd_data <= mem[rd_ptr]; // should work but it doesnt bc of race condition (tests fault)
            end else if (wr_en && !full) begin
                occupancy <= occupancy + 1;
                if (wr_ptr == DEPTH-1) begin // it can be just "wr_ptr <= wr_ptr + 1;" if depth is a power of 2
                    wr_ptr <= 0;
                end else begin
                    wr_ptr <= wr_ptr + 1;
                end
                mem[wr_ptr] <= wr_data;
            end else if (rd_en && !empty) begin
                occupancy <= occupancy - 1;
                if (rd_ptr == DEPTH-1) begin // it can be just "rd_ptr <= rd_ptr + 1;" if depth is a power of 2
                    rd_ptr <= 0;
                end else begin
                    rd_ptr <= rd_ptr + 1;
                end
                // rd_data <= mem[rd_ptr]; // should work but it doesnt bc of race condition (tests fault)
            end
        end
    end

    assign rd_data = (rd_en) ? mem[rd_ptr] : 0; // race condition fix

endmodule
