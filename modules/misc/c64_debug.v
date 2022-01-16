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

reg[4:0]  debug_state;
reg[23:0] debug_timeout;


localparam DEBUG_READ_OP     = 1;
localparam DEBUG_WRITE_OP    = 2;
localparam DEBUG_WRITE_PS2   = 3;
localparam DEBUG_WRITE_RESET = 4;

localparam DEBUG_IDLE        = 0;
localparam DEBUG_WRITE       = 1;
localparam DEBUG_WRITE_ADDR1 = 2;
localparam DEBUG_WRITE_ADDR2 = 3;
localparam DEBUG_WRITE_DATA  = 4;
localparam DEBUG_READ        = 5;
localparam DEBUG_READ_ADDR1  = 6;
localparam DEBUG_READ_ADDR2  = 7;
localparam DEBUG_READ_PS2_1  = 8;
localparam DEBUG_READ_PS2_2  = 9;
localparam DEBUG_READ_PS2_3  = 10;

always @(posedge clk ) begin
    if(reset) begin
        debug_request <= 0;
        debug_we <= 0;
        debug_data_o <=0;
        debug_state <= DEBUG_IDLE;
        debug_timeout <=0;
        uart_tx_byte_valid <= 0;
        debug_addr <= 0;
    end

    if(uart_tx_byte_valid) uart_tx_byte_valid <= 0;

    debug_timeout<= debug_timeout + 1;
    if(debug_timeout == 1000000) debug_state <= DEBUG_IDLE;
    if(uart_rx_byte_valid) begin
        debug_timeout <= 0;
        case (debug_state)
            DEBUG_IDLE: begin
                if( uart_rx_byte == DEBUG_READ_OP) debug_state <= DEBUG_READ_ADDR1;
                else if( uart_rx_byte == DEBUG_WRITE_OP ) debug_state <= DEBUG_WRITE_ADDR1;
                else if( uart_rx_byte == DEBUG_WRITE_PS2 ) begin
                    debug_state <= DEBUG_READ_PS2_1;
                    ps2_request <=1;
                end
            end
            DEBUG_WRITE_ADDR1: begin
                debug_addr[15:8] <= uart_rx_byte;
                debug_state <= DEBUG_WRITE_ADDR2;
            end
            DEBUG_WRITE_ADDR2: begin
                debug_addr[7:0] <= uart_rx_byte;
                debug_state <= DEBUG_WRITE_DATA;
            end
            DEBUG_WRITE_DATA: begin
                debug_data_o <= uart_rx_byte;
                debug_we   <= 1;
                debug_request  <= 1;
            end

            DEBUG_READ_ADDR1: begin
                debug_addr[15:8] <= uart_rx_byte;
                debug_state <= DEBUG_READ_ADDR2;
            end
            DEBUG_READ_ADDR2: begin
                debug_addr[7:0] <= uart_rx_byte;
                debug_we  <= 0;
                debug_request <= 1;
            end
            DEBUG_READ_PS2_1: begin
                ps2_request <=1;
                debug_state <= DEBUG_READ_PS2_2;
            end
            DEBUG_READ_PS2_2: begin
                ps2_request <=0;
                debug_state <= DEBUG_IDLE;
            end
//            DEBUG_READ_PS2_3: begin
//                ps2_request <=0;
//                debug_state <= DEBUG_IDLE;
//            end
        default:
            ;
        endcase
    end else if( debug_request && debug_ack ) begin
        if(debug_state == DEBUG_READ_ADDR2) begin
            uart_tx_byte <= debug_data_i;
        end else if(debug_state == DEBUG_WRITE_DATA) begin
            uart_tx_byte <= 6;
        end
        uart_tx_byte_valid <= 1;
        debug_state <= DEBUG_IDLE;
        debug_request <= 0;
    end
end

endmodule
