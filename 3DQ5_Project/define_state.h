`ifndef DEFINE_STATE

// This defines the states
typedef enum logic [2:0] {
	S_IDLE,
	S_ENABLE_UART_RX,
	S_WAIT_UART_RX,
    S_top_m1,
	S_top_m2
} top_state_type;

typedef enum logic [1:0] {
	S_RXC_IDLE,
	S_RXC_SYNC,
	S_RXC_ASSEMBLE_DATA,
	S_RXC_STOP_BIT
} RX_Controller_state_type;

typedef enum logic [2:0] {
	S_US_IDLE,
	S_US_STRIP_FILE_HEADER_1,
	S_US_STRIP_FILE_HEADER_2,
	S_US_START_FIRST_BYTE_RECEIVE,
	S_US_WRITE_FIRST_BYTE,
	S_US_START_SECOND_BYTE_RECEIVE,
	S_US_WRITE_SECOND_BYTE
} UART_SRAM_state_type;

typedef enum logic [3:0] {
	S_VS_WAIT_NEW_PIXEL_ROW,
	S_VS_NEW_PIXEL_ROW_DELAY_1,
	S_VS_NEW_PIXEL_ROW_DELAY_2,
	S_VS_NEW_PIXEL_ROW_DELAY_3,
	S_VS_NEW_PIXEL_ROW_DELAY_4,
	S_VS_NEW_PIXEL_ROW_DELAY_5,
	S_VS_FETCH_PIXEL_DATA_0,
	S_VS_FETCH_PIXEL_DATA_1,
	S_VS_FETCH_PIXEL_DATA_2,
	S_VS_FETCH_PIXEL_DATA_3
} VGA_SRAM_state_type;

typedef enum logic [4:0] {
	//12 lead in cases
	idle,
	lead_in_0,
	lead_in_1,
	lead_in_2,
	lead_in_3,
	lead_in_4,
	lead_in_5,
	lead_in_6,
	lead_in_7,
	lead_in_8,
	lead_in_9,
	lead_in_10,
	lead_in_11,
	lead_in_12,
	//7 common cases
	common_case_0,
	common_case_1,
	common_case_2,
	common_case_3,
	common_case_4,
	common_case_5,
	common_case_6,
	//7 lead out cases
	lead_out_0,
	lead_out_1,
	lead_out_2,
	lead_out_3,
	lead_out_4,
	lead_out_5,
	lead_out_6,
	final_state,
	milestone1_done
} milestone_state_type;

typedef enum logic [6:0]{
	m2_idle,
	fill_lead_in0,
	fill_lead_in1,
	fill_lead_in2,
	fill_lead_in3,
	fill_lead_in4,
	fill_lead_in5,
	fill_lead_in6,
	fill_lead_in7,
	fill_lead_in8,
	fill_lead_in9,
	fill_lead_in10,
	fill_lead_in11,
	fill_CC0,
	fill_CC1,
	fill_CC2,
	fill_CC3,
	fill_CC4,
	fill_CC5,
	fill_CC6,
	fill_CC7,
	fill_lead_out0,
	fill_lead_out1,
	fill_lead_out2,
	fill_lead_out3,
	fill_lead_out4,
	fill_lead_out5,
	fill_lead_out6,
	fill_lead_out7,
	t_calc_lead_in0,
	t_calc_lead_in1,
	t_calc_lead_in2,
	t_calc_lead_in3,
	t_calc_lead_in4,
	t_calc_lead_in5,
	t_calc_lead_in6,
	t_calc_lead_in7,
	t_calc_lead_in8,
	t_calc_lead_in9,
	t_calc_lead_in10,
	t_calc_CC_0,
	t_calc_CC_1,
	t_calc_CC_2,
	t_calc_CC_3,
	t_calc_CC_4,
	t_calc_CC_5,
	t_calc_CC_6,
	t_calc_CC_7,
	S_calc_lead_in0,
	S_calc_lead_in1,
	S_calc_lead_in2,
	S_calc_lead_in3,
	S_calc_lead_in4,
	S_calc_lead_in5,
	S_calc_lead_in6,
	S_calc_lead_in7,
	S_calc_lead_in8,
	S_calc_lead_in9,
	S_calc_lead_in10,
	S_calc_CC0,
	S_calc_CC1,
	S_calc_CC2,
	S_calc_CC3,
	S_calc_CC4,
	S_calc_CC5,
	S_calc_CC6,
	S_calc_CC7,
	m2_final_state

} m2_state_type;



`define DEFINE_STATE 1
`endif
