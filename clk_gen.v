module CLK_gen(

	input clk_i,	// Fast system clock
	output clk_o	// Desired clock
);

	parameter g_clk_div;
	
	reg [] clk_cnt_y = 0;
	
	always @(posedge clk_i)
		if (clk_cnt_y == g_clk_div)
		clk_cnt_y <= clk_cnt_y + 1;

end module;