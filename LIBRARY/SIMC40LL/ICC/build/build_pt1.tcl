#=====================设置变量======================
set CURRENT_PATH     "OLD_CURRENT_PATH"
set top_name         "OLD_TOP_NAME"
set net_path         "$CURRENT_PATH/Layout/netlist"
set syn_net_path     "$CURRENT_PATH/Synthesis/DC/results"
set gds_path         "$CURRENT_PATH/Layout/gds"
set rpt_path         "$CURRENT_PATH/Layout/rpt"
set script_root_path "$CURRENT_PATH/Layout/build"
set lib_path         "/export/yfxie02/library/SMIC40LL/STDCELL/SCC40NLL_VHSC40_RVT_V0.1/SCC40NLL_VHSC40_RVT_V0p1/liberty/1.1v"
set mem_path         "/net/dellt630a/export/home/wangyu/Documents/Repo/SRAM_CIM_Digital/CFPMAC2C_Systolic_Controller/Synthesis/mem"
set io_path          "/export/yfxie02/library/SMIC40LL/IO/SP40NLLD2RNP_OV3_V1p1a/syn/2p5v"

set power_name       "OLD_VDD"
set ground_name      "OLD_VSS"
set MnTXT1            141
set MnTXT2            142
set MnTXT3            143
set MnTXT4            144
set MnTXT5            145
set MnTXT6            146

set search_path "$script_root_path \
                 $lib_path         \
                 $io_path          \
                "

#=====================设置工艺库======================

set lib_name       "scc40nll_vhsc40_rvt_tt_v1p1_25c_ccs"
set target_library "scc40nll_vhsc40_rvt_tt_v1p1_25c_ccs.db \
                    SP40NLLD2RNP_OV3_V1p1_tt_V1p10_25C.db \
                   "
set link_library   "scc40nll_vhsc40_rvt_tt_v1p1_25c_ccs.db \
                    SP40NLLD2RNP_OV3_V1p1_tt_V1p10_25C.db \
                   "

#====================Steps========================
# 1. init_design
# 2. place_opt
# 3. clock_opt_cts
# 4. clock_opt_psyn
# 5. clock_opt_route
# 6. route
# 7. route_opt
# 8. chip_finish
# 9. output


#====================1. init_design=====================

create_mw_lib -technology /export/yfxie02/library/SMIC40LL/STDCELL/SCC40NLL_VHSC40_RVT_V0.1/SCC40NLL_VHSC40_RVT_V0p1/astro/tf/scc40nll_vhs_7lm_1tm.tf -mw_reference_library { /export/yfxie02/library/SMIC40LL/STDCELL/SCC40NLL_VHSC40_RVT_V0.1/SCC40NLL_VHSC40_RVT_V0p1/astro/scc40nll_vhsc40_rvt /export/yfxie02/library/SMIC40LL/IO/SP40NLLD2RNP_OV3_V1p1a/apollo/SP40NLLD2RNP_OV3_V1p1_7MT_1TM } -bus_naming_style {[%d]} -open $CURRENT_PATH/Layout/$top_name
# import_designs -format ddc -top $top_name -cel $top_name { $syn_net_path/$top_name\.ddc }
read_verilog $syn_net_path/$top_name\.mapped\.v -dirty_netlist -top $top_name -cel $top_name
set_tlu_plus_files -max_tluplus /export/yfxie02/library/SMIC40LL/STDCELL/SCC40NLL_VHSC40_RVT_V0.1/SCC40NLL_VHSC40_RVT_V0p1/astro/tluplus/TD-LO40-XS-2002v1R_1PxM_1TM9k_ALPA14.5k/1P7M_1TM/StarRC_40LL_1P7M_1TM_RCMAX.tluplus -min_tluplus /export/yfxie02/library/SMIC40LL/STDCELL/SCC40NLL_VHSC40_RVT_V0.1/SCC40NLL_VHSC40_RVT_V0p1/astro/tluplus/TD-LO40-XS-2002v1R_1PxM_1TM9k_ALPA14.5k/1P7M_1TM/StarRC_40LL_1P7M_1TM_RCMIN.tluplus -tech2itf_map /export/yfxie02/library/SMIC40LL/STDCELL/SCC40NLL_VHSC40_RVT_V0.1/SCC40NLL_VHSC40_RVT_V0p1/astro/tluplus/TD-LO40-XS-2002v1R_1PxM_1TM9k_ALPA14.5k/1P7M_1TM/StarRC_40LL_1P7M_1TM_cell.map
read_sdc -version Latest $syn_net_path/$top_name\.mapped\.sdc

