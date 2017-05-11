`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   22:44:56 05/08/2017
// Design Name:   fifo
// Module Name:   E:/University/AXI_SPI_IF/rtl/fifo_test_full.v
// Project Name:  axi_spi_if
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: fifo
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module fifo_test_full;

	// Inputs
	reg clk_i;
	reg rst_i;
	reg [31:0] data_i;
	reg push_i;
	reg pull_i;

	// Outputs
	wire [31:0] data_o;
	wire full_o;
	wire empty_o;

	// Instantiate the Unit Under Test (UUT)
	fifo1 uut (
		.clk_i(clk_i), 
		.rst_i(rst_i), 
		.data_i(data_i), 
		.push_i(push_i), 
		.pull_i(pull_i), 
		.data_o(data_o), 
		.full_o(full_o), 
		.empty_o(empty_o)
	);

	initial begin
		// Initialize Inputs
		clk_i = 0;
		rst_i = 0;
		data_i = 3;
		push_i = 0;
		pull_i = 0;

		#10;
		rst_i = 1;

		// Wait 100 ns for global reset to finish
		#20;
		push_i = 1;
		
		#10;
		push_i = 0;
		
		#20;
		pull_i = 1;
		
		#10;
		pull_i = 0;
		
		#20;
		pull_i = 1;
		
		#10;
		pull_i = 0;
		
		#100;
		data_i = 5;
		push_i = 1;
		
		#10;
		push_i = 0;
		data_i = 9;
		#20;
		push_i = 1;
		
		#10;
		push_i = 0;
		
	end
      
		always #5 clk_i = ~clk_i;
		
endmodule

