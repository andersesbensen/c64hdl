action = "simulation"
sim_tool = "iverilog"
sim_top = "c64_tb"

iverilog_opt= "-D XILINX_SIMULATOR"

modules = {
    "local" : [ "../../testbench/c64" ],
}