uniquify_fp_mw_cel
current_design 
link

if {[check_error -verbose] != 0} { exit 1 }
save_mw_cel -design $top_name -as "$top_name\_init_design"

gui_zoom -window [gui_get_current_window -types Layout -mru] -full
gui_execute_events


#忽略PAD设置

remove_ideal_network -all
remove_propagated_clock [all_clocks]

read_pin_pad_physical_constraints "$script_root_path/pin_pad.tcl"


derive_pg_connection -power_net "VDD" -power_pin $power_name -ground_net "VSS" -ground_pin $ground_name
# derive_pg_connection -verbose

create_floorplan \
    -control_type aspect_ratio \
    -left_io2core      4 \
    -bottom_io2core    4 \
    -right_io2core     4 \
    -top_io2core       4 \
    -core_aspect_ratio 1 \
    -core_utilization  OLD_CORE_UTILIZATION \
    -start_first_row

add_end_cap -respect_blockage -lib_cell "$lib_name/FDCAP4_12TR40"

if {[check_error -verbose] != 0} { exit 2 }
save_mw_cel -design $top_name -as "$top_name\_die_init"

gui_zoom -window [gui_get_current_window -types Layout -mru] -full
gui_execute_events

#====================optimization_settings============
set_delay_calculation_options -arnoldi_effort high
set_host_options -max_core 16
set_app_var timing_enable_multiple_clocks_per_reg false
set_fix_multiple_port_nets -all -buffer_constants
set_auto_disable_drc_nets -constant true ;# ! ICC_TIE_CELL_FLOW
# Optinal: add dont use cells

#====================placement_settings============
set MIN_ROUTING_LAYER "[get_layer_attribute -layer metal1 name]"
set MAX_ROUTING_LAYER "[get_layer_attribute -layer metal5 name]"
set_ignored_layers -max_routing_layer $MAX_ROUTING_LAYER
set_ignored_layers -min_routing_layer $MIN_ROUTING_LAYER

set_pnet_options -complete {M1 M2} -see_object {all_types}
report_pnet_options

set_fp_placement_strategy -sliver_size 10 -virtual_IPO on \
    -macros_on_edge on \
    -fix_macros all

set_app_var physopt_hard_keepout_distance 10
set placer_soft_keepout_channel_width 10

#====================cts_settings============

define_routing_rule iccrm_clock_double_spacing -default_reference_rule -multiplier_spacing 2 -multiplier_width 2
report_routing_rule iccrm_clock_double_spacing
set_clock_tree_options -routing_rule iccrm_clock_double_spacing -use_default_routing_for_sinks 1

#Optional: clock shielding NDR

set_clock_tree_options -layer_list "M3 M4" ;# typically route clocks on metal3 and above

#====================post_cts_settings============
set ICC_FIX_HOLD_PREFER_CELLS "$lib_name/DEL2V0_12TR40 $lib_name/DEL2V2_12TR40 $lib_name/DEL2V4_12TR40 $lib_name/DEL2V8_12TR40 $lib_name/DEL4V0_12TR40 $lib_name/DEL4V2_12TR40 $lib_name/DEL4V4_12TR40 $lib_name/DEL4V8_12TR40"
remove_attribute [get_lib_cells $ICC_FIX_HOLD_PREFER_CELLS] dont_touch
set_prefer -min [get_lib_cells $ICC_FIX_HOLD_PREFER_CELLS]
set_fix_hold_options -preferred_buffer

#====================route_si_settings============

set_si_options -delta_delay true \
    -route_xtalk_prevention true \
    -route_xtalk_prevention_threshold 0.25 \
    -analysis_effort medium

set_si_options -min_delta_delay true

set_route_opt_strategy -search_repair_loops 40
set_route_opt_strategy -eco_route_search_repair_loops 10

