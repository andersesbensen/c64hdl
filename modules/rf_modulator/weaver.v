module waever (
    input clk,
    input reset,
    input[5:0] video,
    output reg[6:0] rf
);
    reg signed [6:0] zb_i; //Signal frequency shifted to 0 hz
    reg signed [6:0] zb_q;
    wire signed [6:0] zb_i_f; //zero hz filtered signal
    wire signed [6:0] zb_q_f;

    reg[15:0] zb_acc_i;
    reg[15:0] zb_acc_q;

    reg[16:0] w_acc_i;
    reg[16:0] w_acc_q;
    
    reg signed[6:0] w_i; //Signal frequency shifted up to desired if
    reg signed[6:0] w_q;


    // Badwith is set to 5Mhz
    //(gdb) p (1<<16) * (5/2.0) / 141.8758
    //$25 = 1154.8128715397552

    always @(posedge clk ) begin
        if(reset) begin
            zb_acc_i <=0;    
            zb_acc_q <= (1<<14);    
            zb_i <= 0;
            zb_q <= 0;
        end else begin
            zb_acc_i = zb_acc_i + 1155;
            zb_acc_q = zb_acc_q + 1155;

            zb_i <= zb_acc_i[15] ? video : -video;
            zb_q <= zb_acc_q[15] ? video : -video;            
        end

    end

    //Filter the shifted signal
    filter f_i(
        .clk(clk),
        .reset(reset),
        .x0( zb_i ),
        .out(zb_i_f)
    );

    filter f_q(
        .clk(clk),
        .reset(reset),
        .x0( zb_q ),
        .out(zb_q_f)
    );


    //Freqyency shift signal to desired RF
    //(gdb) p (1<<16) * (62.0+5/2.0) / 141.8758
    //$1 = 29794.172085725684
    wire w_i_clk = w_acc_i[15];
    wire w_q_clk = w_acc_q[15];

    always @(posedge clk ) begin
        if(reset) begin
            w_acc_i <=0;    
            w_acc_q <= (1<<14);    
        end else begin
            w_acc_i <= w_acc_i + 25521;
            w_acc_q <= w_acc_q + 25521;

            w_i <= w_acc_i[15] ? zb_i_f : -zb_i_f;
            w_q <= w_acc_q[15] ? zb_q_f : -zb_q_f;

            //Add signals to produce SSB
            rf <= 63 + w_i - w_q;
        end
    end

endmodule