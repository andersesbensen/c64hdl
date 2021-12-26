`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 04/20/2018 06:41:30 AM
// Design Name:
// Module Name: c64_artix_tb
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////


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
        .EXTROM_n(1'b1),
        .serial_data_i(1'b0),
        .serial_clock_i(1'b0),

        .joy1( 5'b11111),
        .joy2( 5'b11111)
    );


/* 8kb cartrige */
rom #("diag.mif",13,8192) carrtrige_rom(
        .clk(clk),
        .a(  Ao[12:0] ),
        .do( rom_data ),
        .enable( ROML )
    );


reg[7:0] cmd[0:9] ;
integer i;

initial begin
    $dumpfile("c64.vcd");
    $dumpvars(0, c64_e);

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


    forever  #63 clk = ~clk;

    $display("Done");
    $finish;
end

endmodule