set_app_var routeopt_skip_report_qor true

set_route_zrt_detail_options -antenna true


#====================2. place_opt=====================

set_app_var compile_instance_name_prefix icc_place
check_mv_design -verbose

create_fp_placement -timing -no_hier
derive_pg_connection -power_net "VDD" -power_pin $power_name -ground_net "VSS" -ground_pin $ground_name
# derive_pg_connection -verbose

create_rectilinear_rings -nets { "VDD" "VSS" } -offset { 1 1 } -width { 0.7 0.7 } -space { 0.3 0.3 }

add_tap_cell_array -master_cell_name FILLTIE3_12TR40 -distance 20 -pattern normal -connect_power_name "VDD" -connect_ground_name "VSS"
derive_pg_connection -power_net "VDD" -power_pin $power_name -ground_net "VSS" -ground_pin $ground_name
# derive_pg_connection -verbose

set_preroute_drc_strategy -max_layer M4
preroute_instances
# preroute_standard_cells -fill_empty_rows -remove_floating_pieces -extend_for_multiple_connections -route_type {P/G Std. Cell Pin Conn}
preroute_standard_cells -fill_empty_rows

set_dont_touch_placement [all_macro_cells]

set r [place_opt -area_recovery -effort medium -congestion -power -continue_on_missing_scandef]
if { $r == 0 } {
    exit 3
}

connect_tie_cells -max_wirelength 200 -tie_high_lib_cell PULL1_12TR40 -tie_low_lib_cell PULL0_12TR40 -max_fanout 5 -obj_type cell_inst -objects [get_cells -hier *]

derive_pg_connection -power_net "VDD" -power_pin $power_name -ground_net "VSS" -ground_pin $ground_name
# derive_pg_connection -verbose

if {[check_error -verbose] != 0} { exit 3 }
save_mw_cel -design $top_name -as "$top_name\_place_opt"

gui_zoom -window [gui_get_current_window -types Layout -mru] -full
gui_execute_events

#====================3. clock_opt_cts=====================

set_app_var cts_instance_name_prefix CTS
check_mv_design -verbose

clock_opt -only_cts -no_clock_route -continue_on_missing_scandef -update_clock_latency

derive_pg_connection -power_net "VDD" -power_pin $power_name -ground_net "VSS" -ground_pin $ground_name
# derive_pg_connection -verbose

remove_ideal_network [all_fanout -flat -clock_tree]
set_fix_hold [all_clocks]

if {[check_error -verbose] != 0} { exit 4 }
save_mw_cel -design $top_name -as "$top_name\_clock_opt_cts"

gui_zoom -window [gui_get_current_window -types Layout -mru] -full
gui_execute_events

#====================4. clock_opt_psyn=====================

set_app_var compile_instance_name_prefix icc_clock

clock_opt -no_clock_route -only_psyn -area_recovery -congestion -continue_on_missing_scandef 

route_zrt_group -all_clock_nets -reuse_existing_global_route true -stop_after_global_route true

# Antenna prevention
set ICC_PORT_PROTECTION_DIODE "$lib_name/F_DIODE2_12TR40 $lib_name/F_DIODE4_12TR40 $lib_name/F_DIODE8_12TR40"
remove_attribute $ICC_PORT_PROTECTION_DIODE dont_use
set ports [get_ports * -filter "direction==in"]
# insert_port_protection_diodes -prefix port_protection_diode -diode_cell [get_lib_cells $ICC_PORT_PROTECTION_DIODE] -port $ports -ignore_dont_touch
legalize_placement

derive_pg_connection -power_net "VDD" -power_pin $power_name -ground_net "VSS" -ground_pin $ground_name
# derive_pg_connection -verbose

if {[check_error -verbose] != 0} { exit 5 }
save_mw_cel -design $top_name -as "$top_name\_clock_opt_psyn"

gui_zoom -window [gui_get_current_window -types Layout -mru] -full
gui_execute_events

#====================5. clock_opt_route=====================

source -echo /export/yfxie02/library/SMIC40LL/STDCELL/SCC40NLL_VHSC40_RVT_V0.1/SCC40NLL_VHSC40_RVT_V0p1/astro/clf/antenna_7lm_1tm.tcl

