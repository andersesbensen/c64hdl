// Copyright 2022 Anders Lynge Esbensen. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

module ramr
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
           output[DATA_WIDTH-1:0] do
       );
localparam  RAM_DEPTH = 1 << ADDR_WIDTH;
reg[DATA_WIDTH-1:0] mem  [RAM_DEPTH-1:0];
reg[ADDR_WIDTH-1:0] r;

initial begin
    r = 0;
end

wire[ADDR_WIDTH-1:0]  _a = reset ? r : a;
wire  _we = reset ? 1 : we;
wire[DATA_WIDTH-1:0]  _di = reset ? 
    (_a[2] ? (DATA_WIDTH-1) : 0) : di; 

/*always @(clk,reset) begin
    if(reset) r <= r + 1;
end
*/
ram #(ADDR_WIDTH,DATA_WIDTH) ram_e (
    .clk(clk),
    .a(_a),
    .we(_we),
    .di(_di),
    .do(do),
    .enable(enable)
);

endmodule
