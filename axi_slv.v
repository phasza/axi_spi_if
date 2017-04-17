/*---------------------------------------------------------------------------------------------------------------------
-- Author:          Peter Hasza, hasza.peti@gmail.com
-- 
-- Create Date:     04/02/2017 
-- Module Name:     axi4_lite_slv
-- Project Name:    AXI_SPI_IF
-- Description: 
--					AXI4-Lite Slave interface
--					Converts AXI4-Lite compliance requests into FIFO data for further processing
--						AXI4 to AXI4-Lite conversion is not supported
--						However, every requests are responded by DECERR, which is not AXI4-Lite compliant
--
------------------------------ REVISION HISTORY -----------------------------------------------------------------------
--
-- 2017.apr.2	|	hp3265	||	Initial version
--
-----------------------------------------------------------------------------------------------------------------------*/

// TODO make it protected against non Lite compliant requests

module axi4_lite_slv(

	/* Generic Parameters */
	parameter g_axi_data_width		= 32,						// Generic for AXI Data width
	parameter g_axi_addr_width		= 28,						// Generic for AXI Address width
	
	localparam c_log2_data_width   = clogb2(g_axi_data_width)
	
	) (
	
	/* System Clock and Reset */
	input			aclk_i,										// System clock
	input			areset_n_i,									// System asynchronous reset

    // AXI Write Address channel signals
	input 										awvalid_i,
	output										awready_o,
	input 			[g_axi_addr_width-1:0] 		awaddr_i,
	input										awprot_i,
	
	
	// AXI Write Data channel signals
	input										wvalid_i,
	output										wready_o,
	input			[g_axi_data_width-1:0]		wdata_i,
	input			[c_log2_data_width-1:0]		wstrb_i,
	
	// AXI Wrie response channel
	output										bvalid_o,
	input										bready_i,
	output			[1:0]						bresp_o,
	
	// AXI Read address channel
	input										arvalid_i,
	output										arready_o,
	input			[g_axi_addr_width-1:0]		araddr_i,
	input			[2:0]						arprot_i,
	
	// AXI Read data channel
	output										rvalid_o,
	input										rready_i,
	output			[g_axi_data_width-1:0]		rdata_o,
	output			[1:0]						rresp_o,
	
	// Write Request FIFO signals
	input										wr_req_full_i,
	output			[g_wr_req_width-1:0]		wr_req_data_o,
	output										wr_req_push_o,
	
	// Write Data FIFO signals
	input										wr_data_full_i,
	output			[g_wr_data_width-1:0]		wr_data_data_o,
	output										wr_data_push_o,
	
	// Write Response FIFO signals
	input										wr_resp_empty_i,
	input			[g_wr_resp_width-1:0]		wr_resp_data_i,
	output										wr_resp_pull_i,
	
	// Read Request FIFO signals
	input										rd_req_full_i,
	output			[g_rd_req_width-1:0]		rd_req_data_o,
	output										rd_req_push_o,
	
	// Read Resp FIFO signals
	input										rd_resp_empty_i,
	input			[g_rd_data_width-1:0]		rd_resp_data_i,
	output										rd_resp_pull_o
);

	parameter [1:0]
		IDLE = 2'd0,
		STORE_REQ = 2'd1,
		WAIT_READY = 2'd2,
		SEND_RESP = 2'd3;
		
    /*=============================================================================================
    --  WRITE ADDRESS CHANNEL FSM
    --=============================================================================================*/
	reg 	awready_y;
	reg		wr_req_push_y;
	reg [2:0]
		wr_req_state, wr_req_state_next;
	
	always @ (posedge aclk_i, negedge areset_n_i)
	begin
		if (!areset_n_i)
			wr_req_state <= IDLE;
		else
			wr_req_state <= wr_req_state_next;
	end
	
	always @ (posedge aclk_i, negedge areset_n_i)
	begin
		case (wr_req_state)
			IDLE :
				begin
					awready_y <= 1;
					wr_req_push_y <= 0;
				end
		
			STORE_REQ :
				begin
					awready_y <= 0;
					wr_req_push_y <= 1;
				end
			WAIT_READY :
				begin
					awready_y <= 0;
					wr_req_push_y <= 0;
				end
			default :	// Should never go into default state
				begin
					awready_y <= 0;
					wr_req_push_y <= 0;
				end
		endcase;
	end
		
	always @ (posedge aclk_i, negedge areset_n_i)
	begin
		if (!areset_n_i)
			wr_req_state_next <= IDLE;
		else
		begin
			if (awvalid_i and (!wr_req_full_i))
				wr_req_state_next <= #1 STORE_REQ; // Added delay to avoid hold-time problems
			else if (awvalid_i and wr_req_full_i)
				wr_req_state_next <= #1 WAIT_READY;
			else
				wr_req_state_next <= #1 IDLE;	
		end
	end
	
	assign awready_o <= awready_y;
	assign wr_req_push_o <= wr_req_push_y;
	assign wr_req_data_o <= awaddr_i;
	
    /*=============================================================================================
    --  WRITE DATA CHANNEL FSM
    --=============================================================================================*/
	reg 	wready_y;
	reg		wr_data_push_y;
	reg [2:0]
		wr_data_state, wr_data_state_next;
	
	always @ (posedge aclk_i, negedge areset_n_i)
	begin
		if (!areset_n_i)
			wr_data_state <= IDLE;
		else
			wr_data_state <= wr_data_state_next;
	end
	
	always @ (posedge aclk_i, negedge areset_n_i)
	begin
		case (wr_data_state)
			IDLE :
				begin
					wready_y <= 1;
					wr_data_push_y <= 0;
				end
		
			STORE_REQ :
				begin
					wready_y <= 0;
					wr_data_push_y <= 1;
				end
			WAIT_READY :
				begin
					wready_y <= 0;
					wr_data_push_y <= 0;
				end
			default :	// Should never go into default state
				begin
					wready_y <= 0;
					wr_data_push_y <= 0;
				end
		endcase;
	end
		
	always @ (posedge aclk_i, negedge areset_n_i)
	begin
		if (!areset_n_i)
			wr_data_state_next <= IDLE;
		else
		begin
			if (wvalid_i and (!wr_data_full_i))
				wr_data_state_next <= #1 STORE_REQ; // Added delay to avoid hold-time problems
			else if (wvalid_i and wr_data_full_i)
				wr_data_state_next <= #1 WAIT_READY;
			else
				wr_data_state_next <= #1 IDLE;	
		end
	end
	
	assign wready_o <= wready_y;
	assign wr_data_push_o <= wr_data_push_y;
	assign wr_data_data_o <= {wdata_i, wstrb_i};
	
    /*=============================================================================================
    --  WRITE RESPONSE CHANNEL FSM
    --=============================================================================================*/
	reg 	bvalid_y;
	reg		wr_resp_pull_y;
	reg [2:0]
		wr_resp_state, wr_resp_state_next;
	
	always @ (posedge aclk_i, negedge areset_n_i)
	begin
		if (!areset_n_i)
			wr_resp_state <= IDLE;
		else
			wr_resp_state <= wr_resp_state_next;
	end
	
	always @ (posedge aclk_i, negedge areset_n_i)
	begin
		case (wr_resp_state)
			IDLE :
				begin
					bvalid_y <= 0;
					wr_resp_pull_y <= 0;
				end
		
			SEND_RESP :
				begin
					bvalid_y <= 1;
					wr_resp_pull_y <= 1;
				end
			default :	// Should never go into default state
				begin
					bvalid_y <= 0;
					wr_resp_pull_y <= 0;
				end
		endcase;
	end	
	
	always @ (posedge aclk_i, negedge areset_n_i)
	begin
		if (!areset_n_i)
			wr_resp_state_next <= IDLE;
		else
		begin
			if (bready_i and (!wr_resp_empty_i))
				wr_data_state_next <= #1 SEND_RESP; // Added delay to avoid hold-time problems
			else
				wr_data_state_next <= #1 IDLE;	
		end
	end
	
	assign bvalid_o <= bvalid_y;
	assign wr_resp_pull_o <= wr_resp_pull_y;
	assign bresp_o <= wr_resp_data_i;
	
    /*=============================================================================================
    --  READ ADDRESS CHANNEL FSM
    --=============================================================================================*/
	reg 	arready_y;
	reg		rd_req_push_y;
	reg [2:0]
		rd_req_state, rd_req_state_next;
	
	always @ (posedge aclk_i, negedge areset_n_i)
	begin
		if (!areset_n_i)
			rd_req_state <= IDLE;
		else
			rd_req_state <= rd_req_state_next;
	end
	
	always @ (posedge aclk_i, negedge areset_n_i)
	begin
		case (rd_req_state)
			IDLE :
				begin
					arready_y <= 1;
					rd_req_push_y <= 0;
				end
		
			STORE_REQ :
				begin
					arready_y <= 0;
					rd_req_push_y <= 1;
				end
			WAIT_READY :
				begin
					arready_y <= 0;
					rd_req_push_y <= 0;
				end
			default :	// Should never go into default state
				begin
					arready_y <= 0;
					rd_req_push_y <= 0;
				end
		endcase;
	end
		
	always @ (posedge aclk_i, negedge areset_n_i)
	begin
		if (!areset_n_i)
			rd_req_state_next <= IDLE;
		else
		begin
			if (arvalid_i and (!rd_req_full_i))
				rd_req_state_next <= #1 STORE_REQ; // Added delay to avoid hold-time problems
			else if (arvalid_i and rd_req_full_i)
				rd_req_state_next <= #1 WAIT_READY;
			else
				rd_req_state_next <= #1 IDLE;	
		end
	end	
	
	assign arready_o <= arready_y;
	assign rd_req_push_o <= rd_req_push_y;
	assign rd_req_data_o <= araddr_i;
	
	/*=============================================================================================
    --  READ DATA CHANNEL FSM
    --=============================================================================================*/
	reg 	rvalid_y;
	reg		rd_resp_pull_y;
	reg [2:0]
		rd_resp_state, rd_resp_state_next;
	
	always @ (posedge aclk_i, negedge areset_n_i)
	begin
		if (!areset_n_i)
			rd_resp_state <= IDLE;
		else
			rd_resp_state <= rd_resp_state_next;
	end
	
	always @ (posedge aclk_i, negedge areset_n_i)
	begin
		case (rd_resp_state)
			IDLE :
				begin
					rvalid_y <= 0;
					rd_resp_pull_y <= 0;
				end
		
			SEND_RESP :
				begin
					rvalid_y <= 1;
					rd_resp_pull_y <= 1;
				end
			default :	// Should never go into default state
				begin
					rvalid_y <= 0;
					rd_resp_pull_y <= 0;
				end
		endcase;
	end	
	
	always @ (posedge aclk_i, negedge areset_n_i)
	begin
		if (!areset_n_i)
			rd_resp_state_next <= IDLE;
		else
		begin
			if (rready_i and (!rd_resp_empty_i))
				rd_resp_state_next <= #1 SEND_RESP; // Added delay to avoid hold-time problems
			else
				rd_resp_state_next <= #1 IDLE;	
		end
	end
	
	assign rvalid_o <= rvalid_y;
	assign rd_resp_pull_o <= rd_resp_pull_y;
	assign rdata_o <= rd_resp_data_i[g_axi_data_width+1:2];
	assign rresp_o <= rd_resp_data_i[1:0];
	
endmodule