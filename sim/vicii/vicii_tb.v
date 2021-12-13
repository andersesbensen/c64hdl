`define XILINX_SIMULATOR

`include "../vicii2.v"
`include "../ram.v"
`include "../rom.v"
`include "../vicii_palette.v"
`include "../vicii_sprite.v"

//`timescale 1ns/1ps
`default_nettype none

module tb_vicii2();
reg clk;
reg rst_n;
wire phi0;
wire[13:0] vic_aout;
reg[13:0] cpu_addr;

wire[11:0] data_ram;
wire[7:0] data_rom;
reg ram_we;
wire aec;
reg[11:0] vic_di;
reg vic_cs;
reg vic_we;
reg[11:0] vic_ain;

wire[5:0]  video;
wire ba;
integer i;

reg[7:0] test_rom[16'hffff:0];

wire[11:0] vic_data = aec ? vic_di : data_ram | {4'b0,data_rom};
wire[13:0] bus_addr = aec ? cpu_addr : vic_aout;

//assign data_rom = 0;
//assign data_ram = {4'b1000,test_rom[bus_addr]};
ram #(.ADDR_WIDTH(12),.DATA_WIDTH(12)) my_ram1
    (
        .clk(clk),
        .enable( !bus_addr[12] ),
        .we( ram_we ),
        .a( bus_addr[11:0] ),
        .di( vic_di ),
        .do( data_ram )
    );

rom #("chargen.hex",12) chargen(
        .clk(clk),
        .a( bus_addr[11:0]),
        .do( data_rom[7:0] ),
        .enable( bus_addr[12] )
    );


vicii2 my_vic
       (
           .aec( aec ),
           .reset ( !rst_n ),
           .pixel_clock (clk),
           .color_clock(clk),
           .phi0(phi0),
           .ao( vic_aout ),
           .ai( vic_ain[5:0]),
           .di( vic_data ),
           .cs( vic_cs ),
           .we( vic_we ),
           .ba(ba),
           .sync_lumen(video)
       );

localparam CLK_PERIOD = 10;
always #(CLK_PERIOD/2) clk=~clk;

initial begin
    $dumpfile("tb_vicii2.vcd");
    $dumpvars(0, tb_vicii2);
    $readmemh("start_screen.hex",test_rom);
end

initial begin
    #1 rst_n<=1'bx;clk<=1'bx;
    vic_cs <=0;
    vic_we <=0;
    ram_we <=0;
    vic_ain <=0;
    #(CLK_PERIOD*3) rst_n<=1;
    #(CLK_PERIOD*3) rst_n<=0;clk<=0;


    ram_we <= 1;
    for (i =0  ; i < 1000;i=i+1 ) begin
        cpu_addr = i[11:0];
        vic_di = 12'h800 | i[7:0];
        repeat(8) @(posedge clk);
    end
    ram_we <=0;


    repeat(8) @(posedge clk);
    rst_n<=1;
    @(posedge clk);

    vic_cs <=1;
    vic_we <=1;


    /*for(i = 16'hd000; i< 16'hd030; i=i+1) begin
      vic_ain <= i;
      vic_di  <=  test_rom[i];
      repeat(8) @(posedge clk);
    end*/
    // //Write VM and CB pointers
    vic_ain <= 12'h18;
    vic_di  <=  8'h04;
    repeat(8) @(posedge clk);

    // //Write EC
    vic_ain <= 12'h20;
    vic_di  <= 12'he;
    repeat(8) @(posedge clk);

    // //Write B0
    vic_ain <= 12'h21;
    vic_di  <= 6'h00;
    repeat(8) @(posedge clk);


    //Write BLNK BMM
    vic_ain <= 12'h11;
    vic_di  <= 8'h98;
    repeat(8) @(posedge clk);

    // //Write MCM
    vic_ain <= 12'h16;
    vic_di  <= 8'hc8;
    repeat(8) @(posedge clk);

    vic_we <= 0;
    vic_di  <= 8'h00;

    repeat(320000) @(posedge clk);
    $finish(2);
end

endmodule
`default_nettype wire
