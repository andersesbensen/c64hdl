/**
* Toplevel module for the Nexyx4 board
*/
module nexys4_c64 (
           input clk_i ,
           input rstn_i ,
           // push-buttons
           input btnl_i ,
           input btnc_i ,
           input btnr_i ,
           input btnd_i ,
           input btnu_i ,
           // switches
           input[15:0] sw_i,
           // 7-segment display
           output[6:0] disp_seg_o,
           output dp,
           output[7:0] disp_an_o,
           // leds
           output[15:0] led_o,
           // RGB leds
           output rgb1_red_o,
           output rgb1_green_o,
           output rgb1_blue_o,
           output rgb2_red_o,
           output rgb2_green_o,
           output rgb2_blue_o,
           // VGA display
           output vga_hs_o,
           output vga_vs_o,
           output[3:0] vga_red_o,
           output[3:0] vga_blue_o,
           output[3:0] vga_green_o,
           // PDM microphone
           //output pdm_clk_o,
           //input pdm_data_i ,
           //output pdm_lrsel_o,
           // PWM audio
           output pwm_audio_o,
           output pwm_sdaudio_o,
           // Temperature sensor
           //inout tmp_scl,
           //inout tmp_sda,
           //--		tmp_int        : in std_logic; // Not used in this project
           ///--		tmp_ct         : in std_logic; // Not used in this project
           // SPI Interface signals for the ADXL362 accelerometer
           //output sclk,
           //output mosi,
           //input miso,
           //output ss,
           // PS2 interface signals
           input ps2_clk,
           input ps2_data,

           // Debug output signals
           //      output SCLK_DBG,
           //      output MOSI_DBG,
           //      output MISO_DBG,
           //      output SS_DBG,

           //      output PS2C_DBG,
           //      output PS2D_DBG,

           // DDR2 interface signals
           //      output[12:0] ddr2_addr,
           //      output[2:0] ddr2_ba,
           //      output ddr2_ras_n,
           //      output ddr2_cas_n,
           //      output ddr2_we_n ,
           //      output ddr2_ck_p,
           //      output ddr2_ck_n,
           //      output ddr2_cke ,
           //      output ddr2_cs_n,
           //      output[1:0] ddr2_dm,
           //      output ddr2_odt ,
           //      inout[15:0] ddr2_dq,
           //      inout[1:0] ddr2_dqs_p,
           //      inout[1:0] ddr2_dqs_n,


        //IEC port
        input iec_clock_i,
        input iec_data_i,
        output iec_clock_o,
        output iec_data_o,
        output iec_atn_o,

        //UART
        input RsRx,
        output RsTx

       );

//color_clk_out 35.46895
// dot_clk_out 7.8799999999999999

wire[7:0] kk_c;
wire[7:0] kk_r;

wire lock;
wire reset;
wire phi2;
wire[5:0] composite;
wire[11:0] audio;
wire[7:0] cart_data;

/*CPU Bus signals*/
wire ROMH;
wire ROML;
wire[7:0] Do;
wire[7:0] Di;
wire BA;
wire DMA;
wire WE;
wire[15:0] Ai;
wire[15:0] Ao;

wire ps2byte_ready;
wire[7:0] ps2byte;

wire serial_clock_i;
wire serial_data_i;

assign vga_red_o = composite[5:2];
assign reset = ~rstn_i;

reg debug_ack;
reg debug_dma;
reg[7:0] DoL; //Latch Do when changing clock domain

wire[7:0] debug_do;  
reg[7:0] debug_do_l; //Latch Do when changing clock domain

wire[7:0] cart_do;  

wire debug_request;
wire reset_request;

assign DMA = debug_dma;

wire color_clk;
wire dot_clk;



assign led_o[2] = ROML;
assign led_o[3] = ROMH;
assign led_o[4] = (reset | ~lock);
assign led_o[5] = ps2byte_ready;
assign led_o[6] = !ps2_clk;
assign led_o[7] = !ps2_data;
assign led_o[8] = BA;
assign led_o[13:9] = 12'h0;
assign led_o[14] = debug_request;
assign led_o[15] = DMA;

