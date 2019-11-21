`ifndef DISABLE_DEFAULT_NET
`timescale 1ns/100ps
`default_nettype none
`endif
`include "define_state.h"

//mulitplier module which we will instantiate 3 times 
module Multiplier (
	input int Mult_op_1, Mult_op_2,
	output int Mult_result
);

	logic [63:0] Mult_result_long;
	assign Mult_result_long = Mult_op_1 * Mult_op_2;
	assign Mult_result = Mult_result_long[31:0];

endmodule

//these mulitpliers are always running
//do not assign these values in your always ff

module milestone1(
	input logic CLOCK_50_I,
	input logic Resetn,
	input logic start_bit, //for leaving idle state
	input logic [15:0] SRAM_read_data,
	output logic [15:0] write_data,
	output logic [17:0] address,
	output logic write_en_n,
	output logic milestone1_finish
);

milestone_state_type milestone1; //initailize from header file

logic [8:0] counter;
logic [7:0] counter_vert;

//initalize registers for U,V,Y and RGB 
logic [7:0] reg_u [5:0]; //shift register for u values
logic [7:0] reg_v [5:0]; //shift register for v values 
logic [7:0] reg_y [1:0]; //shift register for y values 

logic read_cycle_en; //to keep track of whether we need to incriment address for Y/U/V or not
logic [7:0] value_R;
logic [7:0] value_G;
logic [7:0] value_B;
logic [7:0] clipped_value_R;
logic [7:0] clipped_value_G;
logic [7:0] clipped_value_B;

logic [31:0] matrix_value_y;
logic [31:0] matrix_value_u;
logic [31:0] matrix_value_v;

//address counters for Y, U, and V
logic [17:0] address_y;
logic [17:0] address_u;
logic [17:0] address_v;
logic [17:0] address_RGB;

logic [31:0] value_u_prime;
logic [31:0] value_v_prime;

//intialize input and output (we use them as outputs, theyre not actually "outputs") logic for multipliers 
logic [31:0] Mult_op_1, Mult_op_2, Mult_result;
logic [63:0] Mult_result_long;

logic [31:0] mult1_op1;
logic [31:0] mult1_op2;
logic [31:0] mult2_op1;
logic [31:0] mult2_op2;
logic [31:0] mult3_op1;
logic [31:0] mult3_op2;

logic signed [31:0] mult1_out;
logic signed [31:0] mult2_out;
logic signed [31:0] mult3_out;

//constant ints for 32 bit signed arithmetic
logic signed [31:0] signed_21;
logic signed [31:0] signed_neg_52;
logic signed [31:0] signed_159;
logic signed [31:0] signed_128;
logic signed [31:0] signed_76284;
logic signed [31:0] signed_16;
logic signed [31:0] signed_neg_25624;
logic signed [31:0] signed_104595;
logic signed [31:0] signed_neg_53281;
logic signed [31:0] signed_132251;


Multiplier mult1(
	.Mult_op_1(mult1_op1),
	.Mult_op_2(mult1_op2),
	.Mult_result(mult1_out)
);

Multiplier mult2(
	.Mult_op_1(mult2_op1),
	.Mult_op_2(mult2_op2),
	.Mult_result(mult2_out)
);

Multiplier mult3(
	.Mult_op_1(mult3_op1),
	.Mult_op_2(mult3_op2),
	.Mult_result(mult3_out)
);

assign clipped_value_R = ((mult1_out + mult2_out) >>> 16);
assign clipped_value_G = ((matrix_value_y + mult1_out + mult2_out) >>> 16);
assign clipped_value_B = ((matrix_value_y + mult3_out) >>> 16);

always @(posedge CLOCK_50_I or negedge Resetn) begin
	if (~Resetn) begin
	//initailize all variables and registers as base values
		value_R <= 8'd0;
		value_G <= 8'd0;
		value_B <= 8'd0;
		matrix_value_y <= 8'd0;
		matrix_value_u <= 8'd0;
		matrix_value_v <= 8'd0;
		value_u_prime <= 32'd0;
		value_v_prime <= 32'd0;
		read_cycle_en <= 1'd0;

		address_y <= 18'd0;
		address_u <= 18'd38400;
		address_v <= 18'd57600;
		address_RGB <= 18'd146944;

		reg_y[0] <= 8'd0;
		reg_y[1] <= 8'd0;

		reg_u[0] <= 8'd0;
		reg_u[1] <= 8'd0;
		reg_u[2] <= 8'd0;
		reg_u[3] <= 8'd0;
		reg_u[4] <= 8'd0;
		reg_u[5] <= 8'd0;

		reg_v[0] <= 8'd0;
		reg_v[1] <= 8'd0;
		reg_v[2] <= 8'd0;
		reg_v[3] <= 8'd0;
		reg_v[4] <= 8'd0;
		reg_v[5] <= 8'd0;
		
		//assign the constants for multiplying 
		signed_21 <= 32'd21;
		signed_neg_52 <= -32'd52;
		signed_159 <= 32'd159;
		signed_128 <= 32'd128;
		signed_76284 <= 32'd76284;
		signed_16 <= 32'd16;
		signed_neg_25624 <= -32'd25624;
		signed_104595 <= 32'd104595;
		signed_neg_53281 <= -32'd53281;
		signed_132251 <= 32'd132251;

		counter <= 9'd0;
		counter_vert <= 8'd0;
		milestone1 <= idle;
		
	end else begin
		
		case(milestone1)
			
			idle: begin
			 if(start_bit)begin
			 	write_en_n <= 1'b1;
			   	milestone1 <= lead_in_0;
			 end
			end
			
			lead_in_0: begin
			  
				write_en_n <= 1'b1;
				address <= address_v;
				address_v <= address_v + 18'd1; 
					
				milestone1 <= lead_in_1;

			end
			
			lead_in_1: begin

				address <= address_v;
				
				address_v <= address_v + 18'd1;

				milestone1 <= lead_in_2;
				
			end
			
			lead_in_2: begin

				address <= address_u;
				address_u <= address_u + 18'd1; 
				
				milestone1 <= lead_in_3;
			
			end
			
			lead_in_3: begin

				address <= address_u;
				
				reg_v[0] <= SRAM_read_data[15:8];
				reg_v[1] <= SRAM_read_data[15:8];
				reg_v[2] <= SRAM_read_data[15:8];
				reg_v[3] <=	SRAM_read_data[7:0];
				
				address_u <= address_u + 18'd1; 
				
				milestone1 <= lead_in_4;
			
			end
			
			lead_in_4: begin

				address <= address_y;
				address_y <= address_y + 18'd1;
				
				reg_v[4] <= SRAM_read_data[15:8];
				reg_v[5] <= SRAM_read_data[7:0];
				
				milestone1 <= lead_in_5;
				
			end
			
			lead_in_5: begin
				
				mult1_op1 <= signed_21;
				mult1_op2 <= (reg_v[0] + reg_v[5]); //the u values we require will always be at the start and end of our register
				
				mult2_op1 <= signed_neg_52;
				mult2_op2 <= (reg_v[1] + reg_v[4]);
				
				mult3_op1 <= signed_159;
				mult3_op2 <= (reg_v[2] + reg_v[3]);
			
				reg_u[0] <= SRAM_read_data[15:8];
				reg_u[1] <= SRAM_read_data[15:8];
				reg_u[2] <= SRAM_read_data[15:8];
				reg_u[3] <=	SRAM_read_data[7:0];
				
				milestone1 <= lead_in_6;
				
			end
			
			lead_in_6: begin
			  
			  //finish computation for V'
				value_v_prime <= (mult1_out + mult2_out + mult3_out + signed_128) >>> 8;  
			  
				reg_u[4] <= SRAM_read_data[15:8];
				reg_u[5] <= SRAM_read_data[7:0];
				
				milestone1 <= lead_in_7;
			
			end
			
			lead_in_7: begin
				
				reg_y[1] = SRAM_read_data[15:8];
				reg_y[0] = SRAM_read_data[7:0];
			
				mult1_op1 <= signed_21;
				mult1_op2 <=(reg_u[0] + reg_u[5]); //the u values we require will always be at the start and end of our register
				
				mult2_op1 <= signed_neg_52; 
				mult2_op2 <= (reg_u[1] + reg_u[4]);
				
				mult3_op1 <= signed_159;
				mult3_op2 <= (reg_u[2] + reg_u[3]);
				
				milestone1 <= common_case_0;
				
			end
			
			common_case_0: begin
        
       			 //finish computation for U'
				value_u_prime <= (mult1_out + mult2_out + mult3_out + signed_128) >>> 8; 
				
				//enable reading -> read (Veven, Vodd) values -> stores values in reg_v register
				write_en_n <= 1'b1;	
				address <= address_v;
				
				if (read_cycle_en && counter <  9'd310) begin
					address_v <= address_v + 18'd1;
				end


				//Y matrix calculation for R value
				//the output of this multiplication will be available in the next cycle
				mult1_op1 <= signed_76284;
				mult1_op2 <= (reg_y[1] - signed_16);
			
				//V matrix calculation for R value
				//the output of this multiplication will be available in the next cycle
				mult2_op1 <= signed_104595;
				mult2_op2 <= (reg_v[2] - signed_128);

				milestone1 <= common_case_1;
				
			end

			//calculate GB, read (Ueven, Uodd) every other cycle from SRAM and incriment U values SRAM_address 
			common_case_1: begin 
				
				write_en_n <= 1'b1;
				address <= address_u;
				
				if (read_cycle_en && counter <  9'd310) begin
					address_u <= address_u + 18'd1;
					
				end
				
				//use mutlipler output from previous cycle to finalize R value
				matrix_value_y <= mult1_out;
				matrix_value_v <= mult2_out;
				value_R <= (mult1_out + mult2_out) >>> 16; //shifting 16 bits to the right is equivalent to dividing by 2^16
			
				//U matrix calculation for G value
				mult1_op1 <= signed_neg_25624;
				mult1_op2 <= (reg_u[2] - signed_128);

				//V matrix calculation for G value
				mult2_op1 <= signed_neg_53281;
				mult2_op2 <= (reg_v[2] - signed_128);

				//U matrix calculation for B value
				mult3_op1 <= signed_132251;
				mult3_op2 <= (reg_u[2] - signed_128);

				milestone1 <= common_case_2;

			end

			common_case_2: begin
				
				//use mutliplier output from previous cycle to finalize G value
				matrix_value_u <= mult1_out;
				matrix_value_v <= mult2_out;
				value_G <= (matrix_value_y + mult1_out + mult2_out) >>> 16;

				//use mutliplier output from previous cycle to finalize B value
				matrix_value_u <= mult3_out;
				value_B <= (matrix_value_y + mult3_out) >>> 16;

				//write R and G values to SRAM
				write_en_n <= 1'b0;
				address <= address_RGB;

				//if ANY value needs to be clipped, enter this conditional statement
				if ((clipped_value_R < 8'd0) || (clipped_value_G < 8'd0) || ((clipped_value_R > 8'd255) || (clipped_value_G > 8'd255))) begin

					//if both values are above 255
					if ((value_R > 8'd255) && (clipped_value_G > 8'd255)) begin
						write_data <= {8'd255, 8'd255};
					//if both values are below 0
					end else if ((value_R < 8'd0) && (clipped_value_G < 8'd0)) begin
						write_data <= {8'd0, 8'd0};
					//if R is above 255 AND G is below 0 
					end else if ((value_R > 8'd255) && (clipped_value_G < 8'd0)) begin
						write_data <= {8'd255, 8'd0};
					//if R is below 0 AND G is above 255
					end else if ((value_R < 8'd0) && (clipped_value_G > 8'd255)) begin
						write_data <= {8'd0, 8'd255};
					//if R values is below 0
					end else if (value_R < 8'd0) begin
						write_data <= {8'd0, clipped_value_G};
					//if R value is above 255
					end else if (value_R > 8'd255) begin
						write_data <= {8'd255, clipped_value_G};
					//if G value is below 0
					end else if (clipped_value_G < 8'd0) begin
						write_data <= {value_R, 8'd0};
					//if G value is above 255
					end else if (clipped_value_G> 8'd255) begin
						write_data <= {value_R, 8'd255};
						
				 	 //if no  values need to be clipped
			   		end else begin
		
					   write_data <= {value_R, clipped_value_G};
          
     			  	end
				end

				//write_data <= {{value_R}[7:0], {((matrix_value_y + mult1_out + mult2_out) >>> 16)}[7:0]};

				address_RGB <= address_RGB + 18'd1;

				//compute V' for odd RGB value	
				mult1_op1 <= signed_21;
				mult1_op2 <= (reg_v[0] + reg_v[5]); //the u values we require will always be at the start and end of our register
				
				mult2_op1 <= signed_neg_52;
				mult2_op2 <= (reg_v[1] + reg_v[4]);
				
				mult3_op1 <= signed_159;
				mult3_op2 <= (reg_v[2] + reg_v[3]);
				
				milestone1 <= common_case_3;
				
			end
			
			common_case_3: begin
			  
        		write_en_n <= 1'b1;
				//finalize V' values and start computing U' for odd RGB values	

				//finialize V' computation using mutliplier outputs from previous cycle
				value_v_prime <= (mult1_out + mult2_out + mult3_out + signed_128) >>> 8; 

				//fill multipliers with new values to compute odd U'
				mult1_op1 <= signed_21;
				mult1_op2 <=(reg_u[0] + reg_u[5]); //the u values we require will always be at the start and end of our register
				
				mult2_op1 <= signed_neg_52; 
				mult2_op2 <= (reg_u[1] + reg_u[4]);
				
				mult3_op1 <= signed_159;
				mult3_op2 <= (reg_u[2] + reg_u[3]);
					

				//we need to ensure we shift these values to the correct index for our V' calculation
				//index 0 == V(j-5/2) required data
				//index 1 == V(j-3/2)
				//index 2 == V(j-1/2)
				//index 3 == V(j+1/2)
				//index 4 == V(j+3/2)
				//index 5 == V(j+5/2)
				//need to create a buffer register and shift only 1 out of 2 of the SRAM values into this register per cycle
				
				if (counter <= 9'd310) begin
				
					if(read_cycle_en) begin
						reg_v[0] <= reg_v[1];
						reg_v[1] <= reg_v[2];
						reg_v[2] <= reg_v[3];
						reg_v[3] <= reg_v[4];
						reg_v[4] <= reg_v[5];
						reg_v[5] <= SRAM_read_data[7:0];

					end else begin
						reg_v[0] <= reg_v[1];
						reg_v[1] <= reg_v[2];
						reg_v[2] <= reg_v[3];
						reg_v[3] <= reg_v[4];
						reg_v[4] <= reg_v[5];
						reg_v[5] <= SRAM_read_data[15:8];
					end
					
				end else begin
					reg_v[0] <= reg_v[1];
					reg_v[1] <= reg_v[2];
					reg_v[2] <= reg_v[3];
					reg_v[3] <= reg_v[4];
					reg_v[4] <= reg_v[5];
				end

				//initiate read for new Y values
				address <= address_y;
				
				if (counter < 9'd319) begin
		    		address_y <= address_y + 18'd1;
  	     end
				milestone1 <= common_case_4;

			end

			common_case_4: begin
			 
				value_u_prime <= (mult1_out + mult2_out + mult3_out + signed_128) >>> 8; 

				//Y matrix calculation for R value
				mult1_op1 <= signed_76284;
				mult1_op2 <= (reg_y[0] - signed_16);
			
				//V matrix calculation for R value
				mult2_op1 <= signed_104595;
				mult2_op2 <= (value_v_prime - signed_128);
				
				if (counter <= 9'd310) begin
				
					if(read_cycle_en) begin
						reg_u[0] <= reg_u[1];
						reg_u[1] <= reg_u[2];
						reg_u[2] <= reg_u[3];
						reg_u[3] <= reg_u[4];
						reg_u[4] <= reg_u[5];
						reg_u[5] <= SRAM_read_data[7:0];

					end else begin
						reg_u[0] <= reg_u[1];
						reg_u[1] <= reg_u[2];
						reg_u[2] <= reg_u[3];
						reg_u[3] <= reg_u[4];
						reg_u[4] <= reg_u[5];
						reg_u[5] <= SRAM_read_data[15:8];
					end
					
				end else begin
				
					reg_u[0] <= reg_u[1];
					reg_u[1] <= reg_u[2];
					reg_u[2] <= reg_u[3];
					reg_u[3] <= reg_u[4];
					reg_u[4] <= reg_u[5];
					
				end
				milestone1 <= common_case_5;

			end

			common_case_5: begin

				
				//use mutlipler output from previous cycle to finalize R value
				matrix_value_y <= (mult1_out);
				matrix_value_v <= (mult2_out);
				value_R <= (mult1_out + mult2_out) >>> 16; //shifting 16 bits to the right is equivalent to dividing by 2^16
			
				//U matrix calculation for G value
				mult1_op1 <= signed_neg_25624;
				mult1_op2 <= (value_u_prime - signed_128);

				//V matrix calculation for G value
				mult2_op1 <= signed_neg_53281;
				mult2_op2 <= (value_v_prime - signed_128);

				//U matrix calculation for B value
				mult3_op1 <= signed_132251;
				mult3_op2 <= (value_u_prime - signed_128);

				//write B and R values to SRAM
				write_en_n <= 1'b0;
				address <= address_RGB;

				//if ANY value needs to be clipped, enter this conditional statement
				if ((value_B < 8'd0) || (clipped_value_R < 8'd0) || ((value_B > 8'd255) || (clipped_value_R > 8'd255))) begin

					//if both values are above 255
					if ((value_B > 8'd255) && (clipped_value_R > 8'd255)) begin
						write_data <= {8'd255, 8'd255};
					//if both values are below 0
					end else if ((value_B < 8'd0) && (clipped_value_R < 8'd0)) begin
						write_data <= {8'd0, 8'd0};
					//if B is above 255 AND R is below 0 
					end else if ((value_B > 8'd255) && (clipped_value_R < 8'd0)) begin
						write_data <= {8'd255, 8'd0};
					//if B is below 0 AND R is above 255
					end else if ((value_B < 8'd0) && (clipped_value_R > 8'd255)) begin
						write_data <= {8'd0, 8'd255};
					//if B values is below 0
					end else if (value_B < 8'd0) begin
						write_data <= {8'd0, clipped_value_R[7:0]};
					//if B value is above 255
					end else if (value_B > 8'd255) begin
						write_data <= {8'd255, clipped_value_R[7:0]};
					//if R value is below 0
					end else if (clipped_value_R < 8'd0) begin
						write_data <= {value_B[7:0], 8'd0};
					//if R value is above 255
					end else if (clipped_value_R > 8'd255) begin
						write_data <= {value_B[7:0], 8'd255};
						
				  	//if no  values need to be clipped
			   		end else begin
		
					write_data <= {value_B[7:0], clipped_value_R[7:0]};
          
          			end
				end

				//write_data <= {{value_B}[7:0], {((mult1_out + mult2_out) >>> 16)}[7:0]};

				address_RGB <= address_RGB + 18'd1;

				//incriment counter everytime we write a B value, so we know when to exit the common_case loop
				counter <= counter + 9'd1;

				milestone1 <= common_case_6;

			end

			common_case_6: begin

				//use mutliplier output from previous cycle to finalize G value
				matrix_value_u <= (mult1_out);
				matrix_value_v <= (mult2_out);
				value_G <= (matrix_value_y + mult1_out + mult2_out) >>> 16;

				//use mutliplier output from previous cycle to finalize B value
				matrix_value_u <= (mult3_out);
				value_B <= (matrix_value_y + mult3_out ) >>> 16;

				//write G and B values to SRAM
				write_en_n <= 1'b0;
				address <= address_RGB;

				//if ANY value needs to be clipped, enter this conditional statement
				if ((clipped_value_G > 8'd255) || (clipped_value_G < 8'd0) || (clipped_value_B > 8'd255) || (clipped_value_B < 8'd0)) begin

					//if both values are above 255
					if ((clipped_value_G > 8'd255) &&  (clipped_value_B > 8'd255)) begin
						write_data <= {8'd255, 8'd255};
					//if both values are below 0
					end else if ((clipped_value_G < 8'd0) && (clipped_value_B < 8'd0)) begin
						write_data <= {8'd0, 8'd0};
					//if G is above 255 AND B is below 0 
					end else if ((clipped_value_G > 8'd255) && (clipped_value_B < 8'd0)) begin
						write_data <= {8'd255, 8'd0};
					//if G is below 0 AND B is above 255
					end else if ((clipped_value_G < 8'd0) && (clipped_value_B > 8'd255)) begin
						write_data <= {8'd0, 8'd255};
					//if G values is below 0
					end else if (clipped_value_G < 8'd0) begin
						write_data <= {8'd0, clipped_value_B[7:0]};
					//if G value is above 255
					end else if (clipped_value_G > 8'd255) begin
						write_data <= {8'd255, clipped_value_B[7:0]};
					//if B value is below 0
					end else if (clipped_value_B < 8'd0) begin
						write_data <= {clipped_value_G[7:0], 8'd0};
					//if B value is above 255
					end else if (clipped_value_B > 8'd255) begin
						write_data <= {clipped_value_G[7:0], 8'd255};
						
				  	//if no  values need to be clipped
			   		end else begin
		
						write_data <= {clipped_value_G[7:0], clipped_value_B[7:0]};
          
          			end
				end

				//write_data <= {{((matrix_value_y + mult1_out + mult2_out) >>> 16)}[7:0], {((matrix_value_y + mult3_out) >>> 16)}[7:0]};

				address_RGB <= address_RGB + 18'd1;
				counter <= counter + 9'd1;

				//store the y values from the read we initiated 3 cycles ago
				reg_y[1] <= SRAM_read_data[15:8];
				reg_y[0] <= SRAM_read_data[7:0];

				//flip the read_cycle_en bit so we do/do not read V and U values on the next cycle
				read_cycle_en <= ~read_cycle_en;
			
				if (counter < 9'd317) begin

					milestone1 <= common_case_0;

				end else begin
				 
					if (counter >= 9'd317) begin
					   milestone1 <= lead_out_0;
					   
					end
					 
				end
		
			end
			
			lead_out_0: begin
			  write_en_n <= 1'd1;
				//Y matrix calculation for R value
				//the output of this multiplication will be available in the next cycle
				mult1_op1 <= signed_76284;
				mult1_op2 <= (reg_y[1] - signed_16);
			
				//V matrix calculation for R value
				//the output of this multiplication will be available in the next cycle
				mult2_op1 <= signed_104595;
				mult2_op2 <= (reg_v[2] - signed_128);
				
				milestone1 <= lead_out_1;
			  
			end
			
			lead_out_1: begin
			  
			  //use mutlipler output from previous cycle to finalize R value
				matrix_value_y <= mult1_out;
				matrix_value_v <= mult2_out;
				value_R <= (mult1_out + mult2_out) >>> 16; //shifting 16 bits to the right is equivalent to dividing by 2^16
			
				//U matrix calculation for G value
				mult1_op1 <= signed_neg_25624;
				mult1_op2 <= (reg_u[2] - signed_128);

				//V matrix calculation for G value
				mult2_op1 <= signed_neg_53281;
				mult2_op2 <= (reg_v[2] - signed_128);

				//U matrix calculation for B value
				mult3_op1 <= signed_132251;
				mult3_op2 <= (reg_u[2] - signed_128);
				
				milestone1 <= lead_out_2;

			end
			
			lead_out_2: begin
			
				write_en_n <= 1'd0;
				//use mutliplier output from previous cycle to finalize G value
				matrix_value_u <= mult1_out;
				matrix_value_v <= mult2_out;
				value_G <= (matrix_value_y + mult1_out + mult2_out) >>> 16;

				//use mutliplier output from previous cycle to finalize B value
				matrix_value_u <= mult3_out;
				value_B <= (matrix_value_y + mult3_out) >>> 16;

				//write R and G values to SRAM
				write_en_n <= 1'b0;
				address <= address_RGB;

				//if ANY value needs to be clipped, enter this conditional statement
				if ((clipped_value_R < 8'd0) || (clipped_value_G < 8'd0) || ((clipped_value_R > 8'd255) || (clipped_value_G > 8'd255))) begin

					//if both values are above 255
					if ((value_R > 8'd255) && (clipped_value_G > 8'd255)) begin
						write_data <= {8'd255, 8'd255};
					//if both values are below 0
					end else if ((value_R < 8'd0) && (clipped_value_G < 8'd0)) begin
						write_data <= {8'd0, 8'd0};
					//if R is above 255 AND G is below 0 
					end else if ((value_R > 8'd255) && (clipped_value_G < 8'd0)) begin
						write_data <= {8'd255, 8'd0};
					//if R is below 0 AND G is above 255
					end else if ((value_R < 8'd0) && (clipped_value_G > 8'd255)) begin
						write_data <= {8'd0, 8'd255};
					//if R values is below 0
					end else if (value_R < 8'd0) begin
						write_data <= {8'd0, clipped_value_G};
					//if R value is above 255
					end else if (value_R > 8'd255) begin
						write_data <= {8'd255, clipped_value_G};
					//if G value is below 0
					end else if (clipped_value_G < 8'd0) begin
						write_data <= {value_R, 8'd0};
					//if G value is above 255
					end else if (clipped_value_G> 8'd255) begin
						write_data <= {value_R, 8'd255};
						
				 	 //if no  values need to be clipped
			   		end else begin
		
					   write_data <= {value_R, clipped_value_G};
          
     			  	end
				end

				//write_data <= {{value_R}[7:0], {((matrix_value_y + mult1_out + mult2_out) >>> 16)}[7:0]};

				address_RGB <= address_RGB + 18'd1;

				//compute V' for odd RGB value	
				mult1_op1 <= signed_21;
				mult1_op2 <= (reg_v[0] + reg_v[5]); //the u values we require will always be at the start and end of our register
				
				mult2_op1 <= signed_neg_52;
				mult2_op2 <= (reg_v[1] + reg_v[4]);
				
				mult3_op1 <= signed_159;
				mult3_op2 <= (reg_v[2] + reg_v[3]);
				
				milestone1 <= lead_out_3;
			end
			
			lead_out_3: begin
				write_en_n <= 1'd1;
				value_v_prime <= (mult1_out + mult2_out + mult3_out + signed_128) >>> 8; 

				//fill multipliers with new values to compute odd U'
				mult1_op1 <= signed_21;
				mult1_op2 <=(reg_u[0] + reg_u[5]); //the u values we require will always be at the start and end of our register
				
				mult2_op1 <= signed_neg_52; 
				mult2_op2 <= (reg_u[1] + reg_u[4]);
				
				mult3_op1 <= signed_159;
				mult3_op2 <= (reg_u[2] + reg_u[3]);
				
				if(read_cycle_en) begin
					reg_v[0] <= reg_v[1];
					reg_v[1] <= reg_v[2];
					reg_v[2] <= reg_v[3];
					reg_v[3] <= reg_v[4];
					reg_v[4] <= reg_v[5];
					reg_v[5] <= SRAM_read_data[7:0];

				end else begin
					reg_v[0] <= reg_v[1];
					reg_v[1] <= reg_v[2];
					reg_v[2] <= reg_v[3];
					reg_v[3] <= reg_v[4];
					reg_v[4] <= reg_v[5];
					reg_v[5] <= SRAM_read_data[15:8];
				end
				
				milestone1 <= lead_out_4;
				
			end
			
			lead_out_4: begin
			  
			  value_u_prime <= (mult1_out + mult2_out + mult3_out + signed_128) >>> 8; 

				//Y matrix calculation for R value
				mult1_op1 <= signed_76284;
				mult1_op2 <= (reg_y[0] - signed_16);
			
				//V matrix calculation for R value
				mult2_op1 <= signed_104595;
				mult2_op2 <= (value_v_prime - signed_128);
				
				if(read_cycle_en) begin
					reg_u[0] <= reg_u[1];
					reg_u[1] <= reg_u[2];
					reg_u[2] <= reg_u[3];
					reg_u[3] <= reg_u[4];
					reg_u[4] <= reg_u[5];
					reg_u[5] <= SRAM_read_data[7:0];

				end else begin
					reg_u[0] <= reg_u[1];
					reg_u[1] <= reg_u[2];
					reg_u[2] <= reg_u[3];
					reg_u[3] <= reg_u[4];
					reg_u[4] <= reg_u[5];
					reg_u[5] <= SRAM_read_data[15:8];
				end
				
				milestone1 <= lead_out_5;
			end
			
			lead_out_5: begin
				write_en_n <= 1'd0;
			  //use mutlipler output from previous cycle to finalize R value
				matrix_value_y <= (mult1_out);
				matrix_value_v <= (mult2_out);
				value_R <= (mult1_out + mult2_out) >>> 16; //shifting 16 bits to the right is equivalent to dividing by 2^16
			
				//U matrix calculation for G value
				mult1_op1 <= signed_neg_25624;
				mult1_op2 <= (value_u_prime - signed_128);

				//V matrix calculation for G value
				mult2_op1 <= signed_neg_53281;
				mult2_op2 <= (value_v_prime - signed_128);

				//U matrix calculation for B value
				mult3_op1 <= signed_132251;
				mult3_op2 <= (value_u_prime - signed_128);

				//write B and R values to SRAM
				write_en_n <= 1'b0;
				address <= address_RGB;

				//if ANY value needs to be clipped, enter this conditional statement
				if ((value_B < 8'd0) || (clipped_value_R < 8'd0) || ((value_B > 8'd255) || (clipped_value_R > 8'd255))) begin

					//if both values are above 255
					if ((value_B > 8'd255) && (clipped_value_R > 8'd255)) begin
						write_data <= {8'd255, 8'd255};
					//if both values are below 0
					end else if ((value_B < 8'd0) && (clipped_value_R < 8'd0)) begin
						write_data <= {8'd0, 8'd0};
					//if B is above 255 AND R is below 0 
					end else if ((value_B > 8'd255) && (clipped_value_R < 8'd0)) begin
						write_data <= {8'd255, 8'd0};
					//if B is below 0 AND R is above 255
					end else if ((value_B < 8'd0) && (clipped_value_R > 8'd255)) begin
						write_data <= {8'd0, 8'd255};
					//if B values is below 0
					end else if (value_B < 8'd0) begin
						write_data <= {8'd0, clipped_value_R[7:0]};
					//if B value is above 255
					end else if (value_B > 8'd255) begin
						write_data <= {8'd255, clipped_value_R[7:0]};
					//if R value is below 0
					end else if (clipped_value_R < 8'd0) begin
						write_data <= {value_B[7:0], 8'd0};
					//if R value is above 255
					end else if (clipped_value_R > 8'd255) begin
						write_data <= {value_B[7:0], 8'd255};
						
				  	//if no  values need to be clipped
			   		end else begin
		
					write_data <= {value_B[7:0], clipped_value_R[7:0]};
          
          			end
				end

				//write_data <= {{value_B}[7:0], {((mult1_out + mult2_out) >>> 16)}[7:0]};

				address_RGB <= address_RGB + 18'd1;
				
				counter <= counter + 9'd1;
				
				milestone1 <= lead_out_6;
			end
			
			lead_out_6: begin
			
			  //use mutliplier output from previous cycle to finalize G value
				matrix_value_u <= (mult1_out);
				matrix_value_v <= (mult2_out);
				value_G <= (matrix_value_y + mult1_out + mult2_out) >>> 16;

				//use mutliplier output from previous cycle to finalize B value
				matrix_value_u <= (mult3_out);
				value_B <= (matrix_value_y + mult3_out ) >>> 16;

				//write G and B values to SRAM
				write_en_n <= 1'b0;
				address <= address_RGB;

				//if ANY value needs to be clipped, enter this conditional statement
				if ((clipped_value_G > 8'd255) || (clipped_value_G < 8'd0) || (clipped_value_B > 8'd255) || (clipped_value_B < 8'd0)) begin

					//if both values are above 255
					if ((clipped_value_G > 8'd255) &&  (clipped_value_B > 8'd255)) begin
						write_data <= {8'd255, 8'd255};
					//if both values are below 0
					end else if ((clipped_value_G < 8'd0) && (clipped_value_B < 8'd0)) begin
						write_data <= {8'd0, 8'd0};
					//if G is above 255 AND B is below 0 
					end else if ((clipped_value_G > 8'd255) && (clipped_value_B < 8'd0)) begin
						write_data <= {8'd255, 8'd0};
					//if G is below 0 AND B is above 255
					end else if ((clipped_value_G < 8'd0) && (clipped_value_B > 8'd255)) begin
						write_data <= {8'd0, 8'd255};
					//if G values is below 0
					end else if (clipped_value_G < 8'd0) begin
						write_data <= {8'd0, clipped_value_B[7:0]};
					//if G value is above 255
					end else if (clipped_value_G > 8'd255) begin
						write_data <= {8'd255, clipped_value_B[7:0]};
					//if B value is below 0
					end else if (clipped_value_B < 8'd0) begin
						write_data <= {clipped_value_G[7:0], 8'd0};
					//if B value is above 255
					end else if (clipped_value_B > 8'd255) begin
						write_data <= {clipped_value_G[7:0], 8'd255};
						
				  	//if no  values need to be clipped
			   		end else begin
		
						write_data <= {clipped_value_G[7:0], clipped_value_B[7:0]};
          
          			end
				end

				address_RGB <= address_RGB + 18'd1;
				
				address_v <= address_v + 18'd1;
				address_u <= address_u + 18'd1;
				
				read_cycle_en <= 1'd0;
				
				counter_vert <= counter_vert + 8'd1;
				
				//store the y values from the read we initiated 3 cycles ago
				reg_y[1] <= SRAM_read_data[15:8];
				reg_y[0] <= SRAM_read_data[7:0];
				
				counter <= 9'd0;
				
				if (counter_vert < 8'd239) begin

				  milestone1 <= lead_in_0;

				end else begin
				
					write_en_n <= 1'b1;
			  	 milestone1_finish <= 1'b1;
			  	 milestone1 <= idle;
				 
				end
			end
			
			
			default: milestone1 <= idle;
			endcase
			
		end
	end
//**** use finish state and send to top FSM ****
endmodule
