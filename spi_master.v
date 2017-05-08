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
	wire sclk_y;
	wire [3:0] clk_div_y;
	wire cpol_y;
	reg sclk_en_reg_y;
	
	assign clk_div_y = reg_control_i[3:0];
	assign cpol_y = reg_control_i[9];
		
	CLK_gen sclk_gen(clk_i, sclk_en_reg_y,reset_n_i, clk_div_y, sclk_y);
	
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
	
	reg sclk_fall_y;
	always @(posedge clk_i) 
	begin
		if (prev_sclk_y & !sclk_y) // falling edge of SCLK
			sclk_fall_y <= 1;
		else
			sclk_fall_y <= 0;
	end;
//    /*=============================================================================================
//    -- Sampling clock enable generation: depending on CPHA
//	 --=============================================================================================*/
	wire samp_ce_y;
	wire cpha_y;
	
	assign cpha_y = reg_control_i[10];
	
	assign samp_ce_y = ((sclk_en_reg_y) & (state == TRANSFER)) ? ((!cpha_y) ? sclk_rise_y : sclk_fall_y) : 0;
	
	/*=============================================================================================
   -- REGISTERED INPUTS
   --=============================================================================================*/
   
	 reg rx_bit_reg_y;
	
    always @(posedge clk_i)
	 begin
		rx_bit_reg_y <= spi_miso_i;
	 end

    /*=============================================================================================
    --  REGISTER TRANSFER FSM
    --=============================================================================================*/
    // fsm state and data registers: synchronous to the spi base reference clock
	
	reg [31:0] tx_reg_y;
	reg [31:0] rx_reg_y;
	reg tx_pull_y; 
	reg rx_push_y;
//	reg spi_enable_y;
	reg transfer_en_y;
	reg transfer_done_y;
	reg [5:0] num_of_transferred_bits_y;
	
	wire msb_first;
	assign msb_first = reg_control_i[8];
	reg [5:0] bits;
	

	always@(*)
	begin
		case(reg_trans_ctrl_i[6:5]) 
			2'b00 : bits <= 8;
			2'b01 : bits <= 16;
			2'b10 : bits <= 32;
			default : bits <= 8;
		endcase
	end
		
	localparam [2:0]
		IDLE = 3'd0,
		LOAD = 3'd1, 
		TRANSFER = 3'd2;
	//	ERROR = 3'd3;
		

	reg [2:0]
		state, next_state;
	// FF registers clocked on rising edge and cleared on sync rst_i
   always @(posedge clk_i, negedge reset_n_i)
	begin
		if (!reset_n_i)
			state <= IDLE;
      else
			state <= next_state;
	end

	always @(posedge clk_i, negedge reset_n_i)
    begin
		if(!reset_n_i)
			begin
				tx_pull_y <= 0;
				transfer_en_y <= 0;
				num_of_transferred_bits_y <= 0;
				transfer_done_y <= 0;
				sclk_en_reg_y <= 0;
				rx_push_y <= 0;
				sclk_en_reg_y <= 0;
				next_state <= IDLE;
			end
		else
			case (state)
				IDLE : 
					begin
						tx_pull_y <= 0;
						transfer_en_y <= 0;
						transfer_done_y <= 0;
						sclk_en_reg_y <= 0;
						rx_push_y <= 0;
						if (trans_start_i & !tx_empty_i)
						begin
							tx_pull_y <= 1;
							num_of_transferred_bits_y <= bits;
							next_state <= LOAD;
						end
					end
				LOAD : 
					begin
						tx_pull_y <= 0;
						rx_push_y <= 0;
						transfer_en_y <= 1;
						next_state <= TRANSFER;
					end
				TRANSFER :
					begin
						rx_push_y <= 0;
						tx_pull_y <= 0;
						sclk_en_reg_y <= 1;
						if(bit_counter==num_of_transferred_bits_y)
						begin
							sclk_en_reg_y <= 0;
							if(tx_empty_i)
							begin
								transfer_done_y <= 1;
								next_state <= IDLE;
							end
							else			
							begin
								tx_pull_y <= 1;
								next_state <= LOAD;	
								sclk_en_reg_y <= 0;
							end
							rx_push_y <= 1;
						end
					end
					
			endcase
	end	
	
//    /*=============================================================================================
//    -- Data shifting
//    =============================================================================================*/		
	
	reg [31:0] shr;
	reg [5:0] bit_counter;
	
