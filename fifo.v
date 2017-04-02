/*---------------------------------------------------------------------------------------------------------------------
-- Author:          Peter Hasza, hasza.peti@gmail.com
-- 
-- Create Date:     04/02/2017 
-- Module Name:     fifo
-- Project Name:    AXI_SPI_IF
-- Description: 
--					Generic fifo module
--
------------------------------ REVISION HISTORY -----------------------------------------------------------------------
--
-- 2017.apr.2	|	hp3265	||	Initial version
--
-----------------------------------------------------------------------------------------------------------------------*/

module fifo(
	input clk_i, 
	input rst_i, 
	input clr_i,  
	input [g_width-1:0] data_i, 
	input push_i,
	input pull_i
	output [g_width-1:0] data_o, 
	output full_o, 
	output empty_o
);

	parameter g_depth = 1;
	parameter g_width = 32;

	localparam c_ptr_width = clog2(g_depth);


	/*=============================================================================================
	--  Locals
	--=============================================================================================*/

	reg     [g_width-1:0]		mem[0:g_depth-1];
	reg     [c_ptr_width:0]   	wr_ptr, rd_ptr;
	reg     [c_ptr_width:0]   	wr_ptr_next, rd_ptr_next;
	reg							gb;

	/*=============================================================================================
	--  Pointer settting
	--=============================================================================================*/
	always @(posedge clk_i)
        if(rst_i)	wr_ptr <= 0;
        else if(clr_i) wr_ptr <= 0;
        else if(push_i)  wr_ptr <= wr_ptr_next;

		
	always @(posedge clk_i)
        if(rst_i)	rd_ptr <= 0;
        else if(clr_i)	rd_ptr <= 0;
        else if(pull_i)	rd_ptr <= rd_ptr_next;
		
	assign wr_ptr_next <= wr_ptr + 1;
	assign rd_ptr_next <= rd_ptr + 1;

	// Fifo Output
	assign  data_o = mem[ rd_ptr ];

	// Fifo Input
	always @(posedge clk_i)
        if(push_i)	mem[ wr_ptr ] <= data_i;

	// Status
	assign empty_o = (wr_ptr == rd_ptr) & !gb;
	assign full_o  = (wr_ptr == rd_ptr) &  gb;

	// Guard Bit ...
	always @(posedge clk_i)
		if(rst_i)							gb <= 0;
		else if(clr_i) 						gb <= 0;
		else if((wr_ptr_next == rp) & we)	gb <= 1;
		else if(pull_i)					    gb <= 0;

endmodule
