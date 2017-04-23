/*---------------------------------------------------------------------------------------------------------------------
-- Author:          Peter Hasza, hasza.peti@gmail.com
-- 
-- Create Date:     04/02/2017 
-- Module Name:     utils
-- Project Name:    AXI_SPI_IF
-- Description: 
--					Common utility functions for AXI_SPI_IF project
--
------------------------------ REVISION HISTORY -----------------------------------------------------------------------
--
-- 2017.apr.2	|	hp3265	||	Initial version
--
-----------------------------------------------------------------------------------------------------------------------*/
`define CLOGB2(clogb2)             											\
function integer clogb2;														\
    input integer value;														\
    begin																			\
        value = value - 1;														\
        for (clogb2 = 0; value > 0; clogb2 = clogb2 + 1) begin		\
            value = value >> 1;												\
        end																			\
    end																				\
endfunction

`define TRUNC(trunc_signal, IN_LEFT_VAL, OUT_LEFT_VAL)            \
function [OUT_LEFT_VAL:0] trunc_signal;									\
	input [IN_LEFT_VAL:0] in_val;												\
	trunc_signal = in_val[OUT_LEFT_VAL:0];									\
endfunction 