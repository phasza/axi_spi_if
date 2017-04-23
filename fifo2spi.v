/*---------------------------------------------------------------------------------------------------------------------
-- Author:          Peter Hasza, hasza.peti@gmail.com
-- 
-- Create Date:     04/02/2017 
-- Module Name:     fifo2spi
-- Project Name:    AXI_SPI_IF
-- Description: 
--					Converts the data from the FIFOs to valid SPI requests.
--					Functions:
--								- Control signals to SPI Master from Control Registers
--								- AXI Address mapping to SPI Slave Select based on Address Window Registers
--								- Signaling current status to Status Register
--
------------------------------ REVISION HISTORY -----------------------------------------------------------------------
--
-- 2017.apr.19	|	hp3265	||	Initial version
--
-----------------------------------------------------------------------------------------------------------------------*/

module fifo2spi (

	/* System Clock & Reset */
	input											clk_i,						// System clock
	input											reset_n_i,					// System asynchronous reset
	
	/* Register interface */
	input			[31:0]						reg_control_i,
	input			[31:0]						reg_trans_ctrl_i,
	input			[31:0]						reg_status_i,
	output 										spi_busy_o,
	output			[31:0]					reg_data_o,
	output										reg_load_o,
	output			[1:0]						reg_sel_o,
	
	/* FIFO interface */
	// Write Request FIFO signals
	input											wr_req_empty_i,
	input			[1:0]							wr_req_data_i,
	output										wr_req_pull_o,
	
	// Write Data FIFO signals
	input											wr_data_empty_i,
	input			[35:0]						wr_data_data_i,
	output										wr_data_pull_o,
	
	// Write Response FIFO signals
	input											wr_resp_full_i,
	output			[1:0]						wr_resp_data_o,
	output										wr_resp_push_o,
	
	// Read Request FIFO signals
	input											rd_req_empty_i,
	input			[1:0]							rd_req_data_i,
	output										rd_req_pull_o,
	
	// Read Resp FIFO signals
	input											rd_resp_full_i,
	output			[33:0]					rd_resp_data_o,
	output										rd_resp_push_o,
	
	// TX FIFO signals
	input											tx_full_i,
	output			[31:0]					tx_data_o,
	output										tx_push_o,
	
	// RX FIFO signals
	input											rx_empty_i,
	input			[31:0]						rx_data_i,
	output										rx_pull_o,
	
	// SPI Master signals
	input											trans_done_i,
	output										trans_start_o
	
);

	reg 			spi_busy_y;

	reg [31:0] 	reg_data_y;
	reg 			reg_load_y;
	reg [1:0] 	reg_sel_y;
	
	reg			wr_req_pull_y;
	reg 			wr_data_pull_y;
	reg [1:0] 	wr_resp_data_y;
	reg 			wr_resp_push_y;
	reg			rd_req_pull_y;
	reg 			rd_resp_push_y;
	reg [33:0] 	rd_resp_data_y;
	reg [31:0]  tx_data_y;
	reg 			tx_push_y;
	reg			rx_pull_y;
	
	
	/*=============================================================================================
    --  Request Decoder FSM
    --=============================================================================================*/
	parameter [2:0]
		IDLE = 3'd0,
		START_WRITE = 3'd1,
		START_READ = 3'd2,
		WAIT_SEND_WR_RESP = 3'd3,
		WAIT_SEND_RD_RESP = 3'd4;
	
	reg [2:0]
		request_state;
	always @ (posedge clk_i or negedge reset_n_i)
	begin
		if (!reset_n_i)
			request_state <= IDLE;
		else
		begin
			case (request_state)
				IDLE :
					begin
						wr_req_pull_y <= 0;
						wr_data_pull_y <= 0;
						wr_resp_push_y <= 0;
						rd_req_pull_y <= 0;
						rd_resp_push_y <= 0;
						reg_load_y <= 0;
						tx_push_y <= 0;
						rx_pull_y <= 0;
						if (!wr_req_empty_i & !wr_data_empty_i & !spi_busy_y)
							request_state <= START_WRITE;
						else if (!rd_req_empty_i & !spi_busy_y)
							request_state <= START_READ;
					end
			
				START_WRITE :
					begin
						wr_req_pull_y <= 1;
						wr_data_pull_y <= 1;
						
						if (wr_req_data_i < 2'd2)			// WRITE registers
						begin
							reg_data_y <= wr_data_data_i[35:4];				// TODO Use strobes
							reg_load_y <= 1;
							reg_sel_y <= wr_req_data_i;
							wr_resp_data_y <= 0;
							if (!wr_resp_full_i)
							begin
								wr_resp_push_y <= 1; 
								request_state <= IDLE;
							end
							else
							begin
								request_state <= WAIT_SEND_WR_RESP;
							end
						end
						else if (wr_req_data_i == 2'd2)		// ACCESS ERROR
						begin
							wr_resp_data_y <= 2'd2;
							if (!wr_resp_full_i)
							begin
								wr_resp_push_y <= 1; 
								request_state <= IDLE;
							end
							else
							begin
								request_state <= WAIT_SEND_WR_RESP;
							end
						end
						else								// TX FIFO WRITE
						begin
							tx_data_y <= wr_data_data_i[35:4]; 				// TODO Use strobes, assign somewhere else
							if (!tx_full_i)
							begin
								tx_push_y <= 1; 
								request_state <= IDLE;
							end
							else
							begin
								wr_resp_data_y <= 2'd2;			// TODO Write Error register
								if (!wr_resp_full_i)
								begin
									wr_resp_push_y <= 1; 
									request_state <= IDLE;
								end
								else
								begin
									request_state <= WAIT_SEND_WR_RESP;
								end
							end
						end					
					end
				START_READ :
					begin
						rd_req_pull_y <= 1;
						if (rd_req_data_i < 2'd3)			// READ registers
						begin
							rd_resp_data_y[1:0] <= 0; 
							case (rd_req_data_i[1:0])
								2'd0 : rd_resp_data_y[33:2] <= reg_control_i;
								2'd1 : rd_resp_data_y[33:2] <= reg_trans_ctrl_i;
								2'd2 : rd_resp_data_y[33:2] <= reg_status_i;
								default : rd_resp_data_y[33:2] <= 32'bx;
							endcase
							
							if (!rd_resp_full_i)
							begin
								rd_resp_push_y <= 1; 
								request_state <= IDLE;
							end
							else
							begin
								request_state <= WAIT_SEND_RD_RESP;
							end
						end
						else								// RX FIFO READ
						begin							
							if (!rx_empty_i)
							begin
								rd_resp_data_y <= {rx_data_i, 2'd0 };
								rx_pull_y <= 1; 
							end
							else
							begin
								rd_resp_data_y <= {32'hFFFF_FFFF, 2'd2 };
							end
							if (!rd_resp_full_i)
							begin
								rd_resp_push_y <= 1; 
								request_state <= IDLE;
							end
							else
							begin
								request_state <= WAIT_SEND_RD_RESP;
							end
						end			
					end
				WAIT_SEND_WR_RESP :
					begin
						if (!wr_resp_full_i)
						begin
							wr_resp_push_y <= 1; 
							request_state <= IDLE;
						end
					end
				WAIT_SEND_RD_RESP :
					begin
						if (!rd_resp_full_i)
						begin
							rd_resp_push_y <= 1; 
							request_state <= IDLE;
						end
					end
				default :	// Should never go into default state, but if does, go to a safe place
					begin
						wr_req_pull_y <= 0;
						wr_data_pull_y <= 0;
						wr_resp_push_y <= 0;
						rd_req_pull_y <= 0;
						rd_resp_push_y <= 0;
						reg_load_y <= 0;
						tx_push_y <= 0;
						request_state <= IDLE;
					end
			endcase;
		end;
	end
	
	reg prev_spi_start_y;
	wire cur_spi_start_y;
	reg trans_start_y;
	
	assign cur_spi_start_y = reg_trans_ctrl_i[13];
	
	always @ (posedge clk_i, negedge reset_n_i)
	begin
		if (!reset_n_i)
		begin
			trans_start_y <= 0;
			prev_spi_start_y <= 0;
		end
		else
		begin
			if (!prev_spi_start_y & cur_spi_start_y)
				trans_start_y <= 1;
			else
				trans_start_y <= 0;
			prev_spi_start_y <= cur_spi_start_y;
		end
	end
	
	always @ (posedge clk_i, negedge reset_n_i)
	begin
		if (!reset_n_i)
			spi_busy_y <= 0;
		else
			if (trans_start_y)
				spi_busy_y <= 1;
			else if (trans_done_i)
				spi_busy_y <= 0;
	end
	
	assign trans_start_o = trans_start_o;
	assign spi_busy_o = spi_busy_y;
	assign reg_data_o = reg_data_y;
	assign reg_load_o = reg_load_y;
	assign reg_sel_o = reg_sel_y;
	assign wr_req_pull_o = wr_req_pull_y;
	assign wr_data_pull_o = wr_data_pull_y;
	assign wr_resp_data_o = wr_resp_data_y;
	assign wr_resp_push_o = wr_resp_push_y;
	assign rd_req_pull_o = rd_req_pull_y;
	assign rd_resp_push_o = rd_resp_push_y;
	assign rd_resp_data_o = rd_resp_data_y;
	assign tx_data_o = tx_data_y;
	assign tx_push_o = tx_push_y;
	assign rx_pull_o = rx_pull_y;

endmodule