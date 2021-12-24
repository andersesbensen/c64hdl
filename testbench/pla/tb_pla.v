
`default_nettype none

module tb_pla;
reg clk;
reg rst_n;
reg[2:0] P;
reg[15:0] ADDR;
reg[14:0] VADDR;
reg AEC;
reg BA;
reg GAME_n;
reg EXTROM_n;
reg RW;


integer i;
integer j;

pla pla_e
(
    .A(ADDR),
    ._LORAM(P[0]),
    ._HIRAM(P[1]),
    ._CHAREN(P[2]),
    ._CAS(1'b0),
    .VA12(VADDR[12]),
    .VA13(VADDR[13]),
    ._VA14(!VADDR[14]),
    ._AEC(AEC),
    .BA(BA),
    ._GAME( GAME_n),
    ._EXROM( EXTROM_n),
    .R__W(!RW)
);

localparam CLK_PERIOD = 10;
always #(CLK_PERIOD/2) clk=~clk;


initial begin
    $dumpfile("tb_pla.vcd");
    $dumpvars(0, tb_pla);
end

initial begin
    P<=0;
    VADDR<=0;
    ADDR<=0;
    AEC <=0;
    BA<=0;
    GAME_n<=1;
    EXTROM_n<=1;
    RW<=0;
    

    #1 rst_n<=1'bx;clk<=1'bx;
    #(CLK_PERIOD*3) rst_n<=1;
    #(CLK_PERIOD*3) rst_n<=0;clk<=0;
    repeat(5) @(posedge clk);
    rst_n<=1;
    @(posedge clk);
    repeat(2) @(posedge clk);
    
    for(i=0; i < 7; i=i+1) begin
        P <= i;
        for(j=0; j < 16; j=j+1) begin
            ADDR <= j <<12;
            repeat(2) @(posedge clk);
        end
    end

    $finish(2);
end

endmodule
`default_nettype wire