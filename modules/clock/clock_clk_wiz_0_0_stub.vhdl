-- Copyright 1986-2021 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2021.1.1 (lin64) Build 3286242 Wed Jul 28 13:09:46 MDT 2021
-- Date        : Sun Nov 21 00:16:44 2021
-- Host        : aes-Lenovo-Legion-5-15ARH05H running 64-bit Ubuntu 20.04.3 LTS
-- Command     : write_vhdl -force -mode synth_stub
--               /home/aes/Kode/c64hdl/c64hdl.gen/sources_1/bd/clock/ip/clock_clk_wiz_0_0/clock_clk_wiz_0_0_stub.vhdl
-- Design      : clock_clk_wiz_0_0
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xc7a100tcsg324-1
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity clock_clk_wiz_0_0 is
  Port ( 
    clk_dot : out STD_LOGIC;
    clk_color : out STD_LOGIC;
    reset : in STD_LOGIC;
    locked : out STD_LOGIC;
    clk_in1 : in STD_LOGIC
  );

end clock_clk_wiz_0_0;

architecture stub of clock_clk_wiz_0_0 is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "clk_dot,clk_color,reset,locked,clk_in1";
begin
end;
