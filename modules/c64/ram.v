// Copyright 2022 Anders Lynge Esbensen. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

module ram
       #(
           parameter ADDR_WIDTH = 16 ,
           parameter DATA_WIDTH = 8
       )
       (
           input clk,
           input enable,
           input reset,
           input we,

           input [ADDR_WIDTH-1:0] a,
           input [DATA_WIDTH-1:0] di,
           output reg[DATA_WIDTH-1:0] do
       );
localparam  RAM_DEPTH = 1 << ADDR_WIDTH;
reg[DATA_WIDTH-1:0] mem  [RAM_DEPTH-1:0];
integer i;

wire wr = enable & we;

initial begin
`ifdef XILINX_SIMULATOR
    for (i =0  ; i < RAM_DEPTH ;i=i+1 ) begin
        mem[i] = 22;
    end
`endif

end

always @(posedge clk) begin
    if(wr) begin
        mem[a] <= di;
        do <= 0;
    end else if(enable)
        do <= mem[a];
    else
        do <=0;
end

endmodule
