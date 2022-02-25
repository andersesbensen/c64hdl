//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 04/03/2018 01:59:34 PM
// Design Name:
// Module Name: c64
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


module c64(
           input color_carrier,
           input dot_clk,
           input reset,
           
           //Composite video and audio
           //This does not exist on a real C64
           output[5:0] composite,
           output[11:0] audio,

           // RF modulator output this has been split up in a
           // Video and an audio part, such that two separate 
           // 4 bit dac can be used.
           output[3:0] rf_video,
           output[3:0] rf_audio,

           //Keyboard connector
           input[7:0] keyboard_COL,
           output[7:0] keyboard_ROW,

           //Cassette connector CN3
           input cass_rd,
           input cass_sense,
           output cass_wrt,
           output cass_motor,

           // Serial Bus CN4
           input  serial_data_i,
           input  serial_clock_i,
           output serial_data_o,
           output serial_clock_o,
           output serial_atn,

           //Joystick 
           input[4:0] joy_a,
           input[4:0] joy_b,

           //Expantion connector
           input INTRES,
           input NMI,
           input RW,
           input IRQ,
           input  [15:0] Ai,
           output [15:0] Ao,
           output BA,
           input DMA,
           input EXTROM_n,
           input GAME_n,
           output ROMH,
           output ROML,
           input[7:0] Di,
           output[7:0] Do,
           output phi2,
           output IO1,
           output IO2,

           output reg[7:0] debug_status,
           output reg debug_status_valid

       );

wire clk;


wire [15:0] bus_address;
wire [15:0] cpu_address;
wire [15:0] vic_address;

wire [7:0] cpu_do;
wire cpu_we;
wire cpu_nmi;
wire cpu_irq;
wire vic_aec;

wire vic_irq;

wire ram_cs;
wire kernal_cs;
wire basic_cs;
wire charrom_cs;
wire colorram_cs;

wire vic_cs;
wire sid_cs;
wire cia1_cs;
wire cia2_cs;
wire cia1_irq_n;
wire cia2_irq_n;

wire [7:0] ram_do;
wire [7:0] kernal_do;
wire [7:0] basic_do;
wire [7:0] charrom_do;
wire [3:0] colorram_do;
wire [7:0] vic_do;
wire [7:0] sid_do;
wire [7:0] cia1_do;
wire [7:0] cia2_do;
wire [7:0] cpu_p;

wire [7:0] cia2_pao;
wire [7:0] cia2_pbo;

wire [7:0] cia2_pai;
wire [7:0] cia2_pbi;


//assign cia1_pai[7:0] = 8'hff;
assign cia2_pai[5:0] = 6'h3f;
assign cia2_pbi[7:0] = 8'hff;

//Serial connector
assign serial_atn     = !cia2_pao[3];
assign serial_clock_o = !cia2_pao[4];
assign serial_data_o  = !cia2_pao[5];
assign cia2_pai[6] = serial_clock_i;
assign cia2_pai[7] = serial_data_i;

assign cpu_irq =  vic_irq | ~cia1_irq_n  ;
assign cpu_nmi =  ~cia2_irq_n;

//Bus control lines
assign    bus_address = vic_aec ? (DMA ? Ai : cpu_address) : vic_address;
wire      bus_we      = vic_aec ? (DMA ? RW : cpu_we ) : 1'b0;
wire[7:0] bus_di      = DMA ? Di : cpu_do;

wire [7:0] bus_do;
assign Do = bus_do;
assign Ao = bus_address;

assign vic_address[15] = ~cia2_pao[1];
assign vic_address[14] = ~cia2_pao[0];

assign phi2 = clk;
wire[7:0] vic_di = vic_aec ? bus_di : bus_do;
wire color;
wire[5:0] luma;
wire GR_W;
assign cass_motor = cpu_p[5];
assign cass_wrt = cpu_p[3];

//Fake a 50 hz clock
reg tod;
reg[15:0] tod_cnt;
always @(posedge clk ) begin
    if(reset) begin
        tod_cnt<=0;
        tod <=0;
    end else if(tod_cnt == 10000) begin
        tod_cnt <=0;
        tod <=!tod;
    end else
        tod_cnt <= tod_cnt + 1;
end

rf_modulator rf_modulator_e(
    .clk_142mhz(color_carrier), // Color carrier * 32 ie 141.8758
    .luma(luma),
    .color(color),
    .audio(audio),
    .rf_video(rf_video), //Video RF at 55Mhz VHF channel 3
    .rf_audio(rf_audio), //Audio RF at 60.5Mhz VHF channel 3
    .composite(composite) //Composite video
);

