/*---------------------------------------------------------------------------------------------------------------------
-- Author:          Peter Hasza, hasza.peti@gmail.com
-- 
-- Create Date:     04/02/2017 
-- Module Name:     SPI_MASTER
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

// synopsys translate_off
`define SPI_MASTER_DEBUG_INTERFACE
// synopsys translate_on

module spi_master (

		// Reset and Clocking
		input clk_i,								// high-speed system clock
		input rst_i,								// synchronous reset input
		
		// Serial interface
        output spi_ssel_o,          				// spi bus slave select line
        output spi_sck_o,           				// spi bus sck
        output spi_mosi_o,          				// spi bus mosi output
        input spi_miso_i,     						// spi bus spi_miso_i input
		
`ifdef SPI_MASTER_DEBUG_INTERFACE
        // debug ports
        output sck_ena_o,                          	// debug: internal sck enable signal
        output sck_ena_ce_o,                        // debug: internal sck clock enable signal
        output do_transfer_o,                       // debug: internal transfer driver
        output wren_o,                              // debug: internal state of the wren_i pulse stretcher
        output rx_bit_reg_o,                        // debug: internal rx bit
        output [3:0] state_dbg_o,                	// debug: internal state register
        output core_clk_o,
        output core_n_clk_o,
        output core_ce_o,
        output core_n_ce_o,
        output [g_word_length-1:0] sh_reg_dbg_o,    // debug: internal shift register
`endif

		//Parallel system interface
        output data_pull_o,                         // preload lookahead data request line
        input [g_word_length-1:0] data_i,  			// parallel data in (clocked on rising spi_clk after last bit)
        input wren_i,                               // user data write enable, starts transmission when interface is idle
        output wr_ack_o,                            // write acknowledge
        output data_push_o,                         // do_o data valid signal, valid during one spi_clk rising edge.
        output [g_word_length-1:0] data_o           // parallel output (clocked on rising spi_clk after last bit)		

	);

	parameter g_word_length = 32;	// 32bit serial word length is default
	parameter g_cpol = 0;			// CPOL = clock polarity
	parameter g_cpha = 0;			// CPHA = clock phase.
	parameter g_prefetch = 2;		// prefetch lookahead cycles
	parameter g_clk_div = 5;		// CLK ratio between clk_i and sclk_i
	
/*     // core clocks; generated from 'sclk_i': initialized at GSR to differential values
    wire core_clk;     				// continuous core clock; positive logic
    wire core_n_clk;     			// continuous core clock; negative logic
    wire core_ce;     				// core clock enable; positive logic
    wire core_n_ce;     			// core clock enable; negative logic
    // spi bus clock; generated from the CPOL selected core clock polarity
    wire spi_2x_ce;     			// spi_2x clock enable
    wire spi_clk;    				// spi bus output clock
    reg spi_clk_reg ;            	// output pipeline delay for spi sck (do NOT global initialize)
    // core fsm clock enables
    wire fsm_ce;     				// fsm clock enable
    wire sck_ena_ce;     			// SCK clock enable
    wire samp_ce;    				// data sampling clock enable */
    
	/* GLOBAL RESET: 
    --      all signals are initialized to zero at GSR (global set/reset) by giving explicit
    --      initialization values at declaration. This is needed for all Xilinx FPGAs; and 
    --      especially for the Spartan-6 and newer CLB architectures; where a async reset can
    --      reduce the usability of the slice registers; due to the need to share the control 
    --      set (RESET/PRESET; CLOCK ENABLE and CLOCK) by all 8 registers in a slice.
    --      By using GSR for the initialization; and reducing async RESET local init to the bare
    --      essential; the model achieves better LUT/FF packing and CLB usability. 
	*/
	
