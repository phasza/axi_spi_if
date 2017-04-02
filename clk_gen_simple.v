/*---------------------------------------------------------------------------------------------------------------------
-- Author:          Peter Hasza, hasza.peti@gmail.com
-- 
-- Create Date:     04/02/2017 
-- Module Name:     CLK_gen_simple
-- Project Name:    AXI_SPI_IF
-- Description: 
--					Simple Clock generator module. The purpose of a less resourceful implementation of the SPI interface
--					SCLK generation in case of modulo 2 clock ratio.
--					The use case clock ratios:
--						- clk_div 2,4,8
--					But the module can handle any modulo 2 clock ratios.
--
------------------------------ REVISION HISTORY -----------------------------------------------------------------------
--
-- 2017.apr.2	|	hp3265	||	Initial version
--
-----------------------------------------------------------------------------------------------------------------------*/

module CLK_gen_simple(

	input clk_i,
	output clk_o
);

	parameter g_clk_div;
	localparam c_counter_width = clog2(g_clk_div); 
	
	reg [c_counter_width:0] clk_cnt_y = 0;
	
	always @(posedge clk_i)
		clk_cnt_y <= clk_cnt_y + 1;

	assign clk_o = clk_cnt_y[c_counter_width];

end module;