vicii vicii_e (
           .do(vic_do),
           .di( {colorram_do[3:0], vic_di} ),
           .ai(bus_address[5:0]),
           .ao(vic_address[13:0]),
           .irq_o(vic_irq),
           .lp(1'b0),
           .cs(vic_cs),
           .we(bus_we),
           .ba(BA),
           .color_out(color),
           .sync_lumen(luma),
           .aec(vic_aec),
           .dot_clk(dot_clk),
           .color_clock(color_carrier),
           .phi0(clk),
           .reset(reset)
       );

mos6510 mos6510_e(
            .clk(dot_clk),
            .phi2(phi2),
            .reset(reset),
            .AB(cpu_address),
            .DO(cpu_do),
            .DI(bus_do),
            .WE(cpu_we),
            .IRQ(cpu_irq | IRQ),
            .NMI(cpu_nmi | NMI),
            .RDY(~BA & ~DMA),
            .PO(cpu_p),
            .PI( { 3'b000,cass_sense, 4'b1111} ),
            .AEC(vic_aec)
        );


pla pla_e(
         //Inputs
         .A(bus_address),
         ._LORAM(cpu_p[0]),
         ._HIRAM(cpu_p[1]),
         ._CHAREN(cpu_p[2]),
         ._CAS(1'b0),
         .VA12(vic_address[12]),
         .VA13(vic_address[13]),
         ._VA14(!vic_address[14]),
         ._AEC(!vic_aec),
         .BA(!BA),
         ._GAME( GAME_n),
         ._EXROM( EXTROM_n),
         .R__W(!bus_we),
         //Outputs
         .ROMH( ROMH ),
         .ROML( ROML ),
         .GR_W(GR_W),
         .CHAROM(charrom_cs),
         .KERNAL(kernal_cs),
         .BASIC(basic_cs),
         .CASRAM(ram_cs),
         .CIA1(cia1_cs),
         .CIA2(cia2_cs),
         .SID(sid_cs),
         .VIC(vic_cs),
         .COLOR_RAM(colorram_cs),
         .IO1(IO1),
         .IO2(IO2)
     );

ramr ram_e(
        .reset(reset),
        .clk(dot_clk),
        .a(bus_address),
        .di(bus_di),
        .do(ram_do),
        .enable(ram_cs),
        .we(bus_we)
    );

ramr #(10,4) color_ram(
        .reset(reset),
        .clk(dot_clk),
        .a(bus_address[9:0]),
        .di(bus_di[3:0]),
        .do(colorram_do),
        .enable(colorram_cs | !vic_aec),
        .we(GR_W)
    );

//Hook up joystick
wire[7:0] cia1_pb =  keyboard_COL & {3'b111,joy_a[4:0]};
wire[7:0] cia1_pa =  keyboard_ROW & {3'b111,joy_b[4:0]};

mos6526 cia1 (
            .dot_clk(dot_clk),
            .clk(clk),
            .res_n(!reset),
            .cs_n(!cia1_cs),
            .rw(bus_we),
            .rs(bus_address[3:0]),
            .db_in(bus_di),
            .db_out(cia1_do),

            .pa_in(cia1_pa),
            .pb_in(cia1_pb),
            .pa_out(keyboard_ROW),
            .pb_out(),

            .irq_n(cia1_irq_n),
            .flag_n(cass_rd),
            .pc_n(),
            .tod(tod),
            .sp_in(1),
            .sp_out(),
            .cnt_in(1),
            .cnt_out()
        );

mos6526 cia2 (
            .dot_clk(dot_clk),
            .clk(clk),
            .res_n(!reset),
            .cs_n(!cia2_cs),
            .rw(bus_we),
            .rs(bus_address[3:0]),
            .db_in(bus_di),
            .db_out(cia2_do),
            .pa_in(cia2_pai),
            .pb_in(cia2_pbi),
            .pa_out(cia2_pao),
            .pb_out(cia2_pbo),
            .irq_n(cia2_irq_n),
            .flag_n(),
            .pc_n(),
            .tod(tod),
            .sp_in(1),
            .sp_out(),
            .cnt_in(1),
            .cnt_out()
        );

sid sid_e (
        .dot_clk(dot_clk),
        .clk(clk),
        .reset(reset),
        .cs(sid_cs),
        .do(sid_do),
        .di(bus_di),
        .a(bus_address[4:0]),
        .rw(bus_we),
        .audio(audio)
    );

`ifdef XILINX_SIMULATOR
rom #("kernal.mif",13) kernal (
`else
rom #("kernal_orig.mif",13) kernal (
`endif
        .clk(dot_clk),
        .a(bus_address[12:0]),
        .do(kernal_do),
        .enable(kernal_cs)

    );

rom #("basic.mif",13) basic(
        .clk(dot_clk),
        .a(bus_address[12:0]),
        .do(basic_do),
        .enable(basic_cs)
    );

rom #("chargen.mif",12) chargen(
        .clk(dot_clk),
        .a(bus_address[11:0]),
        .do(charrom_do),
        .enable(charrom_cs)
    );

// U2 5066
wire[7:0] colorram_do_cpu = vic_aec ? {4'b0,colorram_do} : 8'h00;

// Expansion port
wire[7:0] romh_do = (ROMH & !DMA) ? Di : 8'h00;
wire[7:0] roml_do = (ROML & !DMA) ? Di : 8'h00;
wire[7:0] vic_do_mask = vic_aec ? vic_do : 8'b0;
assign bus_do = reset ? 0 : ( ram_do | kernal_do | basic_do | charrom_do | vic_do_mask | cia1_do| cia2_do | sid_do  | colorram_do_cpu | romh_do | roml_do ) ;
always @(posedge clk)
begin
    //The debug status is used by the VICE test suite
    if(bus_we && sid_cs && (bus_address == 16'hD7ff)) 
    begin
        debug_status <= bus_di;
        debug_status_valid <=1;
    end
    else
        debug_status_valid <=0;

    //if(vic_cs || cia1_cs || cia2_cs)
    //    $display("Addr %h do=%h di=%h ram=%h kernal=%b basic=%b char=%b cia1=%b cia2=%b vic=%b we = %b  P=%b aec=%b",
    //             bus_address,bus_do,bus_di,ram_cs,kernal_cs,basic_cs,charrom_cs,cia1_cs,cia2_cs,vic_cs,cpu_we,cpu_p,vic_aec);
end
endmodule
