#-------------------------------------------------------------------------
# Do not edit this file! It is auto-generated from create_dcp_from_cl.tcl.
#-------------------------------------------------------------------------

# Group A Clocks
create_clock -period 8  -name clk_main_a0 -waveform {0.000 4}  [get_ports clk_main_a0]
create_clock -period 16 -name clk_extra_a1 -waveform {0.000 8} [get_ports clk_extra_a1]
create_clock -period 5.333 -name clk_extra_a2 -waveform {0.000 2.667} [get_ports clk_extra_a2]
create_clock -period 4 -name clk_extra_a3 -waveform {0.000 2} [get_ports clk_extra_a3]

# Group B Clocks
create_clock -period 4 -name clk_extra_b0 -waveform {0.000 2} [get_ports clk_extra_b0]
create_clock -period 8 -name clk_extra_b1 -waveform {0.000 4} [get_ports clk_extra_b1]

# Group C Clocks
create_clock -period 3.333 -name clk_extra_c0 -waveform {0.000 1.667} [get_ports clk_extra_c0]
create_clock -period 2.5 -name clk_extra_c1 -waveform {0.000 1.25} [get_ports clk_extra_c1]
