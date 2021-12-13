action = "simulation"
sim_tool = "iverilog"
sim_top = "sid_tb"

#sim_post_cmd = "vsim -do ../vsim.do -i counter_tb"

modules = {
    "local" : [ "../../testbench/sid" ],
}
