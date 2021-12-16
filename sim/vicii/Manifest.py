action = "simulation"
sim_tool = "iverilog"
sim_top = "vicii_tb"

iverilog_opt= "-D XILINX_SIMULATOR"
#sim_post_cmd = "vsim -do ../vsim.do -i counter_tb"

modules = {
    "local" : [ "../../testbench/vicii" ],
}
