// Copyright 2022 Anders Lynge Esbensen. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.



`default_nettype none

module tb_iec;
reg clk;
reg rst_n;


reg atn;

reg data_i;
reg clock_i;
wire clock_o;
wire data_o;

reg[7:0] tx_byte;
reg tx_ready;

wire[7:0] rx_byte;
wire rx_ready;
reg[7:0] last_rx_byte;


iec iec_e
(
    .reset(!rst_n),
    .clk(clk),
    .atn(atn),
    .clock_i(clock_i),
    .data_i(data_i),
    .clock_o(clock_o),
    .data_o(data_o),

    .tx_byte(tx_byte),
    .tx_ready(tx_ready),

    .rx_byte(rx_byte),
    .rx_ready(rx_ready)

);

always @(posedge clk ) begin
    if(rx_ready) last_rx_byte <= rx_byte;
end

localparam CLK_PERIOD = 10;
always #(CLK_PERIOD/2) clk=~clk;
integer  i;

initial begin
    $dumpfile("tb_iec.vcd");
    $dumpvars(0, tb_iec);
end

initial begin

    atn <= 1;
    data_i <= 0;
    clock_i <= 0;
    tx_byte <= 8'h42;
    tx_ready <=0;
    last_rx_byte <= 0;
    #1 rst_n<=1'bx;clk<=1'bx;
    #(CLK_PERIOD*3) rst_n<=1;
    #(CLK_PERIOD*3) rst_n<=0;clk<=0;
    repeat(5) @(posedge clk);
    rst_n<=1;
    @(posedge clk);
    repeat(2) @(posedge clk);


    /* To begin the talker releases the Clock line to false. When all bus listeners are ready to
        receive they release the Data line to false. */
    clock_i <=1;
    repeat(30) @(posedge clk);
    
    if(data_o != 1) $display("Data is not false");

    //Transmit 

    for(i = 0; i < 8 ; i=i+1) begin
        clock_i <=1;
        data_i <= tx_byte & 1;
        tx_byte <= tx_byte >> 1;
        repeat(30) @(posedge clk);

        clock_i <=0;
        repeat(30) @(posedge clk);        
    end

   if(data_o != 0) $display("Data is not true");
   if(rx_byte != 8'h42) $display("Werong byte value");


    //Force EOI
    tx_byte <= 123;

    clock_i <=1;
    repeat(30) @(posedge clk);
    
    if(data_o != 1) $display("Data is not false");

    //Transmit 

    for(i = 0; i < 4 ; i=i+1) begin
        clock_i <=1;
        data_i <= tx_byte & 1;
        tx_byte <= tx_byte >> 1;
        repeat(30) @(posedge clk);

        clock_i <=0;
        repeat(30) @(posedge clk);        
    end
    clock_i <=1;

    if(data_o != 0) $display("Data is not true");

    repeat(200) @(posedge clk);        

    if(data_o != 1) $display("Data is not false");

    repeat(60) @(posedge clk);        

    $finish(2);
end

endmodule
`default_nettype wire