/*---------------------------------------------------------------------------------------------------------------------
-- Author:          Peter Hasza, hasza.peti@gmail.com
-- 
-- Create Date:     04/02/2017 
-- Module Name:     apb_reg_if
-- Project Name:    AXI_SPI_IF
-- Description: 
--					APB Slave module for register interface
--
------------------------------ REVISION HISTORY -----------------------------------------------------------------------
--
-- 2017.apr.18	|	hp3265	||	Initial version
--
-----------------------------------------------------------------------------------------------------------------------*/

module apb_reg_if (

	/* Generic Parameters */
	parameter g_apb_addr_width		= 8,
	
	localparam c_data_width        = 32;
	localparam c_log2_data_width   = clogb2(c_data_width)
	
	) (
	
	/* System Clock and Reset */
	input			pclk_i,										// APB clock
	input			preset_n_i,									// APB asynchronous reset
	
	/* APB Bridge signals */
	input 			[g_apb_addr_width-1:0] 		paddr_i,
	input			[2:0]						pprot_i,
	input										psel_i,
	input										penable_i,
	input										pwrite_i,
	input			[c_data_width-1:0]			pwdata_i,
	input			[c_log2_data_width-1:0]		pstrb_i,
	
	/* APB Slave interface signals */
	output										pready_o,
	output			[c_data_width-1:0]			prdata_o,
	output										pslverr_o,
	
	/* Internal register interface */
	input			[c_data_width-1:0]			reg_control_i,
	input			[c_data_width-1:0]			reg_addr_window_0_i,
	input			[c_data_width-1:0]			reg_addr_window_1_i,
	input			[c_data_width-1:0]			reg_addr_window_2_i;
	input			[c_data_width-1:0]			reg_addr_window_3_i,
	input			[c_data_width-1:0]			reg_status_i,
	
	output			[c_data_width-1:0]			reg_data_o,
	output										reg_load_o,
	output			[2:0]						reg_sel_o
);

	/*=============================================================================================
	--  APB Clock Domain
	--=============================================================================================*/
	parameter [1:0]
		IDLE 		= 2'd0,
		R_ENABLE 	= 2'd1,
		W_ENABLE 	= 2'd2;
		
	reg [2:0]
		state, next_state;
	
	always @ (posedge pclk_i, negedge preset_n_i)
	begin
		if (!preset_n_i)
			state <= IDLE;
		else
			state <= next_state;
	end
	
	reg pready_y;
	reg pslverr_y;
	reg [g_apb_data_width-1:0] prdata_y;
	
	reg reg_sel_y;
	reg [c_data_width-1:0] reg_data_y;
	reg reg_load_y;
	
	always @ (posedge pclk_i)
	begin
		case (reg_sel_y)
			3'd0 : prdata_y <= reg_control_i;
			3'd1 : prdata_y <= reg_addr_window_0_i;
			3'd2 : prdata_y <= reg_addr_window_1_i;
			3'd3 : prdata_y <= reg_addr_window_2_i;
			3'd4 : prdata_y <= reg_addr_window_2_i;
			3'd5 : prdata_y <= reg_status_i;
			default : prdata_y <= reg_status_i;
		endcase;
	end
	
	genvar i;
	generate
	for (i = 0; i < c_log2_data_width ; i = i + 1) begin: 
		always @(posedge pclk_i) begin
			reg_data_y[(i*8+7):(i*8)] <= (pstrb_i[i] == 1) ? pwdata_i[(i*8+7):(i*8)] : 8'd0;	
		end
	end
	endgenerate
	
	always @ (posedge pclk_i, negedge preset_n_i)
	begin
		case (state)
			IDLE :
				begin
					pready_y <= 0;
					pslverr_y <= 0;
					reg_load_y <= 0;
				end
			R_ENABLE :
				begin
					pready_y <= 1;
					reg_sel_y <= paddr_i[3:0];
					if (paddr_i > 3'd5)
						pslverr_y <= 1;
					else
						pslverr_y <= 0;
				end
			W_ENABLE :
				begin
					pready_y <= 1;
					reg_sel_y <= paddr_i[3:0];
					reg_load_y <= 1;
					if (paddr_i > 3'd4)			// Status register is HW-Modified
						pslverr_y <= 1;
					else
						pslverr_y <= 0;
						
				end
			default :	// Should never go into default state
				begin
					pready_y <= 0;
					pslverr_y <= 0;
					reg_load_y <= 0;
				end
		endcase;
	end
	
	always @ (posedge pclk_i, negedge preset_n_i)
	begin
		if (!preset_n_i)
			next_state <= IDLE;
		else
		begin
			if (psel_i and (!penable_i) and pwrite_i)
				next_state <= #1 W_ENABLE;
			else if (psel_i and (!penable_i) and (!pwrite_i))
				next_state <= #1 R_ENABLE;
			else
				next_state <= #1 IDLE;
		end
	end
	
	pready_o <= pready_y;
	prdata_o <= prdata_y;
	pslverr_o <= pslverr_y;
	
	reg_data_o <= reg_data_y;
	reg_load_o <= reg_load_y;
	reg_sel_o <= reg_sel_y;
	
endmodule;