/*     // internal state signals for register and combinatorial stages
    reg [g_word_length+1:0] state_next = 0;
    reg [g_word_length+1:0] state_reg = 0;
    // shifter wires for register and combinatorial stages
    reg [g_word_length-1:0] sh_next = 0;
    reg [g_word_length-1:0] sh_reg = 0;
    // input bit sampled buffer
    reg rx_bit_reg;
    // buffered di_i data wires for register and combinatorial stages
    reg [g_word_length=1:0] di_reg = 0;
    // internal wren_i stretcher for fsm combinatorial stage
    wire wren;
    reg wr_ack_next = 0;
    reg wr_ack_reg = 0;
    // internal SSEL enable control wires
    reg ssel_ena_next = 0;
    reg ssel_ena_reg = 0;
    // internal SCK enable control wires
    reg sck_ena_next = 0;
    reg sck_ena_reg = 0;
    // buffered do_o data wires for register and combinatorial stages
    reg [g_word_length-1:0] do_buffer_next = 0;
    reg [g_word_length-1:0] do_buffer_reg = 0;
    // internal wire to flag transfer to do_buffer_reg
    reg do_transfer_next = 0;
    reg do_transfer_reg = 0;
    // internal input data request wire 
    reg di_req_next = 0;
    reg di_req_reg = 0;
    // cross-clock do_transfer_reg -> do_valid_o_reg pipeline
    reg do_valid_A = 0;
    reg do_valid_B = 0;
    reg do_valid_C = 0;
    reg do_valid_D = 0;
    reg do_valid_next = 0;
    reg do_valid_o_reg = 0;
    // cross-clock di_req_reg -> di_req_o_reg pipeline
    reg di_req_o_A = 0;
    reg di_req_o_B = 0;
    reg di_req_o_C = 0;
    reg di_req_o_D = 0;
    reg di_req_o_next = 1;
    reg di_req_o_reg = 1; */
	
	/*=============================================================================================
    --  CLOCK GENERATION
    --=============================================================================================
    -- In order to preserve global clocking resources, the core clocking scheme is completely based 
    -- on using clock enables to process the serial high-speed clock at lower rates for the core fsm,
    -- the spi clock generator and the input sampling clock.
    -- The clock generation block derives 2 continuous antiphase signals from the 2x spi base clock 
    -- for the core clocking.
    -- The 2 clock phases are generated by separate and synchronous FFs, and should have only 
    -- differential interconnect delay skew.
    -- Clock enable signals are generated with the same phase as the 2 core clocks, and these clock 
    -- enables are used to control clocking of all internal synchronous circuitry. 
    -- The clock enable phase is selected for serial input sampling, fsm clocking, and spi SCK output, 
    -- based on the configuration of CPOL and CPHA.
    -- Each phase is selected so that all the registers can be clocked with a rising edge on all SPI
    -- modes, by a single high-speed global clock, preserving clock resources and clock to data skew.
    ----------------------------------------------------------------------------------------------*/
	wire sclk_y
	
	generate
		if(g_clk_div > 1)
			CLK_gen_simple #(g_clk_div) sclk_gen(clk_i, sclk_y);
		else
			assign sclk_y = clk_i;
	endgenerate
	
	generate
		if(g_cpol = 0)
			assign sclk_o = sclk_y;
		else
			assign sclk_o = not sclk_y;
	endgenerate
	
	reg prev_sclk_y;
	
	always @(posedge clk_i) prev_sclk_y <= sclk_y;
	
	reg clk_en_y;
	
	always @(posedge clk_i) 
	begin
		if (prev_sclk_y = 0 and sclk_y = 1) // rising edge of SCLK
			clk_en_y <= 1;
		else
			clk_en_y <= 0;
	end;
	

    /*-----------------------------------------------------------------------------------------------
    // Sampling clock enable generation: generate 'samp_ce' from 'clk_en_y' depending on CPHA
    // always sample data at the half-cycle of the fsm update cell*/
	wire samp_ce;
	
	generate
		if(g_cpha = 0)
			samp_ce <= clk_en_y;
			fsm_ce <= not clk_en_y;
		else
			samp_ce <= not clk_en_y;
			fsm_ce <= clk_en_y;
	endgenerate
	
	/*=============================================================================================
    //  REGISTERED INPUTS
    //-=============================================================================================
    // rx bit flop: capture rx bit after SAMPLE edge of sck */
	reg rx_bit_reg;
	
    always @(posedge sclk_i) is
	begin
        if (samp_ce)
            rx_bit_reg <= spi_miso_i;
	end
	
	/*============================================================================================
    //  CROSS-CLOCK PIPELINE TRANSFER LOGIC
    //=============================================================================================
    // do_valid_o and di_req_o strobe output logic
    // this is a delayed pulse generator with a ripple-transfer FFD pipeline, that generates a 
    // fixed-length delayed pulse for the output flags, at the parallel clock domain */
    reg [] data_o_shiftreg_y;
	
	always @ (posedge clk_i)
    begin
            do_valid_A <= do_transfer_reg;                  -- the input signal must be at least 2 clocks long
            do_valid_B <= do_valid_A;                       -- feed it to a ripple chain of FFDs
            do_valid_C <= do_valid_B;
            do_valid_D <= do_valid_C;
            do_valid_o_reg <= do_valid_next;                -- registered output pulse
            --------------------------------
            -- di_req_reg -> di_req_o_reg
            di_req_o_A <= di_req_reg;                       -- the input signal must be at least 2 clocks long
            di_req_o_B <= di_req_o_A;                       -- feed it to a ripple chain of FFDs
            di_req_o_C <= di_req_o_B;                           
            di_req_o_D <= di_req_o_C;                           
            di_req_o_reg <= di_req_o_next;                  -- registered output pulse
        end if;
        -- generate a 2-clocks pulse at the 3rd clock cycle
        do_valid_next <= do_valid_A and do_valid_B and not do_valid_D;
        di_req_o_next <= di_req_o_A and di_req_o_B and not di_req_o_D;
    end process out_transfer_proc;
	
    // parallel load input registers: data register and write enable
    in_transfer_proc: process ( pclk_i, wren_i, wr_ack_reg ) is
    begin
        -- registered data input, input register with clock enable
        if pclk_i'event and pclk_i = '1' then
            if wren_i = '1' then
                di_reg <= di_i;                             -- parallel data input buffer register
            end if;
        end  if;
        -- stretch wren pulse to be detected by spi fsm (ffd with sync preset and sync reset)
        if pclk_i'event and pclk_i = '1' then
            if wren_i = '1' then                            -- wren_i is the sync preset for wren
                wren <= '1';
            elsif wr_ack_reg = '1' then                     -- wr_ack is the sync reset for wren
                wren <= '0';
            end if;
        end  if;
    end process in_transfer_proc;

    /*=============================================================================================
    --  REGISTER TRANSFER PROCESSES
    --=============================================================================================*/
    // fsm state and data registers: synchronous to the spi base reference clock
	
	parameter [2:0] // synopsys enum code
		IDLE = 3'd0,
		S1 = 3'd1,
		S2 = 3'd2,
		S3 = 3'd3,
		ERROR = 3'd4;
		
	// synopsys state_vector state
	reg [2:0] // synopsys enum code
		state, next;
	
	// FF registers clocked on rising edge and cleared on sync rst_i
    always @(posedge clk_i)
	begin
		if (rst_i)                             			// sync reset
            state <= IDLE;                             	// only provide local reset for the state machine
        else if (fsm_ce)                         		// fsm_ce is clock enable for the fsm
            state <= next;                    			// state register
        end if;
	end
	
	// FF registers clocked synchronous to the fsm state
	always @(posedge clk_i)
	begin
		if (fsm_ce)
		begin
            sh_reg <= sh_next;                          // shift register
            ssel_ena_reg <= ssel_ena_next;              // spi select enable
            do_buffer_reg <= do_buffer_next;            // registered output data buffer 
            data_push_reg <= data_push_next;        	// output data transferred to buffer
            data_pull_reg <= data_pull_next;        	// input data request
			ctrl_pull_reg <= ctrl_pull_reg;
