action = "simulation"
sim_tool = "iverilog"
sim_top = "c64_tb"

#sim_post_cmd = "vsim -do ../vsim.do -i counter_tb"

modules = {
    "local" : [ "../../testbench/c64" ],
}
