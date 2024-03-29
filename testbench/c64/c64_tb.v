// Copyright 2022 Anders Lynge Esbensen. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.


module c64_tb(

       );

reg clk;
reg reset;

wire[7:0] vga_rgb_r_o;
wire vga_clk_o;

wire[7:0] keyboard_r;
wire[7:0] keyboard_c;

assign keyboard_c =  8'b11111111;

//Load test image
reg loading;
reg[15:0] offset;
reg[15:0] load_addr;
wire[7:0]  rom_data;
wire[15:0] Ao;

reg DMA;
reg RW;
reg start_load;
wire BA;
wire ROMH;
wire ROML;

wire serial_clock_i;
wire serial_data_i;
wire serial_clock_o;
wire serial_data_o;
wire serial_atn_o;
wire[7:0] debug_status;
wire debug_status_valid;
wire phi2;


c64 c64_e(
        .color_carrier(),
        .dot_clk(clk),
        .reset(!reset),
        .composite(),
        .cass_rd(1'b1),
        .cass_sense(1'b1),
        .keyboard_COL(keyboard_c),
        .keyboard_ROW(keyboard_r),

        .INTRES(1'b0),
        .NMI(1'b0),
        .IRQ(1'b0),

        .Ai(load_addr),
        .Ao(Ao),
        .DMA(DMA),
        .Di(rom_data),
        .RW(1'b0),
        .BA(BA),
        .ROMH(ROMH),
        .ROML(ROML),

        .phi2(phi2),

        .GAME_n(1'b1),
        .EXTROM_n(1'b0),
        //.EXTROM_n(1'b1),

        //IEC Serial port
        .serial_clock_i(serial_clock_i),
        .serial_data_i(serial_data_i),
        .serial_data_o(serial_data_o),
        .serial_clock_o(serial_clock_o),
        .serial_atn(serial_atn_o),

        .joy_a( 5'b11111),
        .joy_b( 5'b11111),

        .debug_status(debug_status),
        .debug_status_valid(debug_status_valid)
    );

iec iec_e (
    .reset(!reset),
    .clk(phi2),
    .atn(serial_atn_o),
    .clock_i(serial_clock_o),
    .clock_o(serial_clock_i),
    .data_o(serial_data_i),
    .data_i(serial_data_o)

    /*.rx_byte(iec_tx_byte),
    .rx_ready(iec_tx_byte_valid),
    .tx_byte(iec_rx_byte),
    .tx_ready(iec_rx_byte_valid)*/
);


/* 8kb cartrige */
rom #("cartrige.mif",13,8192) carrtrige_rom(
        .clk(clk),
        .a(  Ao[12:0] ),
        .do( rom_data ),
        .enable( ROML )
    );


reg[7:0] cmd[0:9] ;
integer i;

initial begin
    //$dumpfile("c64.vcd");
    //$dumpvars(0, c64_tb);

    //cmd = "LOAD \"$\",8";
    start_load = 0;
    loading =0;
    reset = 1;
    clk = 1'b0;
    DMA=0;
    load_addr = 0;

    repeat(4*50) #63 clk = ~clk;
    reset = 0;

    repeat(16*50) #63 clk = ~clk;
    reset = 1;


    $display("Running");


    repeat(1000) #63 clk = ~clk;

    reset = 0;
    repeat(16*50) #63 clk = ~clk;
    reset = 1;


    forever  #63 begin
        clk = ~clk;
        if(debug_status_valid) begin
            //$fatal(debug_status,"fail %x", debug_status);
            $finish;
        end;
    end
    $display("Done status %x", debug_status);

    $finish;

end

endmodule
