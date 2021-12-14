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

/*
  wire[7:0] iec_rx;
  wire      iec_ready;

  iec iec_i ( 
    .reset_n(!reset),
    .clk(phi2),
    .atn(serial_atn),
    .clock_i(serial_clock_o),
    .data_i(serial_data_o),
    .clock_o(serial_clock_i),
    .data_o(serial_data_o),
    .rx_byte(iec_rx),
    .rx_ready(iec_ready)
);*/


/* 8kb cartrige */
rom #("mr_tnt.hex",13,8192) carrtrige_rom(
        .clk(clk),
        .a(  Ao[12:0] ),
        .do( rom_data ),
        .enable( ROML )
    );

/*
  rom #("DONKEYKO.HEX",14,16384) carrtrige_rom(
    .clk(clk),
    .a(  { ROML, Ao[12:0]} ),
    .do(rom_data),
    .enable(ROMH | ROML)
  );
*/
`ifdef DMA_TEST
rom #("IKplus.hex",16,47687) test_rom(
        .clk(phi2),
        .a(offset[15:0]),
        .do(data),
        .enable(loading)
    );

always @(posedge phi2 ) begin
    if(!reset) begin
        loading <= 0;
    end else if(loading) begin
        DMA <=1;
        if(!BA) begin
            offset <= offset + 1;
            load_addr <= load_addr + 1;
            if(offset == 47687) loading <=0;
        end
    end else begin
        DMA <= 0;
        if(start_load) begin
            loading <=1;
            offset <= 2;
            load_addr<= 16'h0801;//{prg[0],prg[1]};
        end
    end
end
`endif

reg[7:0] cmd[0:9] ;
integer i;

initial begin
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

    repeat(200000*8) #63 clk = ~clk;
`ifdef DMA_TEST
    $display("START DMA");

    start_load<=1;
    repeat(100*8) #63 clk = ~clk;
    start_load<=0;

    repeat(2000000*8) #63 clk = ~clk;
    repeat(7) #63 clk = ~clk;

    //Now type some suff into the keyboar buffer
    DMA=1;
    loading=1; //For setting write
    for(i=0; i < 5; i=i+1) begin
        load_addr = 631 + i;
        data = cmd[i];
        repeat(8) #63 clk = ~clk;
    end
    load_addr = 198;
    data = 5;
    repeat(8) #63 clk = ~clk;
    DMA=0;
    loading=0; //For setting write

    repeat(8*64*312*8) #63 clk = ~clk;

    DMA=1;
    loading=1; //For setting write
    for(i=0; i < 5; i=i+1) begin
        load_addr = 631 + i;
        data = cmd[5+i];
        repeat(8) #63 clk = ~clk;
    end
    load_addr = 631 + 5;
    data = 8'hd; //Charige return
    repeat(8) #63 clk = ~clk;

    load_addr = 198;
    data = 6;
    repeat(8) #63 clk = ~clk;
    DMA=0;
    loading=0; //For setting write
`endif


    forever  #63 clk = ~clk;

    $display("Done");
    $finish;
end

endmodule