set_si_options -delta_delay false -min_delta_delay false -route_xtalk_prevention false

route_zrt_group -all_clock_nets -reuse_existing_global_route true
optimize_clock_tree -routed_clock_stage detail 

derive_pg_connection -power_net "VDD" -power_pin $power_name -ground_net "VSS" -ground_pin $ground_name
# derive_pg_connection -verbose

if {[check_error -verbose] != 0} { exit 6 }
save_mw_cel -design $top_name -as "$top_name\_clock_opt_route"

gui_zoom -window [gui_get_current_window -types Layout -mru] -full
gui_execute_events

#====================6. route=====================

set_si_options -delta_delay true \
    -route_xtalk_prevention true \
    -route_xtalk_prevention_threshold 0.25 \
    -analysis_effort medium

set_si_options -min_delta_delay true

## pre route_opt checks
set num_ideal [sizeof_collection [all_ideal_nets]]
if {$num_ideal >= 1} {echo "RM-Error: $num_ideal Nets are ideal prior to route_opt. Please investigate it."}

set_route_zrt_common_options -post_detail_route_redundant_via_insertion medium
set_route_zrt_detail_options -optimize_wire_via_effort_level high

report_preferred_routing_direction

route_opt -initial_route_only
if {[check_error -verbose] != 0} { exit 7 }

update_clock_latency
derive_pg_connection -power_net "VDD" -power_pin $power_name -ground_net "VSS" -ground_pin $ground_name
# derive_pg_connection -verbose

save_mw_cel -design $top_name -as "$top_name\_route"

gui_zoom -window [gui_get_current_window -types Layout -mru] -full
gui_execute_events

#====================7. route_opt=====================

set_app_var compile_instance_name_prefix icc_route_opt
update_timing

set_app_var routeopt_allow_min_buffer_with_size_only true

route_opt -skip_initial_route -effort medium -xtalk_reduction
route_opt -incremental 
route_opt -incremental -size_only

derive_pg_connection -power_net "VDD" -power_pin $power_name -ground_net "VSS" -ground_pin $ground_name
# derive_pg_connection -verbose

if {[check_error -verbose] != 0} { exit 8 }
save_mw_cel -design $top_name -as "$top_name\_route_opt"

gui_zoom -window [gui_get_current_window -types Layout -mru] -full
gui_execute_events

#====================7. chip_finish=====================
set_route_zrt_detail_options -eco_route_use_soft_spacing_for_timing_optimization false

spread_zrt_wires -timing_preserve_hold_slack_threshold 0 -timing_preserve_setup_slack_threshold 0.1
widen_zrt_wires -timing_preserve_hold_slack_threshold 0 -timing_preserve_setup_slack_threshold 0.1

set_route_zrt_detail_options -antenna true -diode_libcell_names "F_DIODE2_12TR40 F_DIODE4_12TR40 F_DIODE8_12TR40" -insert_diodes_during_routing true
route_zrt_detail -incremental true

insert_stdcell_filler -cell_without_metal "F_FILL128_12TR40 F_FILL64_12TR40 F_FILL32_12TR40 F_FILL16_12TR40 F_FILL8_12TR40 F_FILL4_12TR40 F_FILL2_12TR40 F_FILL1_12TR40"

derive_pg_connection -power_net "VDD" -power_pin $power_name -ground_net "VSS" -ground_pin $ground_name
# derive_pg_connection -verbose

#final route clean-up

set_route_zrt_global_options -timing_driven false -crosstalk_driven false
set_route_zrt_track_options -timing_driven false -crosstalk_driven false
set_route_zrt_detail_options -timing_driven false

route_zrt_eco

if {[check_error -verbose] != 0} { exit 9 }
save_mw_cel -design $top_name -as "$top_name\_chip_finish"

gui_zoom -window [gui_get_current_window -types Layout -mru] -full
gui_execute_events

#====================GDS标签=====================
############VDD PORT############ 
create_port $power_name
connect_net VDD $power_name
create_port $ground_name
connect_net VSS $ground_name

create_text -origin {1.65 1.65} -layer 141 VDD
create_text -origin {2.65 2.65} -layer 141 VSS

#set routing_direction [report_preferred_routing_direction]
