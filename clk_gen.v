/*---------------------------------------------------------------------------------------------------------------------
-- Author:          Peter Hasza, hasza.peti@gmail.com
-- 
-- Create Date:     04/23/2017 
-- Module Name:     CLK_gen
-- Project Name:    AXI_SPI_IF
-- Description: 
--
------------------------------ REVISION HISTORY -----------------------------------------------------------------------
--
-- 2017.apr.2	|	hp3265	||	Initial version
--
-----------------------------------------------------------------------------------------------------------------------
-- TODO
--  ====
--
-----------------------------------------------------------------------------------------------------------------------*/
`include "utils.v"
/*
module CLK_gen (
	input 			clk_i,
	input				reset_n_i,
	input [7:0]		clk_div_i,
	output 			clk_o
);
	
	reg [7:0] clk_cnt_y;
	wire [7:0] clk_cnt_next_y;
	reg clk_en_y;
	
	always @(posedge clk_i or negedge reset_n_i)
	begin
		if (!reset_n_i)
			clk_cnt_y <= 0;
		else
		begin
			if (clk_cnt_y == clk_div_i)
			begin
				clk_cnt_y <= 0;
				clk_en_y <= ~clk_en_y;
			end
			else
				clk_cnt_y <= clk_cnt_next_y;
		end
	end
	
	`TRUNC(trunc_signal, 8, 7);
	assign clk_cnt_next_y = trunc_signal(clk_cnt_y + 1);
	 	      
	assign clk_o = clk_en_y;

endmodule*/

module CLK_gen (
	input 			clk_i,
	input				reset_n_i,
	input				clk_en,
	input [3:0]		clk_div_i,
	output 			clk_o
);
	    
	reg clk_y;
	reg [3:0] clk_cnt_y;
	
	always@(posedge clk_i,negedge reset_n_i)
	begin
		if (!reset_n_i)
		begin
			clk_cnt_y <= 0;
			clk_y <= 0;
		end
		else if(clk_en)
		begin
			if(clk_cnt_y == clk_div_i-1)
			begin
				clk_y <= ~clk_y; 
				clk_cnt_y <= 0;
			end
			else 
				clk_cnt_y <= clk_cnt_y +1;
		end
		else
			clk_y <= 0;
	end
	
	assign clk_o = (clk_div_i==0) ? clk_i : clk_y;

endmodule
