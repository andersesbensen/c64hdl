
//`timescale 1ns/1ps
`default_nettype none

module vicii_tb();
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
reg[7:0] test_regs[16'h2f:0];
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

rom #("../../assets/chargen.mif",12) chargen(
        .clk(clk),
        .a( bus_addr[11:0]),
        .do( data_rom[7:0] ),
        .enable( bus_addr[12] )
    );


vicii my_vic
       (
           .aec( aec ),
           .reset ( !rst_n ),
           .dot_clk (clk),
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
    $dumpfile("vicii_tb.vcd");
    $dumpvars(0, vicii_tb);
    $readmemh("start_screen.mif",test_rom);
end

initial begin
    #1 rst_n<=1'bx;clk<=1'bx;
    vic_cs <=0;
    vic_we <=0;
    ram_we <=0;
    vic_ain <=0;
    #(CLK_PERIOD*3) rst_n<=1;
    #(CLK_PERIOD*3) rst_n<=0;clk<=0;

    for(i = 0; i< 16'h2f; i=i+1) begin
        vic_ain <= i;
        test_regs[i]  = 0;
    end

    test_regs[12'h18] = 8'h04;
    test_regs[12'h12] = 8'h0e;  //Raster watch
    test_regs[12'h11] = 8'h18;
    test_regs[12'h16] = 8'hc8;
    test_regs[12'h20] = 8'h0c; // Edge color

    test_regs[12'h1A] = 8'h01; //Enable raster watch

    test_regs[12'h00] = 8'h28; //Sprite X
    test_regs[12'h01] = 8'h30; //Sprite Y
    test_regs[12'h02] = 8'h2e; //Sprite X
    test_regs[12'h03] = 8'h40; //Sprite Y
    test_regs[12'h04] = 8'h60; //Sprite X
    test_regs[12'h05] = 8'h60; //Sprite Y
    test_regs[12'h06] = 8'h80; //Sprite X
    test_regs[12'h07] = 8'h80; //Sprite Y
    test_regs[12'h08] = 8'ha0; //Sprite X
    test_regs[12'h09] = 8'ha0; //Sprite Y
    test_regs[12'h0a] = 8'hc0; //Sprite X
    test_regs[12'h0b] = 8'hc0; //Sprite Y
    test_regs[12'h0c] = 8'he0; //Sprite X
    test_regs[12'h0d] = 8'he0; //Sprite Y
    test_regs[12'h0e] = 8'h20; //Sprite X
    test_regs[12'h0f] = 8'he0; //Sprite Y

    test_regs[12'h10] = 8'hff; //Sprite X MSB
    
    
    test_regs[12'h15] = 8'hff; //Sprite enable
    test_regs[12'h17] = 8'h00; //Expand Y
    test_regs[12'h1B] = 8'h00; //MIB data prio
    test_regs[12'h1C] = 8'h00; //Multi color sprite
    test_regs[12'h1D] = 8'h00; //Expand X
    
    test_regs[12'h27] = 8'h03; //MIB Color
    test_regs[12'h28] = 8'h09; //MIB Color
    test_regs[12'h29] = 8'h03; //MIB Color
    test_regs[12'h2a] = 8'h04; //MIB Color
    test_regs[12'h2b] = 8'h05; //MIB Color
    test_regs[12'h2c] = 8'h06; //MIB Color
    test_regs[12'h2d] = 8'h07; //MIB Color
    test_regs[12'h2e] = 8'h08; //MIB Color



    ram_we <= 1;
    for (i =0  ; i < 1000;i=i+1 ) begin
        cpu_addr = i[11:0];
        vic_di = {4'h01, i[7:0]};
        repeat(8) @(posedge clk);
    end
    ram_we <=0;


    repeat(8) @(posedge clk);
    rst_n<=1;
    @(posedge clk);


    vic_cs <=1;
    vic_we <=1;

    for(i = 0; i< 16'h2f; i=i+1) begin
        vic_ain <= i;
        vic_di  <=  test_regs[i];
        repeat(8) @(posedge clk);
    end

    vic_cs <=0;
    vic_we <=0;

    repeat(160000) @(posedge clk);


    vic_cs <=1;
    vic_we <=1;

    //Clear RST interrupt
    vic_ain <= 8'h19;
    vic_di  <=  1;
    repeat(8) @(posedge clk);

    vic_cs <=0;
    vic_we <=0;


    repeat(220000) @(posedge clk);
    $finish(2);
end

endmodule
`default_nettype wire
