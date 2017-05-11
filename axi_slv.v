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
--						Not protected against non AXI4-Lite access, this means an AXI4 access can cause deadlock for the Master
--						(i.e. the module won't send enough responses back for accesses having Axlen > 0)
--
------------------------------ REVISION HISTORY -----------------------------------------------------------------------
-- 2017.apr.2	|	hp3265	||	Initial version
-- 2017.apr.15 |  hp3265 	||	Completed FSMs
-- 2017.apr.20 |  hp3265 	||	Removed unnecessary generics
-- 2017.apr.23 |  hp3265 	||	Some comments and beautifying
-----------------------------------------------------------------------------------------------------------------------*/

module axi4_lite_slv #(

	/* Generic Parameters */
	parameter g_axi_addr_width	= 28							// Generic for AXI Address width
	
	) (
	
	/* System Clock and Reset */
	input											aclk_i,			// AXI clock
	input											areset_n_i,		// AXI asynchronous reset

    // AXI Write Address channel signals
	input 										awvalid_i,
	output										awready_o,
	input 	[g_axi_addr_width-1:0] 		awaddr_i,
	input											awprot_i,
	
	
	// AXI Write Data channel signals
	input											wvalid_i,
	output										wready_o,
	input		[31:0]							wdata_i,
	input		[3:0]								wstrb_i,
	
	// AXI Wrie response channel
	output										bvalid_o,
	input											bready_i,
	output	[1:0]								bresp_o,
	
	// AXI Read address channel
	input											arvalid_i,
	output										arready_o,
	input		[g_axi_addr_width-1:0]		araddr_i,
	input		[2:0]								arprot_i,
	
	// AXI Read data channel
	output										rvalid_o,
	input											rready_i,
	output	[31:0]							rdata_o,
	output	[1:0]								rresp_o,
	
	// Write Request FIFO signals
	input											wr_req_full_i,
	output	[1:0]								wr_req_data_o,
	output										wr_req_push_o,
	
	// Write Data FIFO signals
	input											wr_data_full_i,
	output	[35:0]							wr_data_data_o,
	output										wr_data_push_o,
	
	// Write Response FIFO signals
	input											wr_resp_empty_i,
	input		[1:0]								wr_resp_data_i,
	output										wr_resp_pull_o,
	
	// Read Request FIFO signals
	input											rd_req_full_i,
	output	[1:0]								rd_req_data_o,
	output										rd_req_push_o,
	
	// Read Resp FIFO signals
	input											rd_resp_empty_i,
	input		[33:0]							rd_resp_data_i,
	output										rd_resp_pull_o
);

	// State info enum type
	parameter [1:0]
		IDLE = 2'd0,
		STORE_REQ = 2'd1,
		WAIT_READY = 2'd2,
		SEND_RESP = 2'd3;
		
    /*=============================================================================================
    --  WRITE ADDRESS CHANNEL FSM		-- Moore type
    --=============================================================================================*/
	reg 	awready_y;
	reg	wr_req_push_y;
	
	initial awready_y = 1;
	initial wr_req_push_y = 0;
	
	reg [1:0] wr_req_state;
	
	// Main WR REQ FSM block
	always @ (posedge aclk_i)
	begin
		case (wr_req_state)
			// When IDLE:
			//		be ready to accept a request 	-> awready HIGH
			//		do not touch the FIFO			-> fifo_push LOW
			IDLE :
				begin
					awready_y <= 1;
					wr_req_push_y <= 0;
				end
		
			// When STORE_REQ:
			//		deassert ready -> awready LOW
			//		push to FIFO	-> fifo_push HIGH
			STORE_REQ :
				begin
					awready_y <= 0;
					wr_req_push_y <= 1;
				end
				
			// When WAIT_READY:
			//		keep ready deasserted -> awready LOW
			//		do not touch the FIFO -> fifo_push LOW
			WAIT_READY :
				begin
					awready_y <= 0;
					wr_req_push_y <= 0;
				end
				
			// When default:
			//		Should never go into this state, it's only for full_case synthesis
			//		but if it does, keep everything LOW
			default :
				begin
					awready_y <= 0;
					wr_req_push_y <= 0;
				end
		endcase;
	end
	
	// Next state selector
	always @ (posedge aclk_i or negedge areset_n_i)
	begin
		if (!areset_n_i)
			wr_req_state <= IDLE;
		else
		begin
			case (wr_req_state)
				IDLE :
					begin
						if (awvalid_i & (!wr_req_full_i))
							wr_req_state <= STORE_REQ;
						else if (awvalid_i & wr_req_full_i)
							wr_req_state <= WAIT_READY;
						else
							wr_req_state <= IDLE;
					end
				STORE_REQ :
					begin
						wr_req_state <= IDLE;
					end
				WAIT_READY :
					begin
						if (awvalid_i & (!wr_req_full_i))
							wr_req_state <= STORE_REQ;
						else
							wr_req_state <= WAIT_READY;
					end
			endcase
		end
	end
	
	// assign outputs
	assign awready_o = awready_y;
	assign wr_req_push_o = wr_req_push_y;
	assign wr_req_data_o = awaddr_i[1:0];
	
    /*=============================================================================================
    --  WRITE DATA CHANNEL FSM		-- Moore type
    --=============================================================================================*/
	reg 	wready_y;
	reg	wr_data_push_y;
	
	initial wready_y = 1;
	initial wr_data_push_y = 0;
	
	reg [1:0]
		wr_data_state;

	// Main FSM block
	always @ (posedge aclk_i)
	begin
		case (wr_data_state)
			// When IDLE:
			//		be ready to accept data -> wready HIGH
			//		don't touch the fifo		-> fifo_push LOW
			IDLE :
				begin
					wready_y <= 1;
					wr_data_push_y <= 0;
				end
				
			// When STORE_REQ:
			//		deassert ready 		-> wready LOW
			//		push data to FIFO		-> fifo_push HIGH
			STORE_REQ :
				begin
					wready_y <= 0;
					wr_data_push_y <= 1;
				end
				
			// When WAIT_READY:
			//		keep ready deasserted -> wready LOW
			//		don't touch the fifo	 -> fifo_push HIGH
			WAIT_READY :
				begin
					wready_y <= 0;
					wr_data_push_y <= 0;
				end
				
			// When default:
			//		Should never go into this state, it's only for full_case synthesis
			//		but if it does, keep everything LOW
			default :
				begin
					wready_y <= 0;
					wr_data_push_y <= 0;
				end
		endcase;
	end

	// Next state selector
	always @ (posedge aclk_i or negedge areset_n_i)
	begin
		if (!areset_n_i)
			wr_data_state <= IDLE;
		else
		begin
			case (wr_data_state)
				IDLE :
					begin
						if (wvalid_i & (!wr_data_full_i))
							wr_data_state <= STORE_REQ;
						else if (wvalid_i & wr_data_full_i)
							wr_data_state <= WAIT_READY;
						else
							wr_data_state <= IDLE;
					end
				STORE_REQ :
					begin
						wr_data_state <= IDLE;
					end
				WAIT_READY :
					begin
						if (wvalid_i & (!wr_data_full_i))
							wr_data_state <= STORE_REQ;
						else
							wr_data_state <= WAIT_READY;
					end
			endcase
		end
	end
	
	// assign output
	assign wready_o = wready_y;
	assign wr_data_push_o = wr_data_push_y;
	assign wr_data_data_o = {wdata_i, wstrb_i};
	
    /*=============================================================================================
    --  WRITE RESPONSE CHANNEL FSM			-- Moore type
    --=============================================================================================*/
	reg 	bvalid_y;
	reg	wr_resp_pull_y;
	
	initial bvalid_y = 0;
	initial wr_resp_pull_y = 0;
	
	reg [1:0]
		wr_resp_state;
	
	// Main FSM block
	always @ (posedge aclk_i)
	begin
		case (wr_resp_state)
			// When IDLE:
			//		no valid response 		-> bvalid LOW
			//		don't touch the fifo		-> fifo_pull LOW
			IDLE :
				begin
					bvalid_y <= 0;
					wr_resp_pull_y <= 0;
				end
		
			// When SEND_RESP:
			//		valid response present	-> bvalid HIGH
			//		pull data from FIFO		-> fifo_pull HIGH
			SEND_RESP :
				begin
					bvalid_y <= 1;
					wr_resp_pull_y <= 1;
				end
			WAIT_READY :
				begin
					bvalid_y <= 0;
					wr_resp_pull_y <= 0;
				end	
			// When default:
			//		Should never go into this state, it's only for full_case synthesis
			//		but if it does, keep everything LOW
			default :
				begin
					bvalid_y <= 0;
					wr_resp_pull_y <= 0;
				end
		endcase;
	end	
	
	always @ (posedge aclk_i or negedge areset_n_i)
	begin
		if (!areset_n_i)
			wr_resp_state <= IDLE;
		else
		begin
			case (wr_resp_state)
				IDLE :
					begin
						if (bready_i & (!wr_resp_empty_i))
							wr_resp_state <= SEND_RESP;
						else
							wr_resp_state <= IDLE;
					end
				SEND_RESP :
					begin
						wr_resp_state <= WAIT_READY;
					end
				WAIT_READY :
					begin
						wr_resp_state <= IDLE;
					end
			endcase;
		end
	end
	
	// assign output
	assign bvalid_o = bvalid_y;
	assign wr_resp_pull_o = wr_resp_pull_y;
	assign bresp_o = wr_resp_data_i;
	
    /*=============================================================================================
    --  READ ADDRESS CHANNEL FSM
    --=============================================================================================*/
	// Basically the same as the WRITE FSMs
	reg 	arready_y;
	reg	rd_req_push_y;
	
	initial arready_y = 1;
	initial rd_req_push_y = 0;
	
	reg [1:0]
		rd_req_state;
	
	always @ (posedge aclk_i)
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
	
		// Next state selector
	always @ (posedge aclk_i or negedge areset_n_i)
	begin
		if (!areset_n_i)
			rd_req_state <= IDLE;
		else
		begin
			case (rd_req_state)
				IDLE :
					begin
						if (arvalid_i & (!rd_req_full_i))
							rd_req_state <= STORE_REQ;
						else if (arvalid_i & rd_req_full_i)
							rd_req_state <= WAIT_READY;
						else
							rd_req_state <= IDLE;
					end
				STORE_REQ :
					begin
						rd_req_state <= IDLE;
					end
				WAIT_READY :
					begin
						if (arvalid_i & (!rd_req_full_i))
							rd_req_state <= STORE_REQ;
						else
							rd_req_state <= WAIT_READY;
					end
			endcase
		end
	end	
	
	assign arready_o = arready_y;
	assign rd_req_push_o = rd_req_push_y;
	assign rd_req_data_o = araddr_i[1:0];
	
	/*=============================================================================================
    --  READ DATA CHANNEL FSM
    --=============================================================================================*/
	reg 	rvalid_y;
	reg	rd_resp_pull_y;
	
	initial rvalid_y = 0;
	initial rd_resp_pull_y = 0;
	
	reg [1:0]
		rd_resp_state;
	
	always @ (posedge aclk_i)
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
			WAIT_READY :
				begin
					rvalid_y <= 0;
					rd_resp_pull_y <= 0;
				end
			default :	// Should never go into default state
				begin
					rvalid_y <= 0;
					rd_resp_pull_y <= 0;
				end
		endcase;
	end	
	
	always @ (posedge aclk_i or negedge areset_n_i)
	begin
		if (!areset_n_i)
			rd_resp_state <= IDLE;
		else
		begin
			case (rd_resp_state)
				IDLE :
					begin
						if (rready_i & (!rd_resp_empty_i))
							rd_resp_state <= SEND_RESP;
						else
							rd_resp_state <= IDLE;
					end
				SEND_RESP :
					begin
						rd_resp_state <= WAIT_READY;
					end
				WAIT_READY :
					begin
						rd_resp_state <= IDLE;
					end
			endcase;
		end
	end
	
	assign rvalid_o = rvalid_y;
	assign rd_resp_pull_o = rd_resp_pull_y;
	assign rdata_o = rd_resp_data_i[33:2];
	assign rresp_o = rd_resp_data_i[1:0];
	
endmodule