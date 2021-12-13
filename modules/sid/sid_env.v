module sid_env (
           input clk,
           input reset,
           input[7:0] attack_decay,
           input[7:0] sustain_release,
           input gate,
           output[7:0] out
       );

reg[15:0] rate_counter;
reg[15:0] rate_period;
reg[7:0] exponential_counter;
reg[7:0] exponential_counter_period;
reg[7:0] envelope_counter;
reg[1:0] state;
reg[3:0] rate;
reg gate_last;

wire[3:0] attack_c  = attack_decay[7:4];
wire[3:0] decay_c   = attack_decay[3:0];
wire[3:0] sustain_c = sustain_release[7:4];
wire[3:0] release_c = sustain_release[3:0];

wire[7:0] sustain_level = {sustain_c,sustain_c};

localparam ATTACK           = 0;
localparam DECAY_SUSTAIN    = 1;
localparam RELEASE          = 2;

assign out = envelope_counter;

always @(*) begin
    case (rate)
        0 : rate_period <=      9;  //   2ms*1.0MHz/256 =     7.81
        1 : rate_period <=     32;  //   8ms*1.0MHz/256 =    31.25
        2 : rate_period <=     63;  //  16ms*1.0MHz/256 =    62.50
        3 : rate_period <=     95;  //  24ms*1.0MHz/256 =    93.75
        4 : rate_period <=    149;  //  38ms*1.0MHz/256 =   148.44
        5 : rate_period <=    220;  //  56ms*1.0MHz/256 =   218.75
        6 : rate_period <=    267;  //  68ms*1.0MHz/256 =   265.63
        7 : rate_period <=    313;  //  80ms*1.0MHz/256 =   312.50
        8 : rate_period <=    392;  // 100ms*1.0MHz/256 =   390.63
        9 : rate_period <=    977;  // 250ms*1.0MHz/256 =   976.56
        10 : rate_period <=   1954;  // 500ms*1.0MHz/256 =  1953.13
        11 : rate_period <=   3126;  // 800ms*1.0MHz/256 =  3125.00
        12: rate_period <=   3907;  //   1 s*1.0MHz/256 =  3906.25
        13 : rate_period <=  11720;  //   3 s*1.0MHz/256 = 11718.75
        14 : rate_period <=  19532;  //   5 s*1.0MHz/256 = 19531.25
        15 : rate_period <=  31251;   //   8 s*1.0MHz/256 = 31250.00
    endcase
end

always @(posedge clk ) begin
    if(reset)
    begin
        envelope_counter <= 0;
        gate_last <= 1;
        rate_counter <=0;
    end else
        gate_last <= gate;

    // Gate Control
    if (gate && !gate_last) begin
        state <= ATTACK;
        rate <= attack_c;
    end else if(!gate && gate_last) begin
        rate <= release_c;
        state <= RELEASE;
    end

    if(rate_counter != rate_period)
        rate_counter <= rate_counter + 1;
    else begin
        rate_counter <= 0;
        if((exponential_counter == exponential_counter_period) || (state == ATTACK)) begin
            exponential_counter <=0;
            case (state)
                ATTACK:
                begin
                    if(envelope_counter == 8'hff) begin
                        state <= DECAY_SUSTAIN;
                        rate  <= sustain_c;
                    end else
                        envelope_counter <= envelope_counter + 1;
                end
                DECAY_SUSTAIN:
                begin
                    if(envelope_counter != sustain_level) begin
                        if(envelope_counter != 0)
                            envelope_counter <= envelope_counter - 1;
                    end
                end
                RELEASE:
                    if(envelope_counter != 0)
                        envelope_counter <= envelope_counter - 1;
            endcase
        end else
            exponential_counter <= exponential_counter + 1;
    end

    case (envelope_counter)
        8'hff: exponential_counter_period <=1;
        8'h5d: exponential_counter_period <=2;
        8'h36: exponential_counter_period <=4;
        8'h1a: exponential_counter_period <=8;
        8'h0e: exponential_counter_period <=16;
        8'h06: exponential_counter_period <=30;
        8'h00: exponential_counter_period <=1;
    endcase
end
endmodule
