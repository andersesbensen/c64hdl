module sid_voice (
           input clk,
           input reset,
           input[15:0] fcw,
           input[11:0] pw,
           input[7:0]  control,
           input   sync_in,
           output reg sync_out,
           output[11:0] wave
       );
wire sync_c      = control[1];
wire ring_mod_c  = control[2];
wire test_c      = control[3];
wire triangle_c  = control[4];
wire sawtooth_c  = control[5];
wire rectangle_c = control[6];
wire noise_c     = control[7];

reg[23:0] phase;
reg[23:0] shift;

// Sawtooth:
//The output is identical to the upper 12 bits of the accumulator.
wire[11:0] saw_o  = phase[23:12];

// Triangle:
// The upper 12 bits of the accumulator are used.
// The MSB is used to create the falling edge of the triangle by inverting
// the lower 11 bits. The MSB is thrown away and the lower 11 bits are
// left-shifted (half the resolution, full amplitude).
// Ring modulation substitutes the MSB with MSB EOR sync_source MSB.
//
wire saw_phase = ring_mod_c ? sync_in ^ phase[23] : phase[23];
wire[11:0] tri_o  = saw_phase ? {phase[22:12],1'b0} : ~{phase[22:12],1'b0};

// Pulse:
// The upper 12 bits of the accumulator are used.
// These bits are compared to the pulse width register by a 12 bit digital
// comparator; output is either all one or all zero bits.
// NB! The output is actually delayed one cycle after the compare.
// This is not modeled.
//
// The test bit, when set to one, holds the pulse waveform output at 0xfff
// regardless of the pulse width setting.
//
wire[11:0] rect_o = phase[23:12] > pw ? 12'hfff : 12'h000;
reg old_msb;
reg old_bit19;

always @(posedge clk ) begin
    if(reset) begin
        phase    <= 24'h000000;
        shift    <= 24'h7ffff8;
        old_msb  <=0;
        sync_out <=0;
        old_bit19 <=0;
    end

    // No operation if test bit is set.shift_period
    if(!test_c) begin
        old_msb   <= sync_in;
        old_bit19 <= phase[19];
        sync_out  <= phase[23];

        phase   <= (sync_c && (sync_in ^ old_msb)) ? 0 : phase + fcw;
        
        if(old_bit19 ^ phase[19]) begin
            // Noise:
            // The noise output is taken from intermediate bits of a 23-bit shift register
            // which is clocked by bit 19 of the accumulator.
            // NB! The output is actually delayed 2 cycles after bit 19 is set high.
            shift[23:0] <= {shift[22:0],shift[22] ^ shift[17]};
        end
    end
end

wire[11:0] rect_oo = rectangle_c ? rect_o[11:0] : 12'h000;
wire[11:0] tri_oo  =  triangle_c ? tri_o[11:0]  : 12'h000;
wire[11:0] saw_oo  =  sawtooth_c ? saw_o[11:0]  : 12'h000;
wire[11:0] noise_oo = noise_c    ? shift[11:0]  : 12'h000;
assign wave = saw_oo | tri_oo | rect_oo | noise_oo;

endmodule
