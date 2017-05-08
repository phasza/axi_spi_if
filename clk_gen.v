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