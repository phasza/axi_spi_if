/*---------------------------------------------------------------------------------------------------------------------
-- Author:          Peter Hasza, hasza.peti@gmail.com
-- 
-- Create Date:     04/02/2017 
-- Module Name:     spi_master
-- Project Name:    AXI_SPI_IF
-- Description: 
--							A simple SPI master interface.
--								Device control informations are coming from the Control Register.
--								These are the following:
--										- CLK ratio between the system clock and the SCLK
--										- Clock polarity
--										- Clock phase
--										- Data order
--
--								Information regarding the current SPI transfer is coming from the Transfer Control Register.
--								These are the following:
--										-- SS (Slave Select)
--										-- Direction
--										--	Number of bytes
--										-- Transfer start
--
--								An SPI transfer is only started when there is a HIGH pulse on the trans_start_i.
--								The controller will assert the trans_done_o, once the current transfer is done.
--								The data to be transmitted is acquired in the TX FIFO.
--								The received data is loaded into the RX FIFO.
--
--								A WRITE transfer is done once, the TX FIFO is empty.
--								The controller stalls the bus if the RX FIFO is full.
--
------------------------------ REVISION HISTORY -----------------------------------------------------------------------
--
-- 2017.apr.2	|	hp3265	||	Initial version
-- 2017.apr.20	|	hp3265	||	Clock generation, CPOl and CPHA assignment
-- 2017.apr.23	|	hp3265	||	FSM enable signals
-----------------------------------------------------------------------------------------------------------------------
-- TODO
-- * Finish the FSM for the transfers
-- * Generate trans_done_o
-- * Control FIFO outputs
-- * Testing, commenting, clean up
-- * QSPI / SPI mode
-----------------------------------------------------------------------------------------------------------------------*/

module spi_master (

		// Reset and Clocking
		input clk_i,
		input reset_n_i,
		
		/* Register interface */
		input	[31:0]								reg_control_i,
		input	[31:0]								reg_trans_ctrl_i,
		
		// FIFO2SPI interface
		output										trans_done_o,
		input											trans_start_i,
		
		// TX FIFO
		input											tx_empty_i,
		input	[31:0]								tx_data_i,
		output										tx_pull_o,
		
		// RX FIFO
		input											rx_full_i,
		output [31:0]								rx_data_o,
		output										rx_push_o,		

		// Serial interface
      output [3:0]								spi_ssel_o,
      output 										spi_sck_o,
      output 										spi_mosi_o,
      input 										spi_miso_i

	);
	
	/*=============================================================================================
    --  CLOCK GENERATION
    --=============================================================================================*/
	wire spi_sclk_y;
	wire sclk_y;
	wire [7:0] clk_div_y;
	wire cpol_y;
	
	assign clk_div_y = reg_control_i[7:0];
	assign cpol_y = reg_control_i[9];
	
	CLK_gen sclk_gen(clk_i, reset_n_i, clk_div_y, sclk_y);
	
	assign spi_sclk_y = (!cpol_y) ? sclk_y : ~sclk_y;
	
	reg prev_sclk_y;
	always @(posedge clk_i) prev_sclk_y <= sclk_y;
	
	reg sclk_rise_y;
	always @(posedge clk_i) 
	begin
		if (!prev_sclk_y & sclk_y) // rising edge of SCLK
			sclk_rise_y <= 1;
		else
			sclk_rise_y <= 0;
	end;
	

    /*=============================================================================================
    -- Sampling clock enable generation: generate 'samp_ce_y' from 'clk_en_y' depending on CPHA
    -- always sample data at the half-cycle of the fsm update cell
	 --=============================================================================================*/
	wire samp_ce_y;
	wire fsm_ce_y;
	wire cpha_y;
	
	assign cpha_y = reg_control_i[10];
	assign samp_ce_y = (!cpha_y) ? sclk_rise_y : ~sclk_rise_y;
	assign fsm_ce_y = (!cpha_y) ? ~sclk_rise_y : sclk_rise_y;
	
	/*=============================================================================================
   -- REGISTERED INPUTS
   --=============================================================================================
    // rx bit flop: capture rx bit after SAMPLE edge of sck */
	reg rx_bit_reg_y;
	
   always @(posedge clk_i)
	begin
        if (samp_ce_y)
		  begin
            rx_bit_reg_y <= spi_miso_i;
			end
	end

    /*=============================================================================================
    --  REGISTER TRANSFER FSM
    --=============================================================================================*/
    // fsm state and data registers: synchronous to the spi base reference clock
	
	parameter [2:0]
		IDLE = 3'd0,
		WRITE = 3'd1,
		S2 = 3'd2,
		S3 = 3'd3,
		ERROR = 3'd4;
		

	reg [2:0]
		state, next;
	
	// FF registers clocked on rising edge and cleared on sync rst_i
    always @(posedge clk_i or negedge reset_n_i)
	begin
		if (!reset_n_i)
			state <= IDLE;
      else 
		begin
			if (fsm_ce_y)
				state <= next;
		end
	end

	reg [31:0] tx_reg_y;
	reg [31:0] rx_reg_y;
	reg tx_pull_y;
	reg sck_enable_y; 

	always @(posedge clk_i)
    begin
		
		case (state)
			IDLE : 
				begin
					tx_pull_y <= 0;
					sck_enable_y <= 0;
					if (trans_start_i & !tx_empty_i)
						next <= WRITE;
				end
		endcase
	end	
	
    /*=============================================================================================
    -- SCK out logic: pipeline phase compensation for the SCK line
    =============================================================================================*/	

	
	assign spi_sck_o = (sck_enable_y) ? spi_sclk_y : cpol_y;


endmodule