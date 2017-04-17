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

module axi_spi_if(

	/* Generic Parameters */
	parameter g_axi_data_width		= 32,						// Generic for AXI Data width
	parameter g_axi_addr_width		= 28,						// Generic for AXI Address width
	parameter g_cpol = 0;			// CPOL = clock polarity
	parameter g_cpha = 0;			// CPHA = clock phase.
	parameter g_prefetch = 2;		// prefetch lookahead cycles
	parameter g_clk_div = 5;		// CLK ratio between clk_i and sclk_i
	
	localparam c_log2_data_width   = clogb2(g_axi_data_width)
	localparam c_axi_resp_width = 2;
	localparam c_log2_data_width = clogb2(g_axi_data_width)	
	
	) (

	// Reset and Clocking
	input clk_i,								// high-speed system clock
	input rst_i,								// synchronous reset input
	
	//AXI4 interface
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
	output			[1:0]						rresp_o
	
	// SPI interface
    output spi_ssel_o,          				// spi bus slave select line
    output spi_sck_o,           				// spi bus sck
    output spi_mosi_o,          				// spi bus mosi output
    input spi_miso_i,     						// spi bus spi_miso_i input
	
)
	/*=============================================================================================
    --  Local parameters
    --=============================================================================================*/
	localparam c_wr_req_fifo_width = g_axi_addr_width;
	localparam c_wr_data_fifo_width = g_axi_data_width + c_log2_data_width;
	localparam c_wr_resp_fifo_width = c_axi_resp_width;
	localparam c_rd_req_fifo_width = g_axi_addr_width;
	localparam c_rd_resp_fifo_width = g_axi_data_width + c_axi_resp_width;

	/*=============================================================================================
    --  Internal signals
    --=============================================================================================*/
	wire [c_wr_req_fifo_width-1:0] wr_req_pushdata_y;
	wire wr_req_push_y;
	wire wr_req_pull_y;
	wire [c_wr_req_fifo_width-1:0] wr_req_pulldata_y;
	wire wr_req_full_y;
	wire wr_req_empty_y;
	
	wire [c_wr_data_fifo_width-1:0] wr_data_pushdata_y;
	wire wr_data_push_y;
	wire wr_data_pull_y;
	wire [c_wr_data_fifo_width-1:0] wr_data_pulldata_y;
	wire wr_data_full_y;
	wire wr_data_empty_y;
	
	wire [c_wr_resp_fifo_width-1:0] wr_resp_pushdata_y;
	wire wr_resp_push_y;
	wire wr_resp_pull_y;
	wire [c_wr_resp_fifo_width-1:0] wr_resp_pulldata_y;
	wire wr_resp_full_y;
	wire wr_resp_empty_y;
	
	wire [c_rd_req_fifo_width-1:0] rd_req_pushdata_y;
	wire rd_req_push_y;
	wire rd_req_pull_y;
	wire [c_rd_req_fifo_width-1:0] rd_req_pulldata_y;
	wire rd_req_full_y;
	wire rd_req_empty_y;
	
	wire [c_rd_resp_fifo_width-1:0] rd_resp_pushdata_y;
	wire rd_resp_push_y;
	wire rd_resp_pull_y;
	wire [c_rd_resp_fifo_width-1:0] rd_resp_pulldata_y;
	wire rd_resp_full_y;
	wire rd_resp_empty_y;
	
	
	/*=============================================================================================
    --  AXI4-Lite Slave instantiation
    --=============================================================================================*/
	axi4_lite_slv #(g_axi_data_width, g_axi_addr_width) axi_slave (
		.aclk_i(clk_i),
		.areset_n_i(rst_i),
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
		.rresp_o(rresp_o)
		.wr_req_full_i(wr_req_full_y),
		.wr_req_data_o(wr_req_pushdata_y),
		.wr_req_push_o(wr_req_push_y),
		.wr_data_full_i(wr_data_full_y),
		.wr_data_data_o(wr_data_pushdata_y),
		.wr_data_push_o(wr_data_push_y),
		.wr_resp_empty_i(wr_resp_empty_y),
		.wr_resp_data_i(wr_resp_pulldata_y),
		.wr_resp_pull_i(wr_resp_pull_y),
		.rd_req_full_i(rd_req_full_y),
		.rd_req_data_o(rd_req_pushdata_y),
		.rd_req_push_o(rd_req_push_y),
		.rd_resp_empty_i(rd_resp_empty_y),
		.rd_resp_data_i(rd_resp_pulldata_y),
		.rd_resp_pull_o(rd_resp_pull_y),
		);

		
	/*=============================================================================================
    --  FIFO Instantiations
    --=============================================================================================*/
	fifo #(c_wr_req_fifo_width, 1) 		wr_req_fifo(clk_i, rst_i, 	wr_req_pushdata_y, 	wr_req_push_y, 	wr_req_pull_y, 	wr_req_pulldata_y, 	wr_req_full_y, 	wr_req_empty_y);
	fifo #(c_wr_data_fifo_width, 1) 	wr_data_fifo(clk_i, rst_i, 	wr_data_pushdata_y, wr_data_push_y, wr_data_pull_y, wr_data_pulldata_y, wr_data_full_y, wr_data_empty_y);
	fifo #(c_wr_resp_fifo_width, 1) 	wr_resp_fifo(clk_i, rst_i, 	wr_resp_pushdata_y, wr_resp_push_y, wr_resp_pull_y, wr_resp_pulldata_y, wr_resp_full_y, wr_resp_empty_y);
	fifo #(c_rd_req_fifo_width, 1) 		rd_req_fifo(clk_i, rst_i, 	rd_req_pushdata_y, 	rd_req_push_y, 	rd_req_pull_y, 	rd_req_pulldata_y, 	rd_req_full_y, 	rd_req_empty_y);
	fifo #(c_rd_resp_fifo_width, 1) 	rd_resp_fifo(clk_i, rst_i, 	rd_resp_pushdata_y, rd_resp_push_y, rd_resp_pull_y, rd_resp_pulldata_y, rd_resp_full_y, rd_resp_empty_y);

	/*=============================================================================================
    --  FIFO2SPI Instantiations
    --=============================================================================================*/
	fifo2spi #() fifo2spi (); // TBD

	/*=============================================================================================
    --  SPI Master Instantiation
    --=============================================================================================*/
	spi_master #(g_word_length,g_cpol,g_cpha,g_prefetch,g_clk_div) sclk_gen( );// TBD

end module