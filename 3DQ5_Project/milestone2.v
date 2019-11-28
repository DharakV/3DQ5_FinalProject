`ifndef DISABLE_DEFAULT_NET
`timescale 1ns/100ps
`default_nettype none
`endif
`include "define_state.h"

//mulitplier module which we will instantiate 2 times 
module M2_Multiplier (
	input int op1, op2,
	output int out
);

	logic [63:0] Mult_result_long;
	assign Mult_result_long = op1 * op2;
	assign out = Mult_result_long[31:0];

endmodule

module milestone2(
	input logic CLOCK_50_I,
	input logic Resetn,
	input logic m2_start,
	input logic [15:0] SRAM_read_data,
	output logic [15:0] SRAM_write_data,
	output logic [17:0] SRAM_address,
	output logic write_en_n,
	output logic m2_finish
);

m2_state_type m2_state;

//all math on 32 bit signed
logic signed [31:0] m1_op1;
logic signed [31:0] m1_op2;
logic signed [31:0] m2_op1;
logic signed [31:0] m2_op2;
logic signed [31:0] m1_out;
logic signed [31:0] m2_out;

M2_Multiplier mult1(
	.op1(m1_op1),
	.op2(m1_op2),
	.out(m1_out)
);

M2_Multiplier mult2(
	.op1(m2_op1),
	.op2(m2_op2),
	.out(m2_out)
);

logic [6:0] address0;
logic [31:0] data_in0;
logic write_en0;
logic [31:0] data_out0;

logic [6:0] address1;
logic [31:0] data_in1;
logic write_en1;
logic [31:0] data_out1;

logic [6:0] address2;
logic [31:0] data_in2;
logic write_en2;
logic [31:0] data_out2;

logic [6:0] address3;
logic [31:0] data_in3;
logic write_en3;
logic [31:0] data_out3;

//instintiate DP-RAM1 
dual_port_RAM0 dual_port_RAM0_inst (
	.address_a (address0),
	.address_b (address1),
	.clock (CLOCK_50_I),
	.data_a (data_in0),
	.data_b (data_in1),
	.wren_a (write_en0),
	.wren_b (write_en1),
	.q_a (data_out0),
	.q_b (data_out1)
);

//instintiate DP-RAM2 
dual_port_RAM1 dual_port_RAM1_inst (
	.address_a (address2),
	.address_b (address3),
	.clock (CLOCK_50_I),
	.data_a (data_in2),
	.data_b (data_in3),
	.wren_a (write_en2),
	.wren_b (write_en3),
	.q_a (data_out2),
	.q_b (data_out3)
);

logic [2:0] row_counter; //8 rows of data per 8x8 block of pre-IDCT data
logic [2:0] column_counter; //8 columns of data per 8x8 block of pre-IDCT data
logic [5:0] block_col; //the column location of the 8x8 block we are reading 
logic [4:0] block_row; //the row location of the 8x8 block we are reading

logic read_y;
logic read_u;
logic read_v;

logic [15:0] Sprime_row [7:0];

logic [2:0] increase_Saddress;
logic [2:0] increase_Taddress;
logic signed [31:0] T_first;
logic signed [31:0] T_second;
logic signed [31:0] S_first;
logic signed [31:0] S_second;

logic signed [15:0] bit_T_first;
logic signed [15:0] bit_T_second; 

logic [31:0] temp_S_first;
logic [31:0] temp_S_second;
logic [31:0] S_first_p;
logic [31:0] S_second_p;
logic [7:0] clipped_S_first;
logic [7:0] clipped_S_second;

always_comb begin
	bit_T_first = (T_first >>> 8); 
	bit_T_second = ((T_second + m1_out + m2_out) >>> 8);

	//clipped_S_first = ((S_first >>> 16) > 32'sd255) ? 8'd255 : (((S_first >>> 16) < 32'sd0) ? 8'd0 : (S_first >>> 16));
	//clipped_S_second = (((S_second + m1_out + m2_out) >>> 16) > 32'sd255) ? 8'd255 : ((((S_second + m1_out + m2_out) >>> 16) < 32'sd0) ? 8'd0 : ((S_second + m1_out + m2_out) >>> 16));

	clipped_S_first = (S_first >>> 16);
	clipped_S_second = ((S_second + m1_out + m2_out) >>> 16);

end

always @(posedge CLOCK_50_I or negedge Resetn) begin
	if (~Resetn) begin
		block_col <= 6'd0;
		block_row <= 5'd0;
		row_counter <= 3'd0;
		column_counter <= 3'd0;
		SRAM_address <= 18'd0;

		Sprime_row[0] <= 16'd0;
		Sprime_row[1] <= 16'd0;
		Sprime_row[2] <= 16'd0;
		Sprime_row[3] <= 16'd0;
		Sprime_row[4] <= 16'd0;
		Sprime_row[5] <= 16'd0;
		Sprime_row[6] <= 16'd0;
		Sprime_row[7] <= 16'd0;

		//at reset, we start reading pre-IDCT y values FIRST 
		read_y <= 1'd1;
		read_u <= 1'd0;
		read_v <= 1'd0;

		S_first <= 16'd0;
		S_second <= 16'd0;
		T_first <= 16'd0;
		T_second <= 16'd0;

		//initialize the rest of the signals as we add them to the program
		increase_Saddress <= 3'd0;
		increase_Taddress <= 3'd0;

		//initialize
		m1_op1 <= 32'd0;
		m1_op2 <= 32'd0;
		m2_op1 <= 32'd0;
		m2_op2 <= 32'd0;
		m2_op1 <= 32'd0;

		data_in0 <= 32'd0;
		data_in1 <= 32'd0;
		data_in2 <= 32'd0;
		data_in3 <= 32'd0;

		write_en0 <= 1'd0;
		write_en1 <= 1'd0;
		write_en2 <= 1'd0;
		write_en3 <= 1'd0;

		address0 <= 7'd0;
		address1 <= 7'd0;
		address2 <= 7'd0;
		address3 <= 7'd0;

		SRAM_write_data <= 16'd0;

	end else begin

		case(m2_state)
			
		m2_idle: begin
			if (m2_start) begin
				m2_state <= fill_lead_in0;
			end
		end

		//multiplying block row and 
		fill_lead_in0: begin
			m1_op1 <= block_col;
			m1_op2 <= 32'd8;
			m2_op1 <= block_row;
			m2_op2 <= 32'd2560;

			m2_state <= fill_lead_in1;
		end

		//read S'0 and C
		fill_lead_in1: begin
			
			write_en_n <= 1'b1;

			column_counter <= m1_out;
			row_counter <= m2_out;

			//statements to move SRAM_address to the next 8x8 block if respective signals are high
			if (read_y) begin
				SRAM_address <= 18'd76800 + m1_out + m2_out;
			end else if (read_u) begin
				SRAM_address <= 18'd153600 + m1_out + m2_out;
			end else if (read_v) begin
				SRAM_address <= 18'd192000 + m1_out + m2_out;
			end

			address0 <= 7'd0;
			write_en0 <= 1'b0;

			address1 <= 7'd32;

			m2_state <= fill_lead_in2;
		end

		//read S'1
		fill_lead_in2: begin
			SRAM_address <= SRAM_address + 18'd1;

			m2_state <= fill_lead_in3;
		end
		
		//read S'2
		fill_lead_in3: begin
			SRAM_address <= SRAM_address + 18'd1;
			
			m2_state <= fill_lead_in4;
		end

		fill_lead_in4: begin
			SRAM_address <= SRAM_address + 18'd1;
			Sprime_row[0] <= SRAM_read_data;

			m2_state <= fill_lead_in5;
		end


		fill_lead_in5: begin
			SRAM_address <= SRAM_address + 18'd1;
			Sprime_row[1] <= SRAM_read_data;

			m2_state <= fill_lead_in6;
		end

		fill_lead_in6: begin
			SRAM_address <= SRAM_address + 18'd1;
			Sprime_row[2] <= SRAM_read_data;

			write_en0 <= 1'd1;
			data_in0 <= {Sprime_row[0], Sprime_row[1]};
			
			m2_state <= fill_lead_in7;
		end

		fill_lead_in7: begin
			SRAM_address <= SRAM_address + 18'd1;
			Sprime_row[3] <= SRAM_read_data;
			
			m2_state <= fill_lead_in8;
		end

		fill_lead_in8: begin
			SRAM_address <= SRAM_address + 18'd1;
			Sprime_row[4] <= SRAM_read_data;

			address0 <= address0 + 7'd1;
			data_in0 <= {Sprime_row[2], Sprime_row[3]};
			
			m2_state <= fill_lead_in9;
		end

		fill_lead_in9: begin
			if (read_y) begin
				SRAM_address <= SRAM_address + 18'd313;
			end else begin
				SRAM_address <= SRAM_address + 18'd153;
			end

			Sprime_row[5] <= SRAM_read_data;
			
			m2_state <= fill_lead_in10;
		end

		fill_lead_in10: begin
			SRAM_address <= SRAM_address + 18'd1;
			Sprime_row[6] <= SRAM_read_data;

			address0 <= address0 + 7'd1;
			data_in0 <= {Sprime_row[4], Sprime_row[5]};
			
			m2_state <= fill_lead_in11;
		end

		fill_lead_in11: begin
			SRAM_address <= SRAM_address + 18'd1;
			Sprime_row[7] <= SRAM_read_data;

			address0 <= address0 + 7'd1;
			data_in0 <= {Sprime_row[6], SRAM_read_data};
			
			m2_state <= fill_CC0;
		end


		//read S'3 and store S'0
		fill_CC0: begin
			SRAM_address <= SRAM_address + 18'd1;
			Sprime_row[0] <= SRAM_read_data;

			write_en0 <= 1'b0;
			
			m2_state <= fill_CC1;
		end

		//read S'4 and store S'1
		fill_CC1: begin
			SRAM_address <= SRAM_address + 18'd1;
			Sprime_row[1] <= SRAM_read_data;

			m2_state <= fill_CC2;
		end

		//read S'5 and store S'2
		fill_CC2: begin
			SRAM_address <= SRAM_address + 18'd1;
			Sprime_row[2] <= SRAM_read_data;

			write_en0 <= 1'd1;
			address0 <= address0 + 7'd1;
			data_in0 <= {Sprime_row[0], Sprime_row[1]};

			m2_state <= fill_CC3;
		end

		//read S'6 and store S'3
		fill_CC3: begin
			SRAM_address <= SRAM_address + 18'd1;
			Sprime_row[3] <= SRAM_read_data;

			m2_state <= fill_CC4;
		end

		//read S'7 and store S'4
		fill_CC4: begin
			SRAM_address <= SRAM_address + 18'd1;
			Sprime_row[4] <= SRAM_read_data;

			address0 <= address0 + 7'd1;
			data_in0 <= {Sprime_row[2], Sprime_row[3]};

			m2_state <= fill_CC5;
		end

		//store S'5 and write (S'0, S'1) to DP-RAM0
		fill_CC5: begin
			if (read_y) begin
				SRAM_address <= SRAM_address + 18'd313;
			end else begin
				SRAM_address <= SRAM_address + 18'd153;
			end
			Sprime_row[5] <= SRAM_read_data;

			m2_state <= fill_CC6;
		end

		//store S'6, write (S'2, S'3) to DP-RAM0, and read S'320
		fill_CC6: begin
			SRAM_address <= SRAM_address + 18'd1;
			Sprime_row[6] <= SRAM_read_data;

			address0 <= address0 + 7'd1;
			data_in0 <= {Sprime_row[4], Sprime_row[5]};
		
			m2_state <= fill_CC7;

		end

		fill_CC7: begin
			SRAM_address <= SRAM_address + 18'd1;
			Sprime_row[7] <= SRAM_read_data;

			address0 <= address0 + 7'd1;
			data_in0 <= {Sprime_row[6], SRAM_read_data};

			if (((address0 >= 7'd26) && (read_y)) || ((address0 >= 7'd10) && (read_u || read_v))) begin
				m2_state <= fill_lead_out0;
			end else begin
				m2_state <= fill_CC0;
			end

		end

		//read S'3 and store S'0
		fill_lead_out0: begin
			SRAM_address <= SRAM_address + 18'd1;
			Sprime_row[0] <= SRAM_read_data;
			
			write_en0 <= 1'b0;

			m2_state <= fill_lead_out1;
		end

		//read S'4 and store S'1
		fill_lead_out1: begin
			SRAM_address <= SRAM_address + 18'd1;
			Sprime_row[1] <= SRAM_read_data;

			m2_state <= fill_lead_out2;
		end

		//read S'5 and store S'2
		fill_lead_out2: begin
			SRAM_address <= SRAM_address + 18'd1;
			Sprime_row[2] <= SRAM_read_data;

			write_en0 <= 1'b1;
			address0 <= address0 + 7'd1;
			data_in0 <= {Sprime_row[0], Sprime_row[1]};

			m2_state <= fill_lead_out3;
		end

		//read S'6 and store S'3
		fill_lead_out3: begin
			SRAM_address <= SRAM_address + 18'd1;
			Sprime_row[3] <= SRAM_read_data;

			m2_state <= fill_lead_out4;
		end

		//read S'7 and store S'4
		fill_lead_out4: begin
			SRAM_address <= SRAM_address + 18'd1;
			Sprime_row[4] <= SRAM_read_data;

			address0 <= address0 + 7'd1;
			data_in0 <= {Sprime_row[2], Sprime_row[3]};

			m2_state <= fill_lead_out5; 
		end

		//store S'5 and write (S'0, S'1) to DP-RAM0
		fill_lead_out5: begin
			SRAM_address <= SRAM_address + 18'd1;
			Sprime_row[5] <= SRAM_read_data;
			
			m2_state <= fill_lead_out6;
		end

		//store S'6, write (S'2, S'3) to DP-RAM0, and read S'320
		fill_lead_out6: begin
			Sprime_row[6] <= SRAM_read_data;

			address0 <= address0 + 7'd1;
			data_in0 <= {Sprime_row[4], Sprime_row[5]};

			m2_state <= fill_lead_out7;

		end

		fill_lead_out7: begin
			Sprime_row[7] <= SRAM_read_data;
			
			address0 <= address0 + 7'd1;
			data_in0 <= {Sprime_row[6], SRAM_read_data};
	
			m2_state <= t_calc_lead_in0;
		end

		//read first location
		t_calc_lead_in0: begin

			increase_Saddress <= 3'd0;

			//for DP-RAM0 
			address0 <= 7'd0;
			write_en0 <= 1'd0;

			address1 <= 18'd32;
			write_en1 <= 1'd0;

			m2_state <= t_calc_lead_in1;

		end
		
		//read second location
		t_calc_lead_in1: begin

			//for DP-RAM0 
			address0 <= address0 + 7'd1;
			address1 <= address1 + 7'd1;
			
			m2_state <= t_calc_lead_in2;

		end

		//read (S'2,S'3) and calculate T(S'0,S'1)
		t_calc_lead_in2: begin
			
			//for DP-RAM0
			address0 <= address0 + 7'd1;
			address1 <= address1 + 7'd1;
			
			//begin calculation for S0*C0, begin calculation for S1*C8
			m1_op1 <= data_out0[31:16];
			if (data_out1[28]) begin
				m1_op2 <= 1'd0 - data_out1[27:16];
			end else begin
				m1_op2 <= data_out1[27:16];
			end
			
			m2_op1 <= data_out0[15:0];
			if (data_out1[12]) begin
				m2_op2 <= 1'd0 - data_out1[11:0];
			end else begin
				m2_op2 <= data_out1[11:0];
			end

			m2_state <= t_calc_lead_in3;

		end

		//read (S'4, S'5) and calculate T(S'2, S'3)
		t_calc_lead_in3: begin
			
			//for DP-RAM0
			address0 <= address0 + 7'd1;
			address1 <= address1 + 7'd1;

			increase_Saddress <= increase_Saddress + 3'd1;
			
			T_first <= m1_out + m2_out;

			//begin calculation for S2*C16
			m1_op1 <= data_out0[31:16];
			if (data_out1[28]) begin
				m1_op2 <= 1'd0 - data_out1[27:16];
			end else begin
				m1_op2 <= data_out1[27:16];
			end
			
			m2_op1 <= data_out0[15:0];
			if (data_out1[12]) begin
				m2_op2 <= 1'd0 - data_out1[11:0];
			end else begin
				m2_op2 <= data_out1[11:0];
			end

			m2_state <= t_calc_lead_in4;


		end
		
		//read (S'6, S'7) and calculate T(S'6, S'7)
		t_calc_lead_in4: begin
			
			//for DP-RAM0
			address0 <= address0 + 7'd1;
			address1 <= address1 - 7'd3;

			T_first <= T_first + m1_out + m2_out;
			
			//begin calculation for S4*C32
			m1_op1 <= data_out0[31:16];
			if (data_out1[28]) begin
				m1_op2 <= 1'd0 - data_out1[27:16];
			end else begin
				m1_op2 <= data_out1[27:16];
			end
			
			m2_op1 <= data_out0[15:0];
			if (data_out1[12]) begin
				m2_op2 <= 1'd0 - data_out1[11:0];
			end else begin
				m2_op2 <= data_out1[11:0];
			end

			m2_state <= t_calc_lead_in5;

		end

		t_calc_lead_in5: begin
			
			//for DP-RAM0
			address0 <= address0 + 7'd1;
			address1 <= address1 + 7'd1;

			T_first <= T_first + m1_out + m2_out;
			
			//begin calculation for S6*C48
			m1_op1 <= data_out0[31:16];
			if (data_out1[28]) begin
				m1_op2 <= 1'd0 - data_out1[27:16];
			end else begin
				m1_op2 <= data_out1[27:16];
			end
			
			m2_op1 <= data_out0[15:0];
			if (data_out1[12]) begin
				m2_op2 <= 1'd0 - data_out1[11:0];
			end else begin
				m2_op2 <= data_out1[11:0];
			end

			m2_state <= t_calc_lead_in6;

		end

		t_calc_lead_in6: begin
			
			//for DP-RAM0
			address0 <= address0 + 7'd1;
			address1 <= address1 + 7'd1;

			T_first <= T_first + m1_out + m2_out; //t even is done calculating

			//begin calculation for S0*C1
			m1_op1 <= data_out0[31:16];
			if (data_out1[28]) begin
				m1_op2 <= 1'd0 - data_out1[27:16];
			end else begin
				m1_op2 <= data_out1[27:16];
			end
			
			m2_op1 <= data_out0[15:0];
			if (data_out1[12]) begin
				m2_op2 <= 1'd0 - data_out1[11:0];
			end else begin
				m2_op2 <= data_out1[11:0];
			end

			m2_state <= t_calc_lead_in7;

		end

		t_calc_lead_in7: begin
			
			//for DP-RAM0
			address0 <= address0 + 7'd1;
			address1 <= address1 + 7'd1;

			increase_Saddress <= increase_Saddress + 3'd1;

			T_second <= m1_out + m2_out;

			//begin calculation for S4*C33
			m1_op1 <= data_out0[31:16];
			if (data_out1[28]) begin
				m1_op2 <= 1'd0 - data_out1[27:16];
			end else begin
				m1_op2 <= data_out1[27:16];
			end
			
			m2_op1 <= data_out0[15:0];
			if (data_out1[12]) begin
				m2_op2 <= 1'd0 - data_out1[11:0];
			end else begin
				m2_op2 <= data_out1[11:0];
			end

			m2_state <= t_calc_lead_in8;

		end

		t_calc_lead_in8: begin
			
			//for DP-RAM0
			address0 <= address0 - 7'd7;
			address1 <= address1 - 7'd3;

			T_second <= T_second + m1_out + m2_out; 

			//begin calculation for S2*C17
			m1_op1 <= data_out0[31:16];
			if (data_out1[28]) begin
				m1_op2 <= 1'd0 - data_out1[27:16];
			end else begin
				m1_op2 <= data_out1[27:16];
			end
			
			m2_op1 <= data_out0[15:0];
			if (data_out1[12]) begin
				m2_op2 <= 1'd0 - data_out1[11:0];
			end else begin
				m2_op2 <= data_out1[11:0];
			end
			
			m2_state <= t_calc_lead_in9;

		end

		t_calc_lead_in9: begin
			
			//for DP-RAM0
			address0 <= address0 + 7'd1;
			address1 <= address1 + 7'd1;

			T_second <= T_second + m1_out + m2_out;

			//begin calculation for S6*C49
			m1_op1 <= data_out0[31:16];
			if (data_out1[28]) begin
				m1_op2 <= 1'd0 - data_out1[27:16];
			end else begin
				m1_op2 <= data_out1[27:16];
			end
			
			m2_op1 <= data_out0[15:0];
			if (data_out1[12]) begin
				m2_op2 <= 1'd0 - data_out1[11:0];
			end else begin
				m2_op2 <= data_out1[11:0];
			end

			m2_state <= t_calc_lead_in10;

		end

		t_calc_lead_in10: begin
			
			//for DP-RAM0
			address0 <= address0 + 7'd1;
			address1 <= address1 + 7'd1;

			T_second <= T_second + m1_out + m2_out;

			//for DP-RAM1
			address2 <= 7'd0;
			write_en2 <= 1'd1;
			data_in2 <= {bit_T_first, bit_T_second}; //finish calculating T1 and write (T0,T1) to DP-RAM1

			//begin calculation for S0*C2
			m1_op1 <= data_out0[31:16];
			if (data_out1[28]) begin
				m1_op2 <= 1'd0 - data_out1[27:16];
			end else begin
				m1_op2 <= data_out1[27:16];
			end
			
			m2_op1 <= data_out0[15:0];
			if (data_out1[12]) begin
				m2_op2 <= 1'd0 - data_out1[11:0];
			end else begin
				m2_op2 <= data_out1[11:0];
			end

			m2_state <= t_calc_CC_0;

		end
		
		//read (S'2, S'3) and calculate T(S'0, S'1)
		t_calc_CC_0: begin
			
			//for DP-RAM0
			address0 <= address0 + 7'd1;
			address1 <= address1 + 7'd1;

			increase_Saddress <= increase_Saddress + 3'd1; //used to increase address by 4
			write_en2 <= 1'd0;

			T_first <= m1_out + m2_out;

			//begin calculation for S2*C18
			m1_op1 <= data_out0[31:16];
			if (data_out1[28]) begin
				m1_op2 <= 1'd0 - data_out1[27:16];
			end else begin
				m1_op2 <= data_out1[27:16];
			end
			
			m2_op1 <= data_out0[15:0];
			if (data_out1[12]) begin
				m2_op2 <= 1'd0 - data_out1[11:0];
			end else begin
				m2_op2 <= data_out1[11:0];
			end

			m2_state <= t_calc_CC_1;

		end

		//read (S'4, S'5) and calculate T(S'2, S'3)
		t_calc_CC_1: begin
			
			address0 <= address0 + 7'd1;
			address1 <= address1 - 7'd3;

			T_first <= T_first + m1_out + m2_out;

			//begin calculation for S4*C34
			m1_op1 <= data_out0[31:16];
			if (data_out1[28]) begin
				m1_op2 <= 1'd0 - data_out1[27:16];
			end else begin
				m1_op2 <= data_out1[27:16];
			end
			
			m2_op1 <= data_out0[15:0];
			if (data_out1[12]) begin
				m2_op2 <= 1'd0 - data_out1[11:0];
			end else begin
				m2_op2 <= data_out1[11:0];
			end

			m2_state <= t_calc_CC_2;

		end
		
		t_calc_CC_2: begin
			
			//for DP-RAM0
			address0 <= address0 + 7'd1;
			address1 <= address1 + 7'd1;

			T_first <= T_first + m1_out + m2_out;

			//begin calculation for S6*C50
			m1_op1 <= data_out0[31:16];
			if (data_out1[28]) begin
				m1_op2 <= 1'd0 - data_out1[27:16];
			end else begin
				m1_op2 <= data_out1[27:16];
			end
			
			m2_op1 <= data_out0[15:0];
			if (data_out1[12]) begin
				m2_op2 <= 1'd0 - data_out1[11:0];
			end else begin
				m2_op2 <= data_out1[11:0];
			end

			m2_state <= t_calc_CC_3;

		end
		
		t_calc_CC_3: begin
			
			//for DP-RAM0
			address0 <= address0 + 7'd1;
			address1 <= address1 + 7'd1;

			T_first <= T_first + m1_out + m2_out; //T_first has been fully calculated

			//begin calculation for S0*C3
			m1_op1 <= data_out0[31:16];
			if (data_out1[28]) begin
				m1_op2 <= 1'd0 - data_out1[27:16];
			end else begin
				m1_op2 <= data_out1[27:16];
			end
			
			m2_op1 <= data_out0[15:0];
			if (data_out1[12]) begin
				m2_op2 <= 1'd0 - data_out1[11:0];
			end else begin
				m2_op2 <= data_out1[11:0];
			end

			m2_state <= t_calc_CC_4;

		end

		t_calc_CC_4: begin

			//for DP-RAM0
			address0 <= address0 + 7'd1;
			address1 <= address1 + 7'd1;
			
			increase_Saddress <= increase_Saddress + 3'd1;

			T_second <= m1_out + m2_out; //begin calculating T_second

			//begin calculation for S2*C19
			m1_op1 <= data_out0[31:16];
			if (data_out1[28]) begin
				m1_op2 <= 1'd0 - data_out1[27:16];
			end else begin
				m1_op2 <= data_out1[27:16];
			end
			
			m2_op1 <= data_out0[15:0];
			if (data_out1[12]) begin
				m2_op2 <= 1'd0 - data_out1[11:0];
			end else begin
				m2_op2 <= data_out1[11:0];
			end

			m2_state <= t_calc_CC_5;

		end

		t_calc_CC_5: begin
			
			if (increase_Saddress == 3'd0) begin
				//for DP-RAM0
				address0 <= (address0 == 7'd31 && address2 < 7'd31) ? 7'd0 : address0 + 7'd1;
				address1 <= address1 + 7'd1;
				
			end else begin
				//for DP-RAM0
				address0 <= address0 - 7'd7;
				address1 <= address1 - 7'd3;

			end

			T_second <= T_second + m1_out + m2_out;

			//begin calculation for S4*C35
			m1_op1 <= data_out0[31:16];
			if (data_out1[28]) begin
				m1_op2 <= 1'd0 - data_out1[27:16];
			end else begin
				m1_op2 <= data_out1[27:16];
			end
			
			m2_op1 <= data_out0[15:0];
			if (data_out1[12]) begin
				m2_op2 <= 1'd0 - data_out1[11:0];
			end else begin
				m2_op2 <= data_out1[11:0];
			end

			m2_state <= t_calc_CC_6;
			
		end

		t_calc_CC_6: begin
			
			//for DP-RAM0
			address0 <= address0 + 7'd1;
			address1 <= address1 + 7'd1;

			T_second <= T_second + m1_out + m2_out;

			//begin calculation for S6*C51
			m1_op1 <= data_out0[31:16];
			if (data_out1[28]) begin
				m1_op2 <= 1'd0 - data_out1[27:16];
			end else begin
				m1_op2 <= data_out1[27:16];
			end
			
			m2_op1 <= data_out0[15:0];
			if (data_out1[12]) begin
				m2_op2 <= 1'd0 - data_out1[11:0];
			end else begin
				m2_op2 <= data_out1[11:0];
			end

			m2_state <= t_calc_CC_7;

		end
		
		
		t_calc_CC_7: begin
			
			//for DP-RAM0
			address0 <= address0 + 7'd1;
			address1 <= address1 + 7'd1;

			T_second <= T_second + m1_out + m2_out;

			//for DP-RAM1
			address2 <= address2 + 7'd1;
			write_en2 <= 1'd1;
			data_in2 <= {bit_T_first, bit_T_second}; //finish calculating T_second and write (T_first,T_second) to DP-RAM1

			//begin calculation for S0*C4
			m1_op1 <= data_out0[31:16];
			if (data_out1[28]) begin
				m1_op2 <= 1'd0 - data_out1[27:16];
			end else begin
				m1_op2 <= data_out1[27:16];
			end
			
			m2_op1 <= data_out0[15:0];
			if (data_out1[12]) begin
				m2_op2 <= 1'd0 - data_out1[11:0];
			end else begin
				m2_op2 <= data_out1[11:0];
			end

			if ((read_y && (address2 == 7'd31)) || ((read_u || read_v) && (address2 == 7'd15))) begin
				m2_state <= S_calc_lead_in0;
			end else begin
				m2_state <= t_calc_CC_0;
			end

		end
		
		//read first location
		S_calc_lead_in0: begin

			increase_Taddress <= 3'd0;
			
			//for DP-RAM1
			address2 <= 7'd0;
			write_en2 <= 1'd0;
			address3 <= 7'd32;
			write_en3 <= 1'd0;

			S_first <= 16'd0;

			m2_state <= S_calc_lead_in1;

		end	

		//read (T2, S'3) and calculate (T0,T1) 
		S_calc_lead_in1: begin
			
			//for DP-RAM1
			address2 <= address2 + 7'd1;
			address3 <= address3 + 7'd1;

			m2_state <= S_calc_lead_in2;

		end	

		S_calc_lead_in2: begin
			
			//for DP-RAM1
			address2 <= address2 + 7'd1;
			address3 <= address3 + 7'd1;

			//begin calculation for S
			m1_op1 <= data_out2[31:16];
			if (data_out3[28]) begin
				m1_op2 <= 1'd0 - data_out3[27:16];
			end else begin
				m1_op2 <= data_out3[27:16];
			end
			
			m2_op1 <= data_out2[15:0];
			if (data_out3[12]) begin
				m2_op2 <= 1'd0 - data_out3[11:0];
			end else begin
				m2_op2 <= data_out3[11:0];
			end

			m2_state <= S_calc_lead_in3;

		end	

		S_calc_lead_in3: begin

			increase_Taddress <= increase_Taddress + 3'd1;
			
			//for DP-RAM1
			address2 <= address2 + 7'd1;
			address3 <= address3 + 7'd1;

			S_first <= m1_out + m2_out;

			//begin calculation for S
			m1_op1 <= data_out2[31:16];
			if (data_out3[28]) begin
				m1_op2 <= 1'd0 - data_out3[27:16];
			end else begin
				m1_op2 <= data_out3[27:16];
			end
			
			m2_op1 <= data_out2[15:0];
			if (data_out3[12]) begin
				m2_op2 <= 1'd0 - data_out3[11:0];
			end else begin
				m2_op2 <= data_out3[11:0];
			end

			m2_state <= S_calc_lead_in4;

		end	

		S_calc_lead_in4: begin

			address2 <= address2 + 7'd1;
			address3 <= address3 - 7'd3;
			

			S_first <= S_first + m1_out + m2_out;

			//begin calculation for S
			m1_op1 <= data_out2[31:16];
			if (data_out3[28]) begin
				m1_op2 <= 1'd0 - data_out3[27:16];
			end else begin
				m1_op2 <= data_out3[27:16];
			end
			
			m2_op1 <= data_out2[15:0];
			if (data_out3[12]) begin
				m2_op2 <= 1'd0 - data_out3[11:0];
			end else begin
				m2_op2 <= data_out3[11:0];
			end

			m2_state <= S_calc_lead_in5;

		end	

		S_calc_lead_in5: begin
			
			//for DP-RAM1
			address2 <= address2 + 7'd1;
			address3 <= address3 + 7'd1;

			S_first <= S_first + m1_out + m2_out;
			
			//begin calculation for S
			m1_op1 <= data_out2[31:16];
			if (data_out3[28]) begin
				m1_op2 <= 1'd0 - data_out3[27:16];
			end else begin
				m1_op2 <= data_out3[27:16];
			end
			
			m2_op1 <= data_out2[15:0];
			if (data_out3[12]) begin
				m2_op2 <= 1'd0 - data_out3[11:0];
			end else begin
				m2_op2 <= data_out3[11:0];
			end

			m2_state <= S_calc_lead_in6;

		end	

		S_calc_lead_in6: begin
			
			//for DP-RAM1
			address2 <= address2 + 7'd1;
			address3 <= address3 + 7'd1;

			S_first <= S_first + m1_out + m2_out;
			
			//begin calculation for S
			m1_op1 <= data_out2[31:16];
			if (data_out3[28]) begin
				m1_op2 <= 1'd0 - data_out3[27:16];
			end else begin
				m1_op2 <= data_out3[27:16];
			end
			
			m2_op1 <= data_out2[15:0];
			if (data_out3[12]) begin
				m2_op2 <= 1'd0 - data_out3[11:0];
			end else begin
				m2_op2 <= data_out3[11:0];
			end

			m2_state <= S_calc_lead_in7;

		end	

		S_calc_lead_in7: begin

			increase_Taddress <= increase_Taddress + 3'd1;
			
			//for DP-RAM1
			address2 <= address2 + 7'd1;
			address3 <= address3 + 7'd1;

			S_second <= m1_out + m2_out;
			
			//begin calculation for S
			m1_op1 <= data_out2[31:16];
			if (data_out3[28]) begin
				m1_op2 <= 1'd0 - data_out3[27:16];
			end else begin
				m1_op2 <= data_out3[27:16];
			end
			
			m2_op1 <= data_out2[15:0];
			if (data_out3[12]) begin
				m2_op2 <= 1'd0 - data_out3[11:0];
			end else begin
				m2_op2 <= data_out3[11:0];
			end

			m2_state <= S_calc_lead_in8;

		end	

		S_calc_lead_in8: begin

			address2 <= address2 + 7'd1;
			address3 <= address3 - 7'd3;

			S_second <= S_second + m1_out + m2_out;
			
			//begin calculation for S
			m1_op1 <= data_out2[31:16];
			if (data_out3[28]) begin
				m1_op2 <= 1'd0 - data_out3[27:16];
			end else begin
				m1_op2 <= data_out3[27:16];
			end
			
			m2_op1 <= data_out2[15:0];
			if (data_out3[12]) begin
				m2_op2 <= 1'd0 - data_out3[11:0];
			end else begin
				m2_op2 <= data_out3[11:0];
			end

			m2_state <= S_calc_lead_in9;

		end	

		S_calc_lead_in9: begin
			
			//for DP-RAM1
			address2 <= address2 + 7'd1;
			address3 <= address3 + 7'd1;

			S_second <= S_second + m1_out + m2_out;
			
			//begin calculation for S
			m1_op1 <= data_out2[31:16];
			if (data_out3[28]) begin
				m1_op2 <= 1'd0 - data_out3[27:16];
			end else begin
				m1_op2 <= data_out3[27:16];
			end
			
			m2_op1 <= data_out2[15:0];
			if (data_out3[12]) begin
				m2_op2 <= 1'd0 - data_out3[11:0];
			end else begin
				m2_op2 <= data_out3[11:0];
			end

			m2_state <= S_calc_lead_in10;

		end	


		S_calc_lead_in10: begin
			
			//for DP-RAM1
			address2 <= address2 + 7'd1;
			address3 <= address3 + 7'd1;

			S_second <= S_second + m1_out + m2_out;

			//write the even and odd S values to SRAM
			if (read_y) begin
				SRAM_address <= column_counter + row_counter;
			end else if (read_u) begin
				SRAM_address <= 18'd38400 + column_counter + row_counter;
			end else if (read_v) begin
				SRAM_address <= 18'd57600 + column_counter + row_counter;
			end

			write_en_n <= 1'd0;
			SRAM_write_data <= {clipped_S_first, clipped_S_second};
			
			//begin calculation for S in common case
			m1_op1 <= data_out2[31:16];
			if (data_out3[28]) begin
				m1_op2 <= 1'd0 - data_out3[27:16];
			end else begin
				m1_op2 <= data_out3[27:16];
			end
			
			m2_op1 <= data_out2[15:0];
			if (data_out3[12]) begin
				m2_op2 <= 1'd0 - data_out3[11:0];
			end else begin
				m2_op2 <= data_out3[11:0];
			end

			m2_state <= S_calc_CC0;

		end	

		S_calc_CC0: begin

			increase_Taddress <= increase_Taddress + 3'd1;

			write_en_n <= 1'd1;

			//for DP-RAM1
			address2 <= address2 + 7'd1;
			write_en2 <= 1'd0;
			address3 <= address3 + 7'd1;
			write_en3 <= 1'd0;

			S_first <= m1_out + m2_out;

			//begin calculation for S
			m1_op1 <= data_out2[31:16];
			if (data_out3[28]) begin
				m1_op2 <= 1'd0 - data_out3[27:16];
			end else begin
				m1_op2 <= data_out3[27:16];
			end
			
			m2_op1 <= data_out2[15:0];
			if (data_out3[12]) begin
				m2_op2 <= 1'd0 - data_out3[11:0];
			end else begin
				m2_op2 <= data_out3[11:0];
			end

			m2_state <= S_calc_CC1;

		end	

		S_calc_CC1: begin

			address2 <= address2 + 7'd1;
			address3 <= address3 - 7'd3;

			S_first <= S_first + m1_out + m2_out;

			//begin calculation for S
			m1_op1 <= data_out2[31:16];
			if (data_out3[28]) begin
				m1_op2 <= 1'd0 - data_out3[27:16];
			end else begin
				m1_op2 <= data_out3[27:16];
			end
			
			m2_op1 <= data_out2[15:0];
			if (data_out3[12]) begin
				m2_op2 <= 1'd0 - data_out3[11:0];
			end else begin
				m2_op2 <= data_out3[11:0];
			end

			m2_state <= S_calc_CC2;

		end	

		S_calc_CC2: begin

			//for DP-RAM1
			address2 <= address2 + 7'd1;
			address3 <= address3 + 7'd1;

			S_first <= S_first + m1_out + m2_out;

			//begin calculation for S
			m1_op1 <= data_out2[31:16];
			if (data_out3[28]) begin
				m1_op2 <= 1'd0 - data_out3[27:16];
			end else begin
				m1_op2 <= data_out3[27:16];
			end
			
			m2_op1 <= data_out2[15:0];
			if (data_out3[12]) begin
				m2_op2 <= 1'd0 - data_out3[11:0];
			end else begin
				m2_op2 <= data_out3[11:0];
			end

			m2_state <= S_calc_CC3;

		end	

		S_calc_CC3: begin

			//for DP-RAM1
			address2 <= address2 + 7'd1;
			address3 <= address3 + 7'd1;

			S_first <= S_first + m1_out + m2_out;

			//begin calculation for S
			m1_op1 <= data_out2[31:16];
			if (data_out3[28]) begin
				m1_op2 <= 1'd0 - data_out3[27:16];
			end else begin
				m1_op2 <= data_out3[27:16];
			end
			
			m2_op1 <= data_out2[15:0];
			if (data_out3[12]) begin
				m2_op2 <= 1'd0 - data_out3[11:0];
			end else begin
				m2_op2 <= data_out3[11:0];
			end

			m2_state <= S_calc_CC4;

		end	

		S_calc_CC4: begin

			increase_Taddress <= increase_Taddress + 3'd1;

			//for DP-RAM1
			address2 <= address2 + 7'd1;
			address3 <= address3 + 7'd1;

			S_second <= m1_out + m2_out;

			//begin calculation for S
			m1_op1 <= data_out2[31:16];
			if (data_out3[28]) begin
				m1_op2 <= 1'd0 - data_out3[27:16];
			end else begin
				m1_op2 <= data_out3[27:16];
			end
			
			m2_op1 <= data_out2[15:0];
			if (data_out3[12]) begin
				m2_op2 <= 1'd0 - data_out3[11:0];
			end else begin
				m2_op2 <= data_out3[11:0];
			end

			m2_state <= S_calc_CC5;

		end	

		S_calc_CC5: begin

			if (increase_Taddress == 3'd0) begin
				//for DP-RAM1
				address2 <= address2 + 7'd1;
				address3 <= address3 + 7'd1;
				
			end else begin
				//for DP-RAM1
				address2 <= address2 + 7'd1;
				address3 <= address3 - 7'd3;

			end

			S_second <= S_second + m1_out + m2_out;

			//begin calculation for S
			m1_op1 <= data_out2[31:16];
			if (data_out3[28]) begin
				m1_op2 <= 1'd0 - data_out3[27:16];
			end else begin
				m1_op2 <= data_out3[27:16];
			end
			
			m2_op1 <= data_out2[15:0];
			if (data_out3[12]) begin
				m2_op2 <= 1'd0 - data_out3[11:0];
			end else begin
				m2_op2 <= data_out3[11:0];
			end

			m2_state <= S_calc_CC6;

		end	

		S_calc_CC6: begin

			//for DP-RAM1
			address2 <= address2 + 7'd1;
			address3 <= address3 + 7'd1;

			S_second <= S_second + m1_out + m2_out;

			//begin calculation for S
			m1_op1 <= data_out2[31:16];
			if (data_out3[28]) begin
				m1_op2 <= 1'd0 - data_out3[27:16];
			end else begin
				m1_op2 <= data_out3[27:16];
			end
			
			m2_op1 <= data_out2[15:0];
			if (data_out3[12]) begin
				m2_op2 <= 1'd0 - data_out3[11:0];
			end else begin
				m2_op2 <= data_out3[11:0];
			end

			m2_state <= S_calc_CC7;

		end	

		S_calc_CC7: begin

			//for DP-RAM1
			address2 <= address2 + 7'd1;
			address3 <= address3 + 7'd1;

			//write the even and odd S values to SRAM
			SRAM_address <= SRAM_address + 18'd1;
			write_en_n <= 1'd0;
			SRAM_write_data <= {clipped_S_first, clipped_S_second};

			//begin calculation for S
			m1_op1 <= data_out2[31:16];
			if (data_out3[28]) begin
				m1_op2 <= 1'd0 - data_out3[27:16];
			end else begin
				m1_op2 <= data_out3[27:16];
			end
			
			m2_op1 <= data_out2[15:0];
			if (data_out3[12]) begin
				m2_op2 <= 1'd0 - data_out3[11:0];
			end else begin
				m2_op2 <= data_out3[11:0];
			end

			if ((read_y && (address3 > 7'd63)) || ((read_u || read_v) && (address3 > 7'd31))) begin

				block_col <= block_col + 6'd1;

				//check which Y/U/V block we are reading, and either incriment to the next row/column or change to the next Y/U/V block
				if (read_y) begin
					if (block_col > 6'd39) begin
						block_col <= 6'd0;
						block_row <= block_row + 5'd1;
					end
					
					if (block_row > 5'd29) begin
						block_row <= 5'd0;
						read_u <= 1'd1;
						read_y <= 1'd0;
						read_v <= 1'd0;
					end

				end else if (read_u) begin
					if (block_col > 6'd19) begin
						block_col <= 6'd0;
						block_row <= block_row + 5'd1;
					end
					
					if (block_row > 5'd29) begin
						block_row <= 5'd0;
						read_u <= 1'd0;
						read_y <= 1'd0;
						read_v <= 1'd1;
					end

				end else begin
					if (block_col > 6'd19) begin
						block_col <= 6'd0;
						block_row <= block_row + 5'd1;
					end
					
					if (block_row > 5'd29) begin
						m2_state <= m2_final_state;

					end
				end
				m2_state <= fill_lead_in0;

			end else begin
				m2_state <= S_calc_CC0;

			end

		end	

		m2_final_state: begin
				write_en_n <= 1'b1;
				m2_finish <= 1'b1;
				m2_state <= m2_idle;
		end

		default: m2_state <= m2_idle;
		endcase

	end
end


endmodule