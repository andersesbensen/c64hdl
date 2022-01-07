
module sid (
           input dot_clk,
           input clk,
           input reset,
           input cs,
           input rw,
           input [4:0]  a,
           input [7:0] di,
           output [7:0] do,

           output reg [11:0] audio
       );
integer i;
reg [7:0] do_reg;
reg[7:0] r[31:0];

wire[11:0] wave1;
wire[11:0] wave2;
wire[11:0] wave3;
wire sync1;
wire sync2;
wire sync3;

wire[7:0] env1;
wire[7:0] env2;
wire[7:0] env3;
wire[11:0] flt_out;

reg[19:0] wave1_env;
reg[19:0] wave2_env;
reg[19:0] wave3_env;
reg[21:0] flt_in;
reg[21:0] audio_output;

wire[11:0]  flt_fc = {r[22][7:0],r[21][3:0]};
wire       flt1 = r[23][0];
wire       flt2 = r[23][1];
wire       flt3 = r[23][2];
wire       flte = r[23][3];
wire[3:0]  flt_res = r[23][7:4];

wire[3:0] vol  = r[24][3:0];
wire low_pass  = r[24][4];
wire band_pass = r[24][5];
wire high_pass = r[24][6];
wire mute3     = r[24][7];

assign do = cs ? do_reg : 0;

sid_filter flt_e (
               .clk(clk),
               .reset(reset),
               .resonance(flt_res),
               .fc(flt_fc),
               .in(flt_in[21:10]),
               .high_pass(high_pass),
               .low_pass(low_pass),
               .band_pass(band_pass),
               .out(flt_out)
           );

sid_voice voice1 (
              .clk(clk),
              .reset(reset),
              .fcw( {r[1][7:0],r[0][7:0]}),
              .pw ( {r[3][3:0],r[2][7:0]}),
              .control(r[4]),
              .sync_in(sync3),
              .sync_out(sync1),
              .wave(wave1)
          );

sid_env envelope1 (
            .clk(clk),
            .reset(reset),
            .attack_decay( r[5] ),
            .sustain_release( r[6] ),
            .gate( r[4][0] ),
            .out(env1)
        );

sid_voice voice2 (
              .clk(clk),
              .reset(reset),
              .fcw( {r[8][7:0],r[7][7:0]}),
              .pw ( {r[10][3:0],r[9][7:0]}),
              .control(r[11]),
              .sync_in(sync1),
              .sync_out(sync2),
              .wave(wave2)
          );

sid_env envelope2 (
            .clk(clk),
            .reset(reset),
            .attack_decay( r[12] ),
            .sustain_release( r[13] ),
            .gate( r[11][0] ),
            .out(env2)
        );

sid_voice voice3 (
              .clk(clk),
              .reset(reset),
              .fcw( {r[15][7:0],r[14][7:0]}),
              .pw ( {r[17][3:0],r[16][7:0]}),
              .control(r[18]),
              .sync_in(sync2),
              .sync_out(sync3),
              .wave(wave3)
          );

sid_env envelope3 (
            .clk(clk),
            .reset(reset),
            .attack_decay( r[19] ),
            .sustain_release( r[20] ),
            .gate( r[18][0] ),
            .out(env3)
        );

always @(negedge clk ) begin
    if(cs && !rw && !reset)
        do_reg <= r[a];
    else 
        do_reg<= 0;
end

always @(posedge clk ) begin
    if(reset) begin
        for(i =0; i < 32; i=i+1) r[i]<=0;
    end

    if(rw && cs) begin
        r[a] <= di;
    end

    wave1_env <= wave1 * env1;
    wave2_env <= wave2 * env2;
    wave3_env <= wave3 * env3;

    //Audio output with a little bias
    flt_in <=
           (flt1 ? wave1_env : 0) +
           (flt2 ? wave2_env : 0) +
           (flt3 ? wave3_env : 0);

    audio_output <= (
                     (flt1 ? 0 : wave1_env) +
                     (flt2 ? 0 : wave2_env) +
                     (flt3 || mute3 ? 0 :  wave3_env ) +
                     (flt_out<<8)  ) ;
    audio <=  (vol * audio_output[21:14]);
end
endmodule
