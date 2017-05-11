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
`include "utils.v"

module fifo(
	input clk_i, 
	input rst_i, 
	input [g_width-1:0] data_i, 
	input push_i,
	input pull_i,
	output [g_width-1:0] data_o, 
	output full_o, 
	output empty_o
);

	parameter g_width = 32;
	parameter g_depth = 1;

	`CLOGB2(clogb2);
	localparam c_ptr_width = clogb2(g_depth);


	/*=============================================================================================
	--  Locals
	--=============================================================================================*/
	reg     [g_width-1:0]		mem[0:g_depth-1];
	reg     [c_ptr_width-1:0]   	wr_ptr, rd_ptr;
	wire    [c_ptr_width-1:0]   	wr_ptr_next, rd_ptr_next;
	reg							gb;

	integer k;
	initial 	
	begin 
		for (k = 0; k < g_depth ; k = k + 1) 
		begin 
			mem[k] = 32'h0000_0000; 
		end 
	end
	/*=============================================================================================
	--  Pointer settting
	--=============================================================================================*/
	always @(posedge clk_i, negedge rst_i)
        if(!rst_i)	wr_ptr <= 0;
        else if(push_i)  wr_ptr <= wr_ptr_next;

		
	always @(posedge clk_i, negedge rst_i)
        if(!rst_i)	rd_ptr <= 0;
        else if(pull_i)	rd_ptr <= rd_ptr_next;
	
	`TRUNC(trunc_signal, c_ptr_width + 1, c_ptr_width);
	assign wr_ptr_next = trunc_signal(wr_ptr + 1);
	assign rd_ptr_next = trunc_signal(rd_ptr + 1);

	// Fifo Output
	assign  data_o = mem[ rd_ptr ];

	// Fifo Input
	always @(posedge clk_i)
        if(push_i)	mem[ wr_ptr ] <= data_i;

	// Status
	assign empty_o = (wr_ptr == rd_ptr) & !gb;
	assign full_o  = (wr_ptr == rd_ptr) &  gb;

	// Guard Bit ...
	always @(posedge clk_i, negedge rst_i)
		if(!rst_i)											gb <= 0;
		else if((wr_ptr_next == rd_ptr) & push_i)	gb <= 1;
		else if(pull_i)					    			gb <= 0;
		
	
endmodule
