`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   07:22:37 05/11/2017
// Design Name:   axi_spi_if
// Module Name:   E:/University/AXI_SPI_IF/ise/axi_spi_test_transfer.v
// Project Name:  axi_spi_if
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

module axi_spi_transfer_test;

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
	
	reg [2:0] read_status_reg;

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
	integer i;
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
		.spi_miso_i(spi_mosi_o)
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
		read_status_reg = 7;
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
		 // ===========================================
		 // WRITE CONTROL REGISTER
		 // ===========================================
		 wdata_i = 32'h0000_0102;
		 awaddr_i = 0;
		 awvalid_i = 1;
		 wvalid_i = 1;
		 wait(awready_o && wready_o);

		 @(posedge clk_i) #1;
		 awvalid_i = 0;
		 wvalid_i = 0;
		 
		 #100;
		 
		 // ===========================================
		 // WRITE TX FIFO
		 // ===========================================
		 
		 for (i=0; i < 8; i = i + 1) begin
			wdata_i = 32'd1 + i;
			awaddr_i = 3;
			awvalid_i = 1;
			wvalid_i = 1;
			wait(awready_o && wready_o);

			@(posedge clk_i) #1;
			awvalid_i = 0;
			wvalid_i = 0;
			
			#100;
		end
		
		 // ===========================================
		 // WRITE TRANSFER CONTROL REGISTER
		 // ===========================================
		 wdata_i = 32'h0000_2002;
		 awaddr_i = 1;
		 awvalid_i = 1;
		 wvalid_i = 1;
		 wait(awready_o && wready_o);

		 @(posedge clk_i) #1;
		 awvalid_i = 0;
		 wvalid_i = 0;
		 
		 spi_miso_i = 1;
		 
		 
		 
		 // ===========================================
		 // READ STATUS REGISTER
		 // ===========================================
		 
		 araddr_i = 2;
		 arvalid_i = 1;
		 wait(arready_o);
			
		 @(posedge clk_i) #1;
		 arvalid_i = 0;	
		 
		 #100;
		 
		 while (rdata_o) begin
			araddr_i = 2;
			arvalid_i = 1;
			wait(arready_o);
			
			@(posedge clk_i) #1;
			arvalid_i = 0;	
		 
			#100;
		end

		#500; 
		 // ===========================================
		 // READ RX FIFO
		 // ===========================================
		 
		 for (i=0; i < 8; i = i + 1) begin
			araddr_i = 3;
			arvalid_i = 1;
			wait(arready_o);

			@(posedge clk_i) #1;
			arvalid_i = 0;
			
			#100;
		end
	end
	
		always #77 spi_miso_i = ~spi_miso_i;	
	
		always #5 clk_i = ~clk_i;
      
endmodule