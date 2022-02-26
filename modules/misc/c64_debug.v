// Copyright 2022 Anders Lynge Esbensen. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

module c64_debug (
           input clk,
           input reset,
           input uart_rx_byte_valid,
           input[7:0] uart_rx_byte,
           input[7:0] debug_data_i,

           output reg uart_tx_byte_valid,
           output reg[7:0] uart_tx_byte,

           output reg[15:0] debug_addr,
           output reg[7:0]  debug_data_o,
           output reg       debug_we,

           output reg       debug_request,
           output reg       ps2_request,
           output reg       reset_request,
           input debug_ack
       )
       ;

localparam DEBUG_READ_OP     = 1;
localparam DEBUG_WRITE_OP    = 2;
localparam DEBUG_WRITE_PS2   = 3;
localparam DEBUG_WRITE_RESET = 4;

reg[23:0] debug_timeout;
reg[31:0] cmd;

always @(posedge clk ) begin
    if(reset) begin
        reset_request <= 0;
        debug_request <= 0;
        debug_we <= 0;
        debug_data_o <=0;
        debug_timeout <=0;
        uart_tx_byte_valid <= 0;
        debug_addr <= 0;
    end

    if(uart_tx_byte_valid) uart_tx_byte_valid <= 0;

    reset_request <= cmd == 32'hdeadbeef;

    if(debug_timeout == 1000000) begin
        cmd <= 0;
    end else if( debug_ack ) begin
        uart_tx_byte <= cmd[31:16] == 16'h0001 ?  debug_data_i : 6;
        uart_tx_byte_valid <= 1;
        debug_request <= 0;
        cmd <=0;
    end else if(cmd[31:16] == 16'h0001) begin
        debug_addr <= cmd[15:0];
        debug_we <= 0;
        debug_request <= 1;
    end else if( cmd[31:24] == 8'h02) begin
        debug_addr <= cmd[23:8];
        debug_data_o <= cmd[7:0];
        debug_we <= 1;
        debug_request <= 1;
    end else if( cmd[31:24] == 8'h03) begin
        debug_data_o <= cmd[7:0];
        ps2_request <= 1;
    end 
        
    if(uart_rx_byte_valid) begin
        debug_timeout <= 0;        
        cmd <= cmd << 8 | uart_rx_byte;
    end

    debug_timeout<= debug_timeout + 1;
end

endmodule