/******************************** Seven Segment Display ****************** */
wire[6:0] disp_seg;
wire[7:0] disp_an;
assign disp_seg_o[6:0] = ~disp_seg[6:0];
assign disp_an_o[7:0] = ~disp_an[7:0];

wire[7:0] debug_tx_byte;
wire debug_tx_byte_valid;
wire[7:0] debug_rx_byte;
wire debug_rx_byte_valid;

wire[7:0] iec_tx_byte;
wire iec_tx_byte_valid;
wire[7:0] iec_rx_byte;
wire iec_rx_byte_valid;

// Switch 14 flips uart between bus debug and IEC
wire      uart_rx_byte_valid;
wire[7:0] uart_rx_byte;
wire      uart_tx_byte_valid;
wire[7:0] uart_tx_byte;

assign uart_tx_byte_valid  =  sw_i[14]  ? debug_tx_byte_valid : iec_tx_byte_valid;
assign uart_tx_byte        =  sw_i[14]  ? debug_tx_byte       : iec_tx_byte;
assign debug_rx_byte       =  sw_i[14] ? uart_rx_byte : 0;
assign debug_rx_byte_valid =  sw_i[14] ? uart_rx_byte_valid : 0;
assign iec_rx_byte         = !sw_i[14] ? uart_rx_byte : 0;
assign iec_rx_byte_valid   = !sw_i[14] ? uart_rx_byte_valid : 0;

//Debug status register
wire[7:0] debug_status;
reg debug_status_reg_assigned;

//Clock generation
// color clock must be 141Mhz = 4.43mhz *32
clock_gen clock_gen_i (
    .reset(reset),
    .clk(color_clk),
    .dot_clock(dot_clk)
);

hex7segment u_hex7segment(
                .clk(dot_clk),
                .reset(reset),
                .disp_seg(disp_seg),
                .disp_an(disp_an),
                .segment_number( {debug_status,iec_tx_byte,Ao[15:0]} )
            );

