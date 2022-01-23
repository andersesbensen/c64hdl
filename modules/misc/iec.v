module iec (
           input reset,
           input clk,
           input atn,
           input clock_i,
           input data_i,
           output reg clock_o,
           output reg data_o,

           input[7:0] tx_byte,
           input tx_ready,

           output reg[7:0] rx_byte,
           output reg rx_ready
       );

localparam [3:0] 
           IDLE = 0,
           RX = 1,
           EOI = 2;

reg[3:0] state;
reg[9:0] cnt;
reg[7:0] buffer;
reg[3:0] bit_cnt;

reg last_clk;
reg last_dat;

reg eoi;

always @(posedge clk ) begin
    if(reset) begin
        state <= IDLE;
        rx_byte <=0;
        rx_ready <=0;
        clock_o <= 1;
    end

    cnt <= cnt + 1;
    last_clk <= clock_i;
    last_dat <= data_i;

    //Falling edge
    if(state == IDLE) begin
        bit_cnt <= 0;
        eoi <= 0;
        data_o <= 0;
        rx_ready <= 0;     
    end
    
    if(rx_ready) rx_ready <= 0;

    //Rising edge of input clock
    if(!last_clk && clock_i) begin
        //shift RX byte
        rx_byte = {last_dat, rx_byte[7:1]};
        cnt <= 0;
        if(state == IDLE) begin
            state <= RX;
            data_o <= 1;
        end else if( (state == EOI) || (state == RX)) begin
            bit_cnt <= bit_cnt + 1;            
            
            if(bit_cnt == 7) begin
                rx_ready <=1;
                state <= IDLE;
            end else
                state <= RX;
        end 
    end

    //Receive timeout
    if((cnt == 200) && (state == RX)) begin
        state <=  eoi ? IDLE : EOI;
        data_o <= 0;
        cnt <= 0;
    end

    if((cnt == 60) && (state == EOI)) begin
        state <= RX;
        data_o <= 1;
        eoi <= 1;
    end

end
endmodule
