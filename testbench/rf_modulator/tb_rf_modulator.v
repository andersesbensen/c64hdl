// Copyright 2022 Anders Lynge Esbensen. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.


`timescale 1ns/1ns

module tb_rf_modulator;
reg clk;
reg rst_n;

wire [5:0] video;
wire[6:0] rf;

//Accumulate 3 signals
// Color 
// VSYNC
// HSYNC

reg [31:0] color_acc;
reg [31:0] vsync_acc;
reg [31:0] hsync_acc;

//Make dummy signal
always @(posedge clk ) begin
    if(!rst_n) begin
        color_acc <=0;
        vsync_acc <=0;
        hsync_acc <=0;
    end else begin
        color_acc<= color_acc + 512035;
        vsync_acc<= vsync_acc + 18477;
        hsync_acc<= hsync_acc + 59;        
    end
end
assign video = 2*color_acc[15] + (hsync_acc[15] | hsync_acc[15])<<4;

waever waever1(
    .clk(clk),
    .reset(!rst_n),
    .video(video),
    .rf(rf)
);


localparam CLK_PERIOD = 6;
always #(CLK_PERIOD/2) clk=~clk;

integer file;

initial begin
    file = $fopen("rf.dat","wb");
    $dumpfile("tb_rf_modulator.vcd");
    $dumpvars(0, tb_rf_modulator);
end

always @(posedge clk ) begin
    $fwrite(file, "%u", rf);
end
initial begin
    #1 rst_n<=1'bx;clk<=1'bx;
    #(CLK_PERIOD*3) rst_n<=1;
    #(CLK_PERIOD*3) rst_n<=0;clk<=0;
    repeat(5) @(posedge clk);
    rst_n<=1;
    @(posedge clk);
    repeat(1000000) @(posedge clk);
    $finish(2);
end

endmodule
`default_nettype wire