//            wr_ack_reg <= wr_ack_next;                  // write acknowledge for data load synchronization
        end
	end
	
	// FF registers clocked one-half cycle earlier than the fsm state
	always @(posedge clk_i)
    begin
        if (clk_en_y)
            sck_ena_reg <= sck_ena_next;                // spi clock enable: look ahead logic
    end

    /*=============================================================================================
    --  COMBINATORIAL LOGIC PROCESSES
    --=============================================================================================*/
    // state and datapath combinatorial logic
	
    always @(posedge clk_i)
    begin
        sh_next <= sh_reg;                                              -- all output signals are assigned to (avoid latches)
        ssel_ena_next <= ssel_ena_reg;                                  -- controls the slave select line
        sck_ena_next <= sck_ena_reg;                                    -- controls the clock enable of spi sck line
        do_buffer_next <= do_buffer_reg;                                -- output data buffer
        data_push_next <= do_transfer_reg;                            -- output data flag
        wr_ack_next <= wr_ack_reg;                                      -- write acknowledge
        data_pull_next <= di_req_reg;                                      -- prefetch data request
        spi_mosi_o <= sh_reg(N-1);                                      -- default to avoid latch inference
        state_next <= state_reg;                                        -- next state 
		
		case (state)
			// idle state: start and end of transmission
			IDLE : begin
				di_req_next <= '1';                                     // will request data if shifter empty
                sck_ena_next <= '0';                                    // SCK disabled: tx empty, no data to send
                if (data_valid_i)                                       // load tx register if valid data present at di_i
                    spi_mosi_o <= di_reg(N-1);                          // special case: shift out first tx bit from the MSb (look ahead)
                    ssel_ena_next <= '1';                               // enable interface SSEL
                    state_next <= N+1;                                  // start from idle: let one cycle for SSEL settling
                    sh_next <= di_reg;                                  // load bits from di_reg into shifter
                    wr_ack_next <= '1';                                 // acknowledge data in transfer
                else
                    spi_mosi_o <= sh_reg(N-1);                          // shift out tx bit from the MSb
                    ssel_ena_next <= '0';                               // deassert SSEL: interface is idle
                    wr_ack_next <= '0';                                 // remove write acknowledge for all but the load stages
                    state_next <= 0;                                    // when idle, keep this state
                end if;
			
			
				end
		
		endcase
		
        case state_reg is
        
            when (N+1) =>                                               // this state is to enable SSEL before SCK
                spi_mosi_o <= sh_reg(N-1);                              // shift out tx bit from the MSb
                ssel_ena_next <= '1';                                   // tx in progress: will assert SSEL
                sck_ena_next <= '1';                                    // enable SCK on next cycle (stays off on first SSEL clock cycle)
                di_req_next <= '0';                                     // prefetch data request: deassert when shifting data
                wr_ack_next <= '0';                                     // remove write acknowledge for all but the load stages
                state_next <= state_reg - 1;                            // update next state at each sck pulse
                
            when (N) =>                                                 // deassert 'di_rdy' and stretch do_valid
                spi_mosi_o <= sh_reg(N-1);                              // shift out tx bit from the MSb
                di_req_next <= '0';                                     // prefetch data request: deassert when shifting data
                sh_next(N-1 downto 1) <= sh_reg(N-2 downto 0);          // shift inner bits
                sh_next(0) <= rx_bit_reg;                               // shift in rx bit into LSb
                wr_ack_next <= '0';                                     // remove write acknowledge for all but the load stages
                state_next <= state_reg - 1;                            // update next state at each sck pulse
                
            when (N-1) downto (PREFETCH+3) =>                           // remove 'do_transfer' and shift bits
                spi_mosi_o <= sh_reg(N-1);                              // shift out tx bit from the MSb
                di_req_next <= '0';                                     // prefetch data request: deassert when shifting data
                do_transfer_next <= '0';                                // reset 'do_valid' transfer signal
                sh_next(N-1 downto 1) <= sh_reg(N-2 downto 0);          // shift inner bits
                sh_next(0) <= rx_bit_reg;                               // shift in rx bit into LSb
                wr_ack_next <= '0';                                     // remove write acknowledge for all but the load stages
                state_next <= state_reg - 1;                            // update next state at each sck pulse
                
            when (PREFETCH+2) downto 2 =>                               // raise prefetch 'di_req_o' signal
                spi_mosi_o <= sh_reg(N-1);                              // shift out tx bit from the MSb
                di_req_next <= '1';                                     // request data in advance to allow for pipeline delays
                sh_next(N-1 downto 1) <= sh_reg(N-2 downto 0);          // shift inner bits
                sh_next(0) <= rx_bit_reg;                               // shift in rx bit into LSb
                wr_ack_next <= '0';                                     // remove write acknowledge for all but the load stages
                state_next <= state_reg - 1;                            // update next state at each sck pulse
                
            when 1 =>                                                   // transfer rx data to do_buffer and restart if new data is written
                spi_mosi_o <= sh_reg(N-1);                              // shift out tx bit from the MSb
                di_req_next <= '1';                                     // request data in advance to allow for pipeline delays
                do_buffer_next(N-1 downto 1) <= sh_reg(N-2 downto 0);   // shift rx data directly into rx buffer
                do_buffer_next(0) <= rx_bit_reg;                        // shift last rx bit into rx buffer
                do_transfer_next <= '1';                                // signal transfer to do_buffer
                if wren = '1' then                                      // load tx register if valid data present at di_i
                    state_next <= N;                                  	// next state is top bit of new data
                    sh_next <= di_reg;                                  // load parallel data from di_reg into shifter
                    sck_ena_next <= '1';                                // SCK enabled
                    wr_ack_next <= '1';                                 // acknowledge data in transfer
                else
                    sck_ena_next <= '0';                                // SCK disabled: tx empty, no data to send
                    wr_ack_next <= '0';                                 // remove write acknowledge for all but the load stages
                    state_next <= state_reg - 1;                        // update next state at each sck pulse
                end if;
                
            when 0 =>                                                   // idle state: start and end of transmission
                di_req_next <= '1';                                     // will request data if shifter empty
                sck_ena_next <= '0';                                    // SCK disabled: tx empty, no data to send
                if wren = '1' then                                      // load tx register if valid data present at di_i
                    spi_mosi_o <= di_reg(N-1);                          // special case: shift out first tx bit from the MSb (look ahead)
                    ssel_ena_next <= '1';                               // enable interface SSEL
                    state_next <= N+1;                                  // start from idle: let one cycle for SSEL settling
                    sh_next <= di_reg;                                  // load bits from di_reg into shifter
                    wr_ack_next <= '1';                                 // acknowledge data in transfer
                else
                    spi_mosi_o <= sh_reg(N-1);                          // shift out tx bit from the MSb
                    ssel_ena_next <= '0';                               // deassert SSEL: interface is idle
                    wr_ack_next <= '0';                                 // remove write acknowledge for all but the load stages
                    state_next <= 0;                                    // when idle, keep this state
                end if;
                
            when others =>
                state_next <= 0;                                        // state 0 is safe state
        end case; 
    end process core_combi_proc;

    /*=============================================================================================
    //  OUTPUT LOGIC PROCESSES
    --=============================================================================================*/
    // data output processes
    assign spi_ssel_o = not slave_sel_reg;                 	// active-low slave select line 
    assign data_o = data_buffer_reg;                        // parallel data out
    assign data_push_o = data_push_reg;                   	// data out valid
    assign data_pull_o = data_pull_reg;                     // input data request for next cycle
