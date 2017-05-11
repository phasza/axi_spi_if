`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   02:10:17 05/08/2017
// Design Name:   axi_spi_if
// Module Name:   D:/Projects/Rendszerarch/axi_spi_master_if/axi_spi/axi_spi_test.v
// Project Name:  axi_spi
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: axi_spi_if
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module axi_spi_test;

	// Inputs
	reg clk_i;
	reg reset_n_i;
	reg awvalid_i;
	reg [27:0] awaddr_i;
	reg awprot_i;
	reg wvalid_i;
	reg [31:0] wdata_i;
	reg [3:0] wstrb_i;
	reg bready_i;
	reg arvalid_i;
	reg [27:0] araddr_i;
	reg [2:0] arprot_i;
	reg rready_i;
	reg spi_miso_i;

	// Outputs
	wire awready_o;
	wire wready_o;
	wire bvalid_o;
	wire [1:0] bresp_o;
	wire arready_o;
	wire rvalid_o;
	wire [31:0] rdata_o;
	wire [1:0] rresp_o;
	wire [3:0] spi_ssel_o;
	wire spi_sck_o;
	wire spi_mosi_o;

	// Instantiate the Unit Under Test (UUT)
	axi_spi_if uut (
		.clk_i(clk_i), 
		.reset_n_i(reset_n_i), 
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
		.spi_ssel_o(spi_ssel_o), 
		.spi_sck_o(spi_sck_o), 
		.spi_mosi_o(spi_mosi_o), 
		.spi_miso_i(spi_miso_i)
	);
	
	initial begin
		// Initialize Inputs
		clk_i = 0;
		reset_n_i = 0;
		awvalid_i = 0;
		awaddr_i = 0;
		awprot_i = 0;
		wvalid_i = 0;
		wdata_i = 0;
		wstrb_i = 0;
		bready_i = 0;
		arvalid_i = 0;
		araddr_i = 0;
		arprot_i = 0;
		rready_i = 0;
		spi_miso_i = 0;

		// Wait 100 ns for global reset to finish
		#100;
		// Add stimulus here
      reset_n_i = 1;
		spi_miso_i = 1;
		bready_i = 1;
		rready_i = 1;
		/*		
		reg_control_i = 32'h0000_0602;
		reg_trans_ctrl_i = 32'h0000_0002;
		*/
		
		
		 wdata_i = 32'h0000_0602;
		 awaddr_i = 0;
		 awvalid_i = 1;
		 wvalid_i = 1;
		 wait(awready_o && wready_o);

		 @(posedge clk_i) #1;
		 awvalid_i = 0;
		 wvalid_i = 0;
		 
		 #1000;
		 
		 wdata_i = 32'h0000_0002;
		 awaddr_i = 1;
		 awvalid_i = 1;
		 wvalid_i = 1;
		 wait(awready_o && wready_o);

		 @(posedge clk_i) #1;
		 awvalid_i = 0;
		 wvalid_i = 0;
		 
		 #100;
		 
		 wdata_i = 32'h0000_0073;
		 awaddr_i = 3;
		 awvalid_i = 1;
		 wvalid_i = 1;
		 wait(awready_o && wready_o);

		 @(posedge clk_i) #1;
		 awvalid_i = 0;
		 wvalid_i = 0;
		 
		 #100;
		  wdata_i = 32'h0000_0073;
		 awaddr_i = 4;
		 awvalid_i = 1;
		 wvalid_i = 1;
		 wait(awready_o && wready_o);

		 @(posedge clk_i) #1;
		 awvalid_i = 0;
		 wvalid_i = 0;
		 
		 #100;
		 
		 
	end
	
		always #5 clk_i = ~clk_i;
      
endmodule

