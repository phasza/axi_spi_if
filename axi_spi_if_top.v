/*---------------------------------------------------------------------------------------------------------------------
-- Author:          Peter Hasza, hasza.peti@gmail.com
-- 
-- Create Date:     04/02/2017 
-- Module Name:     axi_spi_if
-- Project Name:    AXI_SPI_IF
-- Description: 
--					Top level of AXI_SPI_IF project.
--
------------------------------ REVISION HISTORY -----------------------------------------------------------------------
--
-- 2017.apr.2	|	hp3265	||	Initial version
--
-----------------------------------------------------------------------------------------------------------------------*/

module axi_spi_if(

	// Reset and Clocking
	input clk_i,								// high-speed system clock
	input rst_i,								// synchronous reset input
	
	
	//AXI4 interface
	// TBD
	
	// SPI interface
    output spi_ssel_o,          				// spi bus slave select line
    output spi_sck_o,           				// spi bus sck
    output spi_mosi_o,          				// spi bus mosi output
    input spi_miso_i,     						// spi bus spi_miso_i input
	
)

parameter g_word_length = 32;	// 32bit serial word length is default
parameter g_cpol = 0;			// CPOL = clock polarity
parameter g_cpha = 0;			// CPHA = clock phase.
parameter g_prefetch = 2;		// prefetch lookahead cycles
parameter g_clk_div = 5;		// CLK ratio between clk_i and sclk_i

spi_master #(g_word_length,g_cpol,g_cpha,g_prefetch,g_clk_div) sclk_gen( );// TDB

fifo #() rd_ctrl_fifo();
fifo #() wr_ctrl_fifo();
fifo #() rd_ctrl_fifo();
fifo #() rd_ctrl_fifo();

end module