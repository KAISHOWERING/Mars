set sdc_version 2.1

set_units -time ns -resistance kOhm -capacitance pF -voltage V -current mA
#set_max_area 100000
set_max_transition 5 [current_design]
set_max_fanout 1000 [current_design]
create_clock -name OLD_CLK_NAME -period OLD_PERIOD -waveform { 0 OLD_HALF_PERIOD } [ get_ports clk ] 
set_input_delay 0 -clock [get_clocks clk] [all_inputs]
set_output_delay 0 -clock [get_clocks clk] [all_outputs]
# set_fix_hold [get_clocks vclk]