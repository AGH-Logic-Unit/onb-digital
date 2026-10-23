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

	localparam int unsigned CLKS_PER_BIT = (CLK_FREQ_HZ + BAUD_RATE/2) / BAUD_RATE;

	// State Machine Section

	typedef enum logic [1:0] {
    IDLE  = 2'd0,
    START = 2'd1,
    DATA  = 2'd2,
    STOP  = 2'd3
	} state_t;

	state_t State;
	state_t Next_State;
	logic [7:0] tx_data_saved;
	logic [2:0] bit_idx;

	//Prescale Section

	logic [$clog2(CLKS_PER_BIT)-1:0] counter;
    logic bit_tick;

	always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= '0;
        end else begin
            if (State == IDLE || counter == CLKS_PER_BIT - 1) begin
                counter <= '0;
            end else begin
                counter <= counter + 1'b1;
            end
        end
    end

	assign bit_tick = (counter == CLKS_PER_BIT - 1);

	assign tx_ready = (State == IDLE || (State == STOP && bit_tick));


	always_comb begin
		Next_State = State;
		case (State)
			IDLE: begin
				if (tx_valid) begin
					Next_State = START;
				end
			end
			START: begin
				if (bit_tick) begin
					Next_State = DATA;
				end
			end
			DATA: begin
				if (bit_tick && (bit_idx[2:0] == 3'd7)) begin
					Next_State = STOP;
				end

			end
			STOP: begin
				if (bit_tick && tx_valid) begin
					Next_State = START;
				end
				else if (bit_tick) begin
					Next_State = IDLE;
				end
			end
		endcase
	end

	always_ff @(posedge clk or negedge rst_n) begin
		 if (~rst_n) begin
			State <= IDLE;
			tx_data_saved <= '0;
            bit_idx       <= '0;
		 end
		 else begin
			State <= Next_State;
			if (tx_ready && tx_valid) begin
				tx_data_saved <= tx_data;
		    end
			else if (State == DATA && bit_tick) begin
                tx_data_saved <= {1'b0, tx_data_saved[7:1]};
                bit_idx       <= bit_idx + 1'b1;
            end
		 end
	end

    always_comb begin
		case (State)
			START: begin
				txd = 1'b0;
			end
			DATA: begin
				txd = tx_data_saved[0];
			end
			default: begin
				txd = 1'b1;
			end
		endcase
	end

endmodule