`timescale 1ns / 1ps

module sync_fifo #(
    parameter int unsigned DATA_WIDTH          = 8,
    parameter int unsigned DEPTH               = 16,
    parameter int unsigned ALMOST_FULL_THRESH  = 14,
    parameter int unsigned ALMOST_EMPTY_THRESH = 2
) (
    input  logic                       clk,
    input  logic                       rst_n,

    // Write interface
    input  logic                       wr_en,
    input  logic [DATA_WIDTH-1:0]      wr_data,
    output logic                       full,
    output logic                       almost_full,

    // Read interface
    input  logic                       rd_en,
    output logic [DATA_WIDTH-1:0]      rd_data,
    output logic                       empty,
    output logic                       almost_empty,

    // Diagnostics / occupancy
    output logic [$clog2(DEPTH+1)-1:0] occupancy
);

    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    logic [$clog2(DEPTH)-1:0] rd_ptr, wr_ptr;

    logic read, write;
    assign read  = rd_en & ~empty;
    assign write = wr_en & ~full;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr    <= 'b0;
            wr_ptr    <= 'b0;
            rd_data   <= 'b0;
            occupancy <= 'b0;
        end else begin
            if (read) begin
                rd_data <= mem[rd_ptr];
                rd_ptr <= (rd_ptr == DEPTH - 1) ? 0 : rd_ptr + 1'b1;
            end

            if (write) begin
                mem[wr_ptr] <= wr_data;
                wr_ptr <= (wr_ptr == DEPTH - 1) ? 0 : wr_ptr + 1'b1;
            end

            occupancy <= occupancy + (write - read);
        end
    end

    assign empty        = occupancy == 0;
    assign full         = occupancy == DEPTH;
    assign almost_full  = occupancy >= ALMOST_FULL_THRESH;
    assign almost_empty = occupancy <= ALMOST_EMPTY_THRESH;

endmodule
