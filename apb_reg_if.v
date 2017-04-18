/*---------------------------------------------------------------------------------------------------------------------
-- Author:          Peter Hasza, hasza.peti@gmail.com
-- 
-- Create Date:     04/02/2017 
-- Module Name:     apb_reg_if
-- Project Name:    AXI_SPI_IF
-- Description: 
--					APB Slave module for register interface
--
------------------------------ REVISION HISTORY -----------------------------------------------------------------------
--
-- 2017.apr.18	|	hp3265	||	Initial version
--
-----------------------------------------------------------------------------------------------------------------------*/

module apb_reg_if (

	/* Generic Parameters */
	parameter g_apb_addr_width		= 32,
	parameter g_apb_data_width		= 32,
	
	localparam c_log2_data_width   = clogb2(g_apb_data_width)
	
	) (
	
	/* System Clock and Reset */
	input			pclk_i,										// System clock
	input			preset_n_i,									// System asynchronous reset
	
	/* APB Bridge signals */
	input 			[g_apb_addr_width-1:0] 		paddr_i,
	input			[2:0]						pprot_i,
	input										psel_i,
	input										penable_i,
	input										pwrite_i,
	input			[g_apb_data_width-1:0]		pwdata_i,
	input			[c_log2_data_width-1:0]		pstrb_i,
	
	/* APB Slave interface signals */
	output										pready_o,
	output			[g_apb_data_width-1:0]		prdata_o,
	output										pslverr_o

);

endmodule;