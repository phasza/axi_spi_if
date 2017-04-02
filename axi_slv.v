/*---------------------------------------------------------------------------------------------------------------------
-- Author:          Peter Hasza, hasza.peti@gmail.com
-- 
-- Create Date:     04/02/2017 
-- Module Name:     axi_slv
-- Project Name:    AXI_SPI_IF
-- Description: 
--					AXI4 Slave interface
--
------------------------------ REVISION HISTORY -----------------------------------------------------------------------
--
-- 2017.apr.2	|	hp3265	||	Initial version
--
-----------------------------------------------------------------------------------------------------------------------*/

module axi_slv(

	parameter g_axi_id_width	= 6, // The AXI id width used for R&W
                                             // This is an int between 1-16
	parameter g_axi_data_width	= 128,// Width of the AXI R&W data
	parameter g_axi_addr_width	= 28,	// AXI Address width
	parameter DW			= 32,	// Wishbone data width
	parameter AW			= 26,	// Wishbone address width
	) (
	input			clk_i,	// System clock
	input			rst_i,// Wishbone reset signal--unused

// AXI write address channel signals
	input				i_axi_awready, // Slave is ready to accept
	output	reg	[C_AXI_ID_WIDTH-1:0]	o_axi_awid,	// Write ID
	output	reg	[C_AXI_ADDR_WIDTH-1:0]	o_axi_awaddr,	// Write address
	output	wire	[7:0]		o_axi_awlen,	// Write Burst Length
	output	wire	[2:0]		o_axi_awsize,	// Write Burst size
	output	wire	[1:0]		o_axi_awburst,	// Write Burst type
	output	wire	[0:0]		o_axi_awlock,	// Write lock type
	output	wire	[3:0]		o_axi_awcache,	// Write Cache type
	output	wire	[2:0]		o_axi_awprot,	// Write Protection type
	output	wire	[3:0]		o_axi_awqos,	// Write Quality of Svc
	output	reg			o_axi_awvalid,	// Write address valid
  
// AXI write data channel signals
	input				i_axi_wready,  // Write data ready
	output	reg	[C_AXI_DATA_WIDTH-1:0]	o_axi_wdata,	// Write data
	output	reg	[C_AXI_DATA_WIDTH/8-1:0] o_axi_wstrb,	// Write strobes
	output	wire			o_axi_wlast,	// Last write transaction   
	output	reg			o_axi_wvalid,	// Write valid
  
// AXI write response channel signals
	input	[C_AXI_ID_WIDTH-1:0]	i_axi_bid,	// Response ID
	input	[1:0]			i_axi_bresp,	// Write response
	input				i_axi_bvalid,  // Write reponse valid
	output	wire			o_axi_bready,  // Response ready
  
// AXI read address channel signals
	input				i_axi_arready,	// Read address ready
	output	wire	[C_AXI_ID_WIDTH-1:0]	o_axi_arid,	// Read ID
	output	wire	[C_AXI_ADDR_WIDTH-1:0]	o_axi_araddr,	// Read address
	output	wire	[7:0]		o_axi_arlen,	// Read Burst Length
	output	wire	[2:0]		o_axi_arsize,	// Read Burst size
	output	wire	[1:0]		o_axi_arburst,	// Read Burst type
	output	wire	[0:0]		o_axi_arlock,	// Read lock type
	output	wire	[3:0]		o_axi_arcache,	// Read Cache type
	output	wire	[2:0]		o_axi_arprot,	// Read Protection type
	output	wire	[3:0]		o_axi_arqos,	// Read Protection type
	output	reg			o_axi_arvalid,	// Read address valid
  
// AXI read data channel signals   
	input	[C_AXI_ID_WIDTH-1:0]	i_axi_rid,     // Response ID
	input	[1:0]			i_axi_rresp,   // Read response
	input				i_axi_rvalid,  // Read reponse valid
	input	[C_AXI_DATA_WIDTH-1:0]	i_axi_rdata,    // Read data
	input				i_axi_rlast,    // Read last
	output	wire			o_axi_rready,  // Read Response ready

	// We'll share the clock and the reset
	input				i_wb_cyc,
	input				i_wb_stb,
	input				i_wb_we,
	input		[(AW-1):0]	i_wb_addr,
	input		[(DW-1):0]	i_wb_data,
	input		[(DW/8-1):0]	i_wb_sel,
	output	reg			o_wb_ack,
	output	wire			o_wb_stall,
	output	reg	[(DW-1):0]	o_wb_data,
	output	reg			o_wb_err
);
)

endmodule