//	always @(posedge clk_i)
//   begin
//		if(!reset_n_i)
//		begin
//			shr <= 0;
//			bit_counter <= 0;
//			mosi_y <= 0;
//		end
//		else if(tx_pull_y)
//			begin
//				shr <= tx_data_i;
//				if(msb_first)
//					mosi_y <= tx_data_i[31];
//				else
//					mosi_y <= tx_data_i[0];
//				bit_counter <=0;
//			end
//		else if(transfer_en_y)
//			begin
//				if(samp_ce_y)
//				begin
//					if(msb_first)
//					begin
//						shr <= {shr[30:0],spi_miso_i};
//						mosi_y <= shr[31];
//					end
//					else 
//					begin
//						shr <= {spi_miso_i,shr[31:1]};
//						mosi_y <= shr[0];
//					end
//					bit_counter <= bit_counter+1;
//				end
//			end
//	end
	
	reg [7:0] fifo0,fifo1,fifo2,fifo3;
	//reg [7:0] tx_fifo0,tx_fifo1,tx_fifo2,tx_fifo3;
	//reg [7:0] rx_fifo0,rx_fifo1,rx_fifo2,rx_fifo3;
	
	always@(posedge clk_i,negedge reset_n_i)
	begin
		if(!reset_n_i)
		begin
			fifo0 <= 0;
			fifo1 <= 0;
			fifo2 <= 0;
			fifo3 <= 0;	
			bit_counter <= 0;
		end
		else if(tx_pull_y)
		begin
			fifo0 <= tx_data_i[7:0];
			fifo1 <= tx_data_i[13:8];
			fifo2 <= tx_data_i[23:14];
			fifo3 <= tx_data_i[31:24];		
			bit_counter <= 0;
		end
		else if(transfer_en_y)
			begin
				if(samp_ce_y)
				begin
					if(!msb_first)
					begin
						fifo0 <= {fifo1[0],fifo0[7:1]};
						fifo1 <= {fifo2[0],fifo1[7:1]};
						fifo2 <= {fifo3[0],fifo2[7:1]};
						fifo3 <= {rx_bit_reg_y,fifo3[7:1]};
					end
					else
					begin
						fifo0 <= {fifo0[6:0],rx_bit_reg_y};
						fifo1 <= {fifo0[6:0],fifo0[7]};
						fifo2 <= {fifo0[6:0],fifo1[7]};
						fifo3 <= {fifo0[6:0],fifo2[7]};
					end
					bit_counter <= bit_counter + 1;
				end
			end
	end
	
	
	
//    /*=============================================================================================
//    -- mosi generation
//    =============================================================================================*/		

	reg mosi_y;
	reg [31:0] rx_data_y;
	always@(posedge clk_i)
	begin
		if(transfer_en_y)
		begin
			if(samp_ce_y)
				begin
					if(!msb_first)
						mosi_y <= fifo0[0];
					else
					begin
						case(num_of_transferred_bits_y)
							 6'd8		:	mosi_y <= fifo0[7];
							 6'd16	:	mosi_y <= fifo1[7];
							 6'd32	:	mosi_y <= fifo3[7];
						endcase
					end
				end
		end
	end
	
	always@(*)
	begin
		if(!msb_first)
		begin
			case(num_of_transferred_bits_y)
				 6'd8		: 	rx_data_y <= {24'd0,fifo3};
				 6'd16	:	rx_data_y <= {16'd0,fifo3,fifo2};
				 6'd32	:  rx_data_y <= {fifo3,fifo2,fifo1,fifo0};
			endcase
		end
		else
		begin
			rx_data_y <= {fifo3,fifo2,fifo1,fifo0};
		end
	end
	
	
//    /*=============================================================================================
//    -- SCK out logic: pipeline phase compensation for the SCK line
//    =============================================================================================*/	
//

	wire [3:0] ss_n = reg_trans_ctrl_i[3:0];

	assign tx_pull_o = tx_pull_y;
	assign trans_done_o = transfer_done_y;
	assign rx_data_o = rx_data_y;
	assign rx_push_o = rx_push_y;		
	assign spi_ssel_o = (sclk_en_reg_y) ? ~(ss_n) : 4'hF; //bitwise
	assign spi_sck_o = (!cpol_y) ? sclk_y : ~sclk_y;
	assign spi_mosi_o = (sclk_en_reg_y) ? mosi_y : 1'bz;


endmodule