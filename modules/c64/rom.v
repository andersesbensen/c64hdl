module rom #(
           parameter FILE = "data.bin",
           parameter ADDR_WIDTH = 8,
           parameter RAM_DEPTH = 1 << ADDR_WIDTH
       )
       (
           clk,a,do,enable
       );

input [ADDR_WIDTH-1:0] a;
output reg[7:0] do;
input enable;
input clk;

reg [7:0] rom [RAM_DEPTH-1:0] ;

initial begin
    $readmemh(FILE, rom,0,RAM_DEPTH-1); // memory_list is memory file
    $display("Loaded file %s size %h",FILE,RAM_DEPTH);
end

always @(posedge clk ) begin
    if(enable)
        do <= rom[a];
    else
        do <= 0;
end

endmodule
