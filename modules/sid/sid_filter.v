module sid_filter (
           input clk,
           input reset,
           input[3:0] resonance,
           input[10:0] fc,
           input [11:0] in,
           input high_pass,
           input low_pass,
           input band_pass,
           output reg [11:0] out
       );
reg signed [31:0] Vbp;
reg signed [31:0] Vhp;
reg signed [31:0] Vlp;
reg signed [17:0] w0;
reg signed [17:0] Q;

always @(*) begin
    case( resonance )
        0: Q <= 1448 ;
        1: Q <= 1323 ;
        2: Q <= 1218;
        3: Q <= 1128 ;
        4: Q <= 1051 ;
        5: Q <=  984 ;
        6: Q <=  925 ;
        7: Q <=  872 ;
        8: Q <=  825 ;
        9: Q <=  783 ;
        10: Q <=  745 ;
        11: Q <=  710 ;
        12: Q <=  679 ;
        13: Q <=  650 ;
        14: Q <=  624 ;
        15: Q <=  599 ;
    endcase
end

always @(posedge clk ) begin
    if(reset) begin
        Vbp <=0;
        Vlp <=0;
        Vhp <=0;
    end else begin
        Vbp <= Vbp - ((w0*Vhp) >>> 20);
        Vlp <= Vlp - ((w0*Vbp) >>> 20);
        Vhp <= $signed((Vbp * Q) >>> 10) - Vlp + (in ) ;
    end

    // Set limit w0 to keep filter stable, see resid source for details
    // w0max =2*np.pi*16000*1.048576
    // fcmax = int((w0max - 797) /40)
    w0  <= fc*41 + 797;

    out <= (high_pass ? ((Vhp)+1024) : 0 +
            low_pass  ? ((Vlp)+1024) : 0 +
            band_pass ? ((Vbp)+1024) : 0);
end
endmodule
