/*---------------------------------------------------------------------------------------------------------------------
-- Author:          Peter Hasza, hasza.peti@gmail.com
-- 
-- Create Date:     04/02/2017 
-- Module Name:     regs_mod
-- Project Name:    AXI_SPI_IF
-- Description: 
--					Modole register instantiations
--
------------------------------ REVISION HISTORY -----------------------------------------------------------------------
--
-- 2017.apr.19	|	hp3265	||	Initial version
--
-----------------------------------------------------------------------------------------------------------------------*/

module regs_mod (

	/* System Clock & Reset */
	input											clk_i,						// System clock
	input											reset_n_i,					// System asynchronous reset
	
	/* Interface from System */
	input 										spi_busy_i,
	input											trans_start_i,
	input											rx_empty_i,
	input											tx_full_i,
	
	/* Interface towards APB Slave */
	output			[31:0]					reg_control_o,
	output			[31:0]					reg_trans_ctrl_o,
	output			[31:0]					reg_status_o,
	
	input			   [31:0]					reg_data_i,
	input											reg_load_i,
	input			   [1:0]						reg_sel_i
);
	
	/*=============================================================================================
	--  Control Register		|		R(h)W
	--=============================================================================================*/
	//   spi_clk_div	|	3:0		||		Clock ratio AXI / SPI 								|| reset value : 1
	//   reserved		|	7:4		||		default 0												|| reset value : 0
	//   data_order	|	8:8		||		1: MSB first, 0: LSB first							|| reset value : 0
	//	  CPOL  			|	9:9		||		1: SCLK HIGH in IDLE, 0: SCLK LOW in IDLE		|| reset value : 0
	//	  CPHA	 		|	10:10		||		1: Leading edge setup, Trailing edge sample 
	//												0: Leading edge sample, Trailing edge setup	|| reset value : 0
	//	  reserved		|	31:11		||		default 0												|| reset value : 0
	
	reg [11:0] axi_spi_ctrl_reg;
	
	always @ (posedge clk_i, negedge reset_n_i)
	begin
		if (!reset_n_i)
		begin
			axi_spi_ctrl_reg <= 32'd1;
		end
		else
			if (reg_load_i & (reg_sel_i == 2'b0))
			begin
				axi_spi_ctrl_reg[10:8] <= reg_data_i[10:8];
				axi_spi_ctrl_reg[3:0] <= reg_data_i[3:0];
			end
	end;
	
	assign reg_control_o = {21'd0, axi_spi_ctrl_reg};
	
	/*=============================================================================================
	--  Transfer Control Register	|	R(h)W
	--=============================================================================================*/
	//  slv_0_en		|	0:0		||		SS 0 enable		(0 disable, 1 enable)			|| reset value : 0
	//  slv_1_en		|	1:1		||		SS 1 enable		(0 disable, 1 enable)			|| reset value : 0
	//  slv_2_en		|	2:2		||		SS 2 enable		(0 disable, 1 enable)			|| reset value : 0
	//  slv_3_en		|	3:3		||		SS 3 enable		(0 disable, 1 enable)			|| reset value : 0
	//  reserved		|	4:4		||		default 0												|| reset value : 0	
	//  Bits per trans|	6:5		||		Num of bits per tranfer								|| reset value : 0
	//												00 - 8 default			
	//												01	- 16
	//												10 - 32
	//												11 - ignored		
	//	 reserved		|  12:7		|| 	default 0												|| reset value : 0
	//	 trans_start   |  13:13   	||    1: Transfer is ready to start, 0: IDLE			|| reset value : 0
	//	 reserved		|	31:14		||		default 0												|| reset value : 0
	
	reg [13:0] trans_ctrl_reg;
	
	always @ (posedge clk_i, negedge reset_n_i)
	begin
		if (!reset_n_i)
		begin
			trans_ctrl_reg <= 14'd0;
		end
		else
			if (trans_start_i)
			begin
				trans_ctrl_reg <= trans_ctrl_reg & 14'b01_1111_1111_1111;
			end
			else if (reg_load_i & (reg_sel_i == 2'b1))
			begin
				trans_ctrl_reg[3:0] <= reg_data_i[3:0];
				trans_ctrl_reg[6:5] <= reg_data_i[6:5];
				trans_ctrl_reg[13:13] <= reg_data_i[13:13];
			end
	end;
	
	assign reg_trans_ctrl_o = {18'd0, trans_ctrl_reg};

	/*=============================================================================================
	--  Status Register	|	Read Only
	--=============================================================================================*/
	//   spi_busy		|	0:0		||		Signals ongoing SPI transfer (0 idle, 1 busy)	|| reset value : 0
	//	  rx_fifo_empty|	1:1		||		SPI RD buffer empty at RD access						|| reset value : 0
	//   tx_fifo_full	|  2:2		||		SPI WR buffer full at WR access						|| reset value : 0
	//   reserved		|	31:3		||		default 0													|| reset value : 0   
	reg [2:0] status_reg;
	
	always @ (posedge clk_i, negedge reset_n_i)
	begin
		if (!reset_n_i)
		begin
			status_reg <= 0;
		end
		else
		begin
			status_reg[0] <= spi_busy_i;
			status_reg[1] <= rx_empty_i;
			status_reg[2] <= tx_full_i;
		end
	end;
	
	assign reg_status_o = {29'd0, status_reg};
	
endmodule