// Copyright 1986-2021 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2021.1.1 (lin64) Build 3286242 Wed Jul 28 13:09:46 MDT 2021
// Date        : Sun Nov 21 00:16:44 2021
// Host        : aes-Lenovo-Legion-5-15ARH05H running 64-bit Ubuntu 20.04.3 LTS
// Command     : write_verilog -force -mode synth_stub
//               /home/aes/Kode/c64hdl/c64hdl.gen/sources_1/bd/clock/ip/clock_clk_wiz_0_0/clock_clk_wiz_0_0_stub.v
// Design      : clock_clk_wiz_0_0
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a100tcsg324-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
module clock_clk_wiz_0_0(clk_dot, clk_color, reset, locked, clk_in1)
/* synthesis syn_black_box black_box_pad_pin="clk_dot,clk_color,reset,locked,clk_in1" */;
  output clk_dot;
  output clk_color;
  input reset;
  output locked;
  input clk_in1;
endmodule
