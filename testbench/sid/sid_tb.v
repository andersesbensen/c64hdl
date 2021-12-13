
`default_nettype none

`define write_reg(addr,v) \
    we<=1;\
    a<= addr; \
    di <= v; \
    @(posedge clk);\
    we<=0;

module sid_tb;
reg clk;
reg rst_n;
reg[7:0] di;
reg we;
reg[4:0] a;

wire[11:0] audio;


sid sid_e
    (
        .reset (!rst_n),
        .clk (clk),
        .di(di),
        .rw(we),
        .a(a),
        .cs(1'b1),
        .audio(audio)
    );

localparam CLK_PERIOD = 10;
always #(CLK_PERIOD/2) clk=~clk;

initial begin
    $dumpfile("sid_tb.vcd");
    $dumpvars(0, sid_tb);
end


initial begin
    #1 rst_n<=1'bx;clk<=1'bx;
    #(CLK_PERIOD*3) rst_n<=1;
    #(CLK_PERIOD*3) rst_n<=0;clk<=0;
    repeat(5) @(posedge clk);
    rst_n<=1;
    @(posedge clk);

    //voice 1
    `write_reg(8'h00,8'h05) //FREQ  low
    `write_reg(8'h01,8'h24) // FREQ hi
    `write_reg(8'h02,8'h00) //PW lo
    `write_reg(8'h03,8'h08) //PW hi
    `write_reg(8'h04,8'h21) //control
    `write_reg(8'h05,8'he3) //attack decay
    `write_reg(8'h06,8'h36) // sustain release
    //voice 2
    `write_reg(8'h07,8'h05) //FREQ  low
    `write_reg(8'h08,8'h14) // FREQ hi
    `write_reg(8'h09,8'h00) //PW lo
    `write_reg(8'h0a,8'h08) //PW hi
    `write_reg(8'h0b,8'h21) //control
    `write_reg(8'h0c,8'h26) //attack decay
    `write_reg(8'h0d,8'h3a) // sustain release
    //voice 3
    `write_reg(8'h0e,8'h05) //FREQ  low
    `write_reg(8'h0f,8'ha4) // FREQ hi
    `write_reg(8'h10,8'h00) //PW lo
    `write_reg(8'h11,8'h08) //PW hi
    `write_reg(8'h12,8'h21) //control
    `write_reg(8'h13,8'h63) //attack decay
    `write_reg(8'h14,8'h31) // sustain release

    `write_reg(8'h15,8'h08)  //filt low
    `write_reg(8'h16,8'h1f)  //filt hi
    `write_reg(8'h17,8'h17) //#filter route
    `write_reg(8'h18,8'h1f) //Volume and low pass 


    `write_reg(8'h04,8'h41)
    repeat(10000) @(posedge clk);
    `write_reg(8'h0b,8'h41)
    repeat(10000) @(posedge clk);
    `write_reg(8'h12,8'h41)

    repeat(500000) @(posedge clk);
    `write_reg(8'h04,8'h20)
    `write_reg(8'h0b,8'h20)
    `write_reg(8'h12,8'h20)

    repeat(100000) @(posedge clk);


    $finish(2);
end

endmodule
`default_nettype wire
