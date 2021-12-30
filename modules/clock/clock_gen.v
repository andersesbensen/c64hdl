
/*
* This module derives the needed clocks for the C64 from 
* the highspeed 4.43Mhz*32 color carrier. The actual 
* clock generator for the C64 creates the dot_clock and the 
* color clock from a 14mhz crystal, however we need the
* opscaled clock to provide a 5 bit color phase resolution
* I could have used a slower color clock if I used more 
* bits for the color carrier. 
*
* The C64 does not hav a "real" RF clock, it uses a RLC oscilator
* in the RF modulator to produce the RF if and the 5.5Mhz color 
* carriers. 
*/

module clock_gen  (
    input clk, //Color clock must be  = 141.8758Mhz
    input reset,
    output rf_i, //60Mhz RF
    output rf_q, //60Mhz RF phase shifted by 90deg
    output dot_clock, // 8Mhz dotclock
    output audio_clock // 5.5 Mhz audio carrier for PAL B
);

//Clock generation
reg[16:0] rf_acc_i;
reg[16:0] rf_acc_q;
reg[16:0] dot_acc;
reg[16:0] audio_acc;

initial begin
    dot_acc   <= 0;
    audio_acc <= 0;    
    rf_acc_i  <= 0;
    rf_acc_q  <= 16384; //90 degrees phase shift

end

assign rf_i = rf_acc_i[15];
assign rf_q = rf_acc_q[15];
assign dot_clock = dot_acc[15];
assign audio_clock = audio_acc[15];

always @(posedge clk ) begin
    rf_acc_i <= rf_acc_i   + 28639;
    rf_acc_q <= rf_acc_q   + 28639;
    dot_acc <= dot_acc     + 3640;
    audio_acc <= audio_acc + 2541;
end


endmodule