//    assign wr_ack_o = wr_ack_reg;                         -- write acknowledge

    /*-----------------------------------------------------------------------------------------------
    -- SCK out logic: pipeline phase compensation for the SCK line
    -----------------------------------------------------------------------------------------------*/
    // This is a MUX with an output register. 
    // The register gives us a pipeline delay for the SCK line, pairing with the state machine moore 
    // output pipeline delay for the MOSI line, and thus enabling higher SCK frequency. 
    always @(posedge clk_i)
    begin
        if sck_ena_reg = '1' then
            spi_clk_reg <= spi_clk;                            // copy the selected clock polarity
        else
            spi_clk_reg <= CPOL;                               // when clock disabled, set to idle polarity
    end
	
	assign spi_sck_o = spi_clk_reg;                              // connect register to output

`ifdef SPI_MASTER_DEBUG_INTERFACE	
    /*=============================================================================================
    --  DEBUG LOGIC PROCESSES
    --=============================================================================================*/
    // these signals are useful for verification, and can be deleted after debug.
    assign do_transfer_o = do_transfer_reg;
    assign state_dbg_o = state_reg;
    assign rx_bit_reg_o = rx_bit_reg;
    assign wren_o = wren;
    assign sh_reg_dbg_o = sh_reg;
    assign core_clk_o = core_clk;
    assign core_n_clk_o = core_n_clk;
    assign core_ce_o = core_ce;
    assign core_n_ce_o = core_n_ce;
    assign sck_ena_o = sck_ena_reg;
    assign sck_ena_ce_o = sck_ena_ce;
`endif	

end module;