clock_clk_wiz_0_0_clk_wiz clock_i
      (.clk_in1(clk_i),
       .clk_color(color_clk),
       .locked(lock),
       .reset(1'b0));

uart_rx uart_rx_i (
            .i_Clock(dot_clk),
            .i_Rx_Serial(RsRx),
            .o_Rx_DV(uart_rx_byte_valid),
            .o_Rx_Byte(uart_rx_byte)
        );

wire[7:0] actual_uart_tx_byte = uart_tx_byte_valid ? uart_tx_byte : debug_status;
wire actual_uart_tx_byte_valid = debug_status_reg_assigned || uart_tx_byte_valid;

always @(posedge phi2 ) begin
    debug_status_reg_assigned <= (Ao == 16'hD7ff) ? 1 : 0;
end

uart_tx uart_tx_i (
            .i_Clock(dot_clk),
            .i_Tx_DV( uart_tx_byte_valid ),
            .i_Tx_Byte( uart_tx_byte ),
            .o_Tx_Serial(RsTx),
            .o_Tx_Active(),
            .o_Tx_Done()
        );

ps2host ps2host_i(
            .clk(dot_clk),
            .reset(reset),
            .ps2c(ps2_clk) ,
            .ps2d(ps2_data),
            .rx_en(1'b1),
            .rx_done_tick(ps2byte_ready),
            .rx_data(ps2byte)
        );

keyboard keyboard_i(
             .reset(reset | ~lock),
             .clk(dot_clk),
             .data(ps2byte),
             .data_rdy(ps2byte_ready),
             .scan_in(kk_r),
             .scan_out(kk_c)
         );

iec iec_e (
    .reset(reset),

    .clk(phi2),
    .atn(serial_atn),
    .clock_i(serial_clock_o),
    .clock_o(serial_clock_i),
    .data_o(serial_data_i),
    .data_i(serial_data_o),

    .rx_byte(iec_tx_byte),
    .rx_ready(iec_tx_byte_valid),
    .tx_byte(iec_rx_byte),
    .tx_ready(iec_rx_byte_valid)
);


/*assign serial_data_i = iec_data_i;
assign serial_clock_i = iec_clock_i;
assign iec_clock_o = serial_clock_o;
assign iec_data_o = serial_data_o;
assign iec_atn_o = serial_atn;
*/
    
c64_debug c64_debug_i(
              .clk(dot_clk),
              .reset(reset),
              .uart_rx_byte_valid(debug_rx_byte_valid),
              .uart_rx_byte(debug_rx_byte),
              .uart_tx_byte_valid(debug_tx_byte_valid),
              .uart_tx_byte(debug_tx_byte),
              .debug_data_i(DoL),
              .debug_data_o(debug_do),
              .debug_addr(Ai),
              .debug_we(WE),
              .debug_request(debug_request),
              .debug_ack(debug_ack),
              .reset_request(reset_request)
          );

always @(negedge phi2 ) begin
    DoL <= Do;
    debug_do_l <= debug_do;
end

always @(posedge phi2 ) begin
    if(reset)
        debug_dma <=0;
    else if(!BA)
        debug_dma <= debug_request;
    
    if(debug_dma) begin
        debug_ack <= !BA;
    end    
    else
        debug_ack <= 0;

end

assign Di = DMA ? debug_do_l : cart_data;
wire[4:0] joyA =  sw_i[15] ?  5'b11111 : { !btnc_i , !btnr_i, !btnl_i,!btnd_i, !btnu_i };
wire[4:0] joyB = !sw_i[15] ?  5'b11111 : { !btnc_i , !btnr_i, !btnl_i,!btnd_i, !btnu_i };

c64 c64_e(
        .color_carrier(color_clk),
        .dot_clk(dot_clk ),
        .reset(reset | reset_request ),
        .composite(composite),
        .rf_audio(vga_green_o),
        .rf_video(vga_blue_o),
        .audio(audio),
        .keyboard_COL( kk_c ),
        .keyboard_ROW( kk_r ),
        .cass_sense(sw_i[2]),
        .cass_rd(sw_i[3]),
        .cass_motor(led_o[0]),
        .cass_wrt(led_o[1]),

        .INTRES(1'b0),
        .NMI(1'b0),
        .IRQ(1'b0),
        .Ai(Ai),
        .Ao(Ao),
        .ROML(ROML),
        .ROMH(ROMH),
        .DMA(DMA),
        .Di(Di),
        .RW(WE),
        .GAME_n(sw_i[0]),
        .EXTROM_n(sw_i[1]),

        .phi2(phi2),

        //IEC Serial port
        .serial_clock_i(serial_clock_i),
        .serial_data_i(serial_data_i),
        .serial_data_o(serial_data_o),
        .serial_clock_o(serial_clock_o),
        .serial_atn(serial_atn),
      
        //Joystick
        //         f         r     l        d        u
        .joy_a( joyA ),
        .joy_b( joyB ),
        .BA(BA),
        .Do(Do),
        .IO1(),
        .IO2(),
        .debug_status(debug_status)
    );

/* PDM modulatio*/
reg[14:0] pdm_acc;
assign pwm_sdaudio_o = !reset ;
assign pwm_audio_o = pdm_acc[14];
always @(posedge color_clk ) begin
    if(pdm_acc[14]) begin
        pdm_acc = pdm_acc & 15'b011111111111111;
    end else begin
        pdm_acc <= pdm_acc + audio;
    end
end


/* 8kb cartrige */
rom #("diag.mif",13,8192) carrtrige_rom(
        .clk(dot_clk),
        .a(  Ao[12:0] ),
        .do( cart_data ),
        .enable( ROML )
    );


endmodule
