/*---------------------------------------------------------------------------------------------------------------------
-- Author:          Peter Hasza, hasza.peti@gmail.com
-- 
-- Create Date:     04/02/2017 
-- Module Name:     axi_spi_if
-- Project Name:    AXI_SPI_IF
-- Description: 
--					Top level of AXI_SPI_IF project.
--
------------------------------ REVISION HISTORY -----------------------------------------------------------------------
--
-- 2017.apr.2	|	hp3265	||	Initial version
--
-----------------------------------------------------------------------------------------------------------------------*/

module axi_spi_if #(

	//=============================================================================================
	/* Generic Parameters */
	parameter g_axi_addr_width		= 28,						// Generic for AXI Address width
	parameter g_tx_fifo_depth		= 8,						// Generic for Transmit FIFO depth
	parameter g_rx_fifo_depth		= 8						// Generic for Receive FIFO depth
	) (

	//=============================================================================================
	// Reset and Clocking
	input clk_i,								// Main system clock (AXI and Core clock)
	input reset_n_i,						    // System asycnhronous reset
	
	//=============================================================================================
	//AXI4 interface
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
	
	//=============================================================================================
	// SPI interface
    output [3:0]								spi_ssel_o,
    output 										spi_sck_o,
    output 										spi_mosi_o,
    input 										spi_miso_i
	
);

	/*=============================================================================================
    --  Internal signals
    --=============================================================================================*/
	wire [31:0] 			reg_data_y;
	wire 						reg_load_y;
	wire [1:0]				reg_sel_y;
	
	wire [31:0] 			reg_control_y;
	wire [31:0] 			reg_trans_ctrl_y;
	wire [31:0] 			reg_status_y;
	
	wire 						spi_busy_y;
	
	wire [1:0] 				wr_req_pushdata_y;
	wire 						wr_req_push_y;
	wire 						wr_req_pull_y;
	wire [1:0] 				wr_req_pulldata_y;
	wire 						wr_req_full_y;
	wire 						wr_req_empty_y;
	
	wire [35:0] 			wr_data_pushdata_y;
	wire 						wr_data_push_y;
	wire 						wr_data_pull_y;
	wire [35:0]		 		wr_data_pulldata_y;
	wire 						wr_data_full_y;
	wire	 					wr_data_empty_y;
	
	wire [1:0]	 			wr_resp_pushdata_y;
	wire 						wr_resp_push_y;
	wire 						wr_resp_pull_y;
	wire [1:0]	 			wr_resp_pulldata_y;
	wire 						wr_resp_full_y;
	wire 						wr_resp_empty_y;
	
	wire [1:0] 				rd_req_pushdata_y;
	wire 						rd_req_push_y;
	wire 						rd_req_pull_y;
	wire [1:0] 				rd_req_pulldata_y;
	wire 						rd_req_full_y;
	wire 						rd_req_empty_y;
	
	wire [33:0] 			rd_resp_pushdata_y;
	wire 						rd_resp_push_y;
	wire 						rd_resp_pull_y;
	wire [33:0] 			rd_resp_pulldata_y;
	wire 						rd_resp_full_y;
	wire 						rd_resp_empty_y;
	
	wire [31:0] 			tx_pushdata_y;
	wire 						tx_push_y;
	wire 						tx_pull_y;
	wire [31:0] 			tx_pulldata_y;
	wire 						tx_full_y;
	wire 						tx_empty_y;
	
	wire [31:0] 			rx_pushdata_y;
	wire 						rx_push_y;
	wire 						rx_pull_y;
	wire [31:0] 			rx_pulldata_y;
	wire 						rx_full_y;
	wire 						rx_empty_y;
	
	/*=============================================================================================
    --  AXI4-Lite Slave instantiation
    --=============================================================================================*/
	axi4_lite_slv #(g_axi_addr_width) axi_slave (
		.aclk_i(clk_i),
		.areset_n_i(reset_n_i),
		.awvalid_i(awvalid_i),
		.awready_o(awready_o),
		.awaddr_i(awaddr_i),
		.awprot_i(awprot_i),
		.wvalid_i(wvalid_i),
		.wready_o(wready_o),
		.wdata_i(wdata_i),
		.wstrb_i(wstrb_i),
		.bvalid_o(bvalid_o),
		.bready_i(bready_i),
		.bresp_o(bresp_o),
		.arvalid_i(arvalid_i),
		.arready_o(arready_o),
		.araddr_i(araddr_i),
		.arprot_i(arprot_i),
		.rvalid_o(rvalid_o),
		.rready_i(rready_i),
		.rdata_o(rdata_o),
		.rresp_o(rresp_o),
		.wr_req_full_i(wr_req_full_y),
		.wr_req_data_o(wr_req_pushdata_y),
		.wr_req_push_o(wr_req_push_y),
		.wr_data_full_i(wr_data_full_y),
		.wr_data_data_o(wr_data_pushdata_y),
		.wr_data_push_o(wr_data_push_y),
		.wr_resp_empty_i(wr_resp_empty_y),
		.wr_resp_data_i(wr_resp_pulldata_y),
		.wr_resp_pull_o(wr_resp_pull_y),
		.rd_req_full_i(rd_req_full_y),
		.rd_req_data_o(rd_req_pushdata_y),
		.rd_req_push_o(rd_req_push_y),
		.rd_resp_empty_i(rd_resp_empty_y),
		.rd_resp_data_i(rd_resp_pulldata_y),
		.rd_resp_pull_o(rd_resp_pull_y)
		);
	
	/*=============================================================================================
    --  FIFO Instantiations
    --=============================================================================================*/
	fifo #(2, 1) wr_req_fifo(
		.clk_i(clk_i), 
		.rst_i(reset_n_i), 	
		.data_i(wr_req_pushdata_y), 	
		.push_i(wr_req_push_y), 	
		.pull_i(wr_req_pull_y), 	
		.data_o(wr_req_pulldata_y), 	
		.full_o(wr_req_full_y), 	
		.empty_o(wr_req_empty_y)
		);
		
	fifo #(36, 1) wr_data_fifo(
		.clk_i(clk_i), 
		.rst_i(reset_n_i), 	
		.data_i(wr_data_pushdata_y), 	
		.push_i(wr_data_push_y), 	
		.pull_i(wr_data_pull_y), 	
		.data_o(wr_data_pulldata_y), 	
		.full_o(wr_data_full_y), 	
		.empty_o(wr_data_empty_y)
		);
	
	fifo #(2, 1) wr_resp_fifo(
		.clk_i(clk_i), 
		.rst_i(reset_n_i), 	
		.data_i(wr_resp_pushdata_y), 	
		.push_i(wr_resp_push_y), 	
		.pull_i(wr_resp_pull_y), 	
		.data_o(wr_resp_pulldata_y), 	
		.full_o(wr_resp_full_y), 	
		.empty_o(wr_resp_empty_y)
		);
	
	fifo #(2, 1) rd_req_fifo(
		.clk_i(clk_i), 
		.rst_i(reset_n_i), 	
		.data_i(rd_req_pushdata_y), 	
		.push_i(rd_req_push_y), 	
		.pull_i(rd_req_pull_y), 	
		.data_o(rd_req_pulldata_y), 	
		.full_o(rd_req_full_y), 	
		.empty_o(rd_req_empty_y)
		);
	
	fifo #(34, 1) rd_resp_fifo(
		.clk_i(clk_i), 
		.rst_i(reset_n_i), 	
		.data_i(rd_resp_pushdata_y), 	
		.push_i(rd_resp_push_y), 	
		.pull_i(rd_resp_pull_y), 	
		.data_o(rd_resp_pulldata_y), 	
		.full_o(rd_resp_full_y), 	
		.empty_o(rd_resp_empty_y)
		);
		
	fifo #(32, g_tx_fifo_depth) tx_fifo(
		.clk_i(clk_i), 
		.rst_i(reset_n_i), 	
		.data_i(tx_pushdata_y), 	
		.push_i(tx_push_y), 	
		.pull_i(tx_pull_y), 	
		.data_o(tx_pulldata_y), 	
		.full_o(tx_full_y), 	
		.empty_o(tx_empty_y)
		);
		
	fifo #(32, g_rx_fifo_depth) rx_fifo(
		.clk_i(clk_i), 
		.rst_i(reset_n_i), 	
		.data_i(rx_pushdata_y), 	
		.push_i(rx_push_y), 	
		.pull_i(rx_pull_y), 	
		.data_o(rx_pulldata_y), 	
		.full_o(rx_full_y), 	
		.empty_o(rx_empty_y)
		);

	/*=============================================================================================
    --  FIFO2SPI Instantiations
    --=============================================================================================*/

	
	
	fifo2spi fifo_2_spi (
		.clk_i(clk_i),
		.reset_n_i(reset_n_i),
		.reg_control_i(reg_control_y),
		.reg_trans_ctrl_i(reg_trans_ctrl_y),
		.reg_status_i(reg_status_y),
		.spi_busy_o(spi_busy_y),
		.reg_data_o(reg_data_y),
		.reg_load_o(reg_load_y),
		.reg_sel_o(reg_sel_y),
		.wr_req_empty_i(wr_req_empty_y),
		.wr_req_data_i(wr_req_pulldata_y),
		.wr_req_pull_o(wr_req_pull_y),
		.wr_data_empty_i(wr_data_empty_y),
		.wr_data_data_i(wr_data_pulldata_y),
		.wr_data_pull_o(wr_data_pull_y),
		.wr_resp_full_i(wr_resp_full_y),
		.wr_resp_data_o(wr_resp_pushdata_y),
		.wr_resp_push_o(wr_resp_push_y),
		.rd_req_empty_i(rd_req_empty_y),
		.rd_req_data_i(rd_req_pulldata_y),
		.rd_req_pull_o(rd_req_pull_y),
		.rd_resp_full_i(rd_resp_full_y),
		.rd_resp_data_o(rd_resp_pushdata_y),
		.rd_resp_push_o(rd_resp_push_y),
		.tx_full_i(tx_full_y),
		.tx_data_o(tx_pushdata_y),
		.tx_push_o(tx_push_y),
		.rx_empty_i(rx_empty_y),
		.rx_data_i(rx_pulldata_y),
		.rx_pull_o(rx_pull_y),
		.trans_done_i(trans_done_y),
		.trans_start_o(trans_start_y)
	);
		
	/*=============================================================================================
    --  Register file instantiation
    --=============================================================================================*/
	regs_mod registers (
		.clk_i(clk_i),
		.reset_n_i(reset_n_i),
		.spi_busy_i(spi_busy_y),
		.trans_start_i(trans_start_y),
		.rx_empty_i(rx_empty_y),
		.tx_full_i(tx_full_y),
		.reg_control_o(reg_control_y),
		.reg_trans_ctrl_o(reg_trans_ctrl_y),
		.reg_status_o(reg_status_y),
		.reg_data_i(reg_data_y),
		.reg_load_i(reg_load_y),
		.reg_sel_i(reg_sel_y)
		);

	/*=============================================================================================
    --  SPI Master Instantiation
    --=============================================================================================*/
	spi_master SPI_if(
		.clk_i(clk_i),
		.reset_n_i(reset_n_i),
		.reg_control_i(reg_control_y),
		.reg_trans_ctrl_i(reg_trans_ctrl_y),
		.trans_done_o(trans_done_y),
		.trans_start_i(trans_start_y),
		.tx_empty_i(tx_empty_y),
		.tx_data_i(tx_pulldata_y),
		.tx_pull_o(tx_pull_y),
		.rx_full_i(rx_full_y),
		.rx_data_o(rx_pushdata_y),
		.rx_push_o(rx_push_y),	
		.spi_ssel_o(spi_ssel_o),
		.spi_sck_o(spi_sck_o),
		.spi_mosi_o(spi_mosi_o),
		.spi_miso_i(spi_miso_i)
	);

endmodule