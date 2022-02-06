module rf_modulator (
    input clk_142mhz, // Color carrier * 32 ie 141.8758
    input [5:0] luma,
    input color,
    input [11:0] audio,
    
    output [3:0] rf_video, //Video RF at 55Mhz VHF channel 3
    output reg [3:0] rf_audio, //Audio RF at 60.5Mhz VHF channel 3
    output reg [5:0] composite //Composite video
);
    //Clock generation
    reg[16:0] rf_acc;
    reg[23:0] audio_acc;
    reg [4:0] rf_video_i;
initial begin
    rf_acc  = 0;
    audio_acc = 0;
end
    assign rf_video = rf_video_i[4:1];

    wire rf_i = rf_acc[15];

    always @(posedge clk_142mhz ) begin
        // Video Carrier wave
        rf_acc <= rf_acc   + 25521;

        // Composite signal    
        composite <= color ? luma + 16 : luma;

        // FM modulated audio at 5.5Mhz + 55.25
        // (gdb) p (1<<24) *(5.5+55.25) / 141.8758
        audio_acc <= audio_acc + 3591930+audio;

        // Modulated RF signal
        // Note this is not SSB modulated, so the bandwith of the 
        // signal is twice what it is supposed to be.
        // Here a hilbert transform or a wiever transform could be used
        // to produce a proper SSB modulation
        rf_video_i <= rf_i ? 31-composite[5:2] : composite[5:2];
    end

    //16 point to 4 bit sine
    always @(*) begin
        case(audio_acc[22:19])
        0 : rf_audio<=  8 ;
        1 : rf_audio<=  10 ;
        2 : rf_audio<=  13 ;
        3 : rf_audio<=  14 ;
        4 : rf_audio<=  15 ;
        5 : rf_audio<=  14 ;
        6 : rf_audio<=  13 ;
        7 : rf_audio<=  10 ;
        8 : rf_audio<=  8 ;
        9 : rf_audio<=  5 ;
        10 : rf_audio<=  2 ;
        11 : rf_audio<=  1 ;
        12 : rf_audio<=  0 ;
        13 : rf_audio<=  1 ;
        14 : rf_audio<=  2 ;
        15 : rf_audio<=  5 ;
        endcase
    end
endmodule