#=====================设置变量======================
set CURRENT_PATH     "OLD_CURRENT_PATH"
set top_name         "OLD_TOP_NAME"
set net_path         "$CURRENT_PATH/Layout/netlist"
set syn_net_path     "/net/dellt630a/export/home/wangyu/Documents/Repo/SRAM_CIM_Digital/CFPMAC2C_Systolic_Controller/Synthesis/netlist"
set gds_path         "$CURRENT_PATH/gds"
set rpt_path         "$CURRENT_PATH/rpt"
set script_root_path "$CURRENT_PATH/build"
set lib_path         "/export/yfxie02/library/SMIC40LL/STDCELL/SCC40NLL_VHSC40_RVT_V0.1/SCC40NLL_VHSC40_RVT_V0p1/liberty/1.1v"
set mem_path         "/net/dellt630a/export/home/wangyu/Documents/Repo/SRAM_CIM_Digital/CFPMAC2C_Systolic_Controller/Synthesis/mem"
set io_path          "/export/yfxie02/library/SMIC40LL/IO/SP40NLLD2RNP_OV3_V1p1a/syn/2p5v"

set power_name       "OLD_VDD"
set ground_name      "OLD_VSS"
set MnTXT1            141
set MnTXT2            142
set MnTXT3            143
set MnTXT4            144

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

create_mw_lib -technology /export/yfxie02/library/SMIC40LL/STDCELL/SCC40NLL_VHSC40_RVT_V0.1/SCC40NLL_VHSC40_RVT_V0p1/astro/tf/scc40nll_vhs_7lm_1tm.tf -mw_reference_library { /export/yfxie02/library/SMIC40LL/STDCELL/SCC40NLL_VHSC40_RVT_V0.1/SCC40NLL_VHSC40_RVT_V0p1/astro/scc40nll_vhsc40_rvt /export/yfxie02/library/SMIC40LL/IO/SP40NLLD2RNP_OV3_V1p1a/apollo/SP40NLLD2RNP_OV3_V1p1_7MT_1TM } -bus_naming_style {[%d]} -open $top_name
# import_designs -format ddc -top $top_name -cel $top_name { $syn_net_path/$top_name\.ddc }
read_verilog $syn_net_path/$top_name\.v -dirty_netlist -top $top_name -cel $top_name
set_tlu_plus_files -max_tluplus /export/yfxie02/library/SMIC40LL/STDCELL/SCC40NLL_VHSC40_RVT_V0.1/SCC40NLL_VHSC40_RVT_V0p1/astro/tluplus/TD-LO40-XS-2002v1R_1PxM_1TM9k_ALPA14.5k/1P7M_1TM/StarRC_40LL_1P7M_1TM_RCMAX.tluplus -min_tluplus /export/yfxie02/library/SMIC40LL/STDCELL/SCC40NLL_VHSC40_RVT_V0.1/SCC40NLL_VHSC40_RVT_V0p1/astro/tluplus/TD-LO40-XS-2002v1R_1PxM_1TM9k_ALPA14.5k/1P7M_1TM/StarRC_40LL_1P7M_1TM_RCMIN.tluplus -tech2itf_map /export/yfxie02/library/SMIC40LL/STDCELL/SCC40NLL_VHSC40_RVT_V0.1/SCC40NLL_VHSC40_RVT_V0p1/astro/tluplus/TD-LO40-XS-2002v1R_1PxM_1TM9k_ALPA14.5k/1P7M_1TM/StarRC_40LL_1P7M_1TM_cell.map
read_sdc -version Latest $syn_net_path/$top_name\.sdc

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
set MIN_ROUTING_LAYER "[get_layer_attribute -layer metal2 name]"
set MAX_ROUTING_LAYER "[get_layer_attribute -layer metal4 name]"
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

#set routing_direction [report_preferred_routing_direction]

set temp_ports [get_ports I_L_DATA[0]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_L_DATA[1]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_L_DATA[2]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_L_DATA[3]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_L_DATA[4]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_L_DATA[5]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_L_DATA[6]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_L_DATA[7]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_L_DATA[8]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_L_DATA[9]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_L_DATA[10]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_L_DATA[11]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_L_DATA[12]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_L_DATA[13]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_L_DATA[14]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_L_DATA[15]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_L_DATA[16]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_L_DATA[17]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_L_DATA[18]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_L_DATA[19]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_L_DATA[20]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_L_DATA[21]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_L_DATA[22]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_L_DATA[23]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_L_DATA[24]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_L_DATA[25]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_L_DATA[26]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_L_DATA[27]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_L_DATA[28]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_L_DATA[29]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_L_DATA[30]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_L_DATA[31]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_L_DATA[32]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_L_DATA[33]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_L_DATA[34]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_L_DATA[35]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_L_DATA[36]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_L_DATA[37]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_L_DATA[38]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_L_DATA[39]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_L_DATA[40]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_L_DATA[41]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_L_DATA[42]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_L_DATA[43]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_L_DATA[44]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_L_DATA[45]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_L_DATA[46]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_L_DATA[47]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_L_DATA[48]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_L_DATA[49]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_L_DATA[50]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_L_DATA[51]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_L_DATA[52]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_L_DATA[53]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_L_DATA[54]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_L_DATA[55]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_L_DATA[56]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_L_DATA[57]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_L_DATA[58]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_L_DATA[59]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_L_DATA[60]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_L_DATA[61]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_L_DATA[62]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_L_DATA[63]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_L_DATA[64]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_L_DATA[65]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_L_DATA[66]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_L_DATA[67]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_L_DATA[68]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_L_DATA[69]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_L_DATA[70]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_L_DATA[71]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_L_DATA[72]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_L_DATA[73]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_L_DATA[74]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_L_DATA[75]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_L_DATA[76]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_L_DATA[77]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_L_DATA[78]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_L_DATA[79]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_LEFT_ROW_BASE_ADDR[0]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_LEFT_ROW_BASE_ADDR[1]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_LEFT_ROW_BASE_ADDR[2]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_LEFT_ROW_BASE_ADDR[3]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_LEFT_ROW_BASE_ADDR[4]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_LEFT_ROW_BASE_ADDR[5]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_LEFT_COL_BASE_ADDR]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_LEFT_FP_INT_MODE]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_LEFT_CIM_MEM_MODE]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_LEFT_MODE[0]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_LEFT_MODE[1]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_LEFT_MODE[2]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_LEFT_POLAR[0]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_LEFT_POLAR[1]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_LEFT_POLAR[2]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_LEFT_DATA[0]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_LEFT_DATA[1]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_LEFT_DATA[2]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_LEFT_DATA[3]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_LEFT_DATA[4]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_LEFT_DATA[5]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_LEFT_DATA[6]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_LEFT_DATA[7]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_LEFT_DATA[8]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_LEFT_DATA[9]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_LEFT_DATA[10]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_LEFT_DATA[11]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_LEFT_DATA[12]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_LEFT_DATA[13]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_LEFT_DATA[14]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_LEFT_DATA[15]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_LEFT_DATA[16]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_LEFT_DATA[17]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_LEFT_DATA[18]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_LEFT_DATA[19]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_LEFT_DATA[20]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_LEFT_DATA[21]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_LEFT_DATA[22]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_LEFT_DATA[23]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_LEFT_DATA[24]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_LEFT_DATA[25]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_LEFT_DATA[26]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_LEFT_DATA[27]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_LEFT_DATA[28]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_LEFT_DATA[29]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_LEFT_DATA[30]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_LEFT_DATA[31]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_LEFT_WRITE_DATA[0]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_LEFT_WRITE_DATA[1]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_LEFT_WRITE_DATA[2]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_LEFT_WRITE_DATA[3]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_LEFT_WRITE_DATA[4]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_LEFT_WRITE_DATA[5]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_LEFT_WRITE_DATA[6]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_LEFT_WRITE_DATA[7]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_LEFT_WRITE_DATA[8]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_LEFT_WRITE_DATA[9]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_LEFT_WRITE_DATA[10]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_LEFT_WRITE_DATA[11]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_LEFT_WRITE_DATA[12]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_LEFT_WRITE_DATA[13]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_LEFT_WRITE_DATA[14]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_LEFT_WRITE_DATA[15]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_LEFT_WRITE_DATA[16]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_LEFT_WRITE_DATA[17]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_LEFT_WRITE_DATA[18]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_LEFT_WRITE_DATA[19]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_LEFT_WRITE_DATA[20]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_LEFT_WRITE_DATA[21]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_LEFT_WRITE_DATA[22]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_LEFT_WRITE_DATA[23]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_LEFT_WRITE_DATA[24]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_LEFT_WRITE_DATA[25]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_LEFT_WRITE_DATA[26]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_LEFT_WRITE_DATA[27]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_LEFT_WRITE_DATA[28]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_LEFT_WRITE_DATA[29]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_LEFT_WRITE_DATA[30]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_LEFT_WRITE_DATA[31]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_LEFT_COMPUTE_RESULT[0]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_LEFT_COMPUTE_RESULT[1]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_LEFT_COMPUTE_RESULT[2]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_LEFT_COMPUTE_RESULT[3]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_LEFT_COMPUTE_RESULT[4]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_LEFT_COMPUTE_RESULT[5]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_LEFT_COMPUTE_RESULT[6]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_LEFT_COMPUTE_RESULT[7]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_LEFT_COMPUTE_RESULT[8]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_LEFT_COMPUTE_RESULT[9]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_LEFT_COMPUTE_RESULT[10]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_LEFT_COMPUTE_RESULT[11]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_LEFT_COMPUTE_RESULT[12]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_LEFT_COMPUTE_RESULT[13]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_LEFT_COMPUTE_RESULT[14]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_LEFT_COMPUTE_RESULT[15]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_LEFT_COMPUTE_RESULT[16]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_LEFT_COMPUTE_RESULT[17]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_LEFT_COMPUTE_RESULT[18]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_LEFT_COMPUTE_RESULT[19]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_LEFT_COMPUTE_RESULT[20]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_LEFT_COMPUTE_RESULT[21]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_LEFT_COMPUTE_RESULT[22]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_LEFT_COMPUTE_RESULT[23]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_LEFT_COMPUTE_RESULT[24]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_LEFT_COMPUTE_RESULT[25]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_LEFT_COMPUTE_RESULT[26]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_LEFT_COMPUTE_RESULT[27]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_LEFT_COMPUTE_RESULT[28]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_LEFT_COMPUTE_RESULT[29]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_LEFT_COMPUTE_RESULT[30]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_LEFT_COMPUTE_RESULT[31]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_LEFT_COMPUTE_RESULT[32]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_LEFT_READ_DATA[0]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_LEFT_READ_DATA[1]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_LEFT_READ_DATA[2]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_LEFT_READ_DATA[3]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_LEFT_READ_DATA[4]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_LEFT_READ_DATA[5]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_LEFT_READ_DATA[6]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_LEFT_READ_DATA[7]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_LEFT_READ_DATA[8]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_LEFT_READ_DATA[9]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_LEFT_READ_DATA[10]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_LEFT_READ_DATA[11]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_LEFT_READ_DATA[12]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_LEFT_READ_DATA[13]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_LEFT_READ_DATA[14]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_LEFT_READ_DATA[15]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_LEFT_READ_DATA[16]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_LEFT_READ_DATA[17]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_LEFT_READ_DATA[18]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_LEFT_READ_DATA[19]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_LEFT_READ_DATA[20]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_LEFT_READ_DATA[21]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_LEFT_READ_DATA[22]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_LEFT_READ_DATA[23]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_LEFT_READ_DATA[24]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_LEFT_READ_DATA[25]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_LEFT_READ_DATA[26]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_LEFT_READ_DATA[27]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_LEFT_READ_DATA[28]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_LEFT_READ_DATA[29]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_LEFT_READ_DATA[30]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_LEFT_READ_DATA[31]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_LEFT_COMPUTE_EN]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_LEFT_COMPUTE_DONE]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_LEFT_WRITE_EN]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_LEFT_WRITE_DONE]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_LEFT_READ_EN]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_LEFT_READ_DONE]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_CLK]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_RST_N]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_SYSTOLIC_EN]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_U_DATA[0]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_U_DATA[1]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_U_DATA[2]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_U_DATA[3]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_U_DATA[4]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_U_DATA[5]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_U_DATA[6]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_U_DATA[7]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_U_DATA[8]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_U_DATA[9]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_U_DATA[10]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_U_DATA[11]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_U_DATA[12]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_U_DATA[13]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_U_DATA[14]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_U_DATA[15]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_U_DATA[16]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_U_DATA[17]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_U_DATA[18]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_U_DATA[19]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_U_DATA[20]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_U_DATA[21]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_U_DATA[22]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_U_DATA[23]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_U_DATA[24]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_U_DATA[25]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_U_DATA[26]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_U_DATA[27]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_U_DATA[28]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_U_DATA[29]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_U_DATA[30]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_U_DATA[31]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_U_DATA[32]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_U_DATA[33]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_U_DATA[34]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_U_DATA[35]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_U_DATA[36]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_U_DATA[37]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_U_DATA[38]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_U_DATA[39]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_U_DATA[40]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_U_DATA[41]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_U_DATA[42]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_U_DATA[43]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_U_DATA[44]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_U_DATA[45]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_U_DATA[46]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_U_DATA[47]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_U_DATA[48]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_U_DATA[49]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_U_DATA[50]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_U_DATA[51]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_U_DATA[52]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_U_DATA[53]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_U_DATA[54]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_U_DATA[55]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_U_DATA[56]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_U_DATA[57]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_U_DATA[58]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_U_DATA[59]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_U_DATA[60]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_U_DATA[61]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_U_DATA[62]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_U_DATA[63]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_U_DATA[64]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_U_DATA[65]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_U_DATA[66]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_U_DATA[67]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_U_DATA[68]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_U_DATA[69]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_U_DATA[70]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_U_DATA[71]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_U_DATA[72]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_U_DATA[73]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_U_DATA[74]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_U_DATA[75]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_U_DATA[76]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_U_DATA[77]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_U_DATA[78]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_U_DATA[79]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_ADDR[0]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_ADDR[1]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_ADDR[2]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_ADDR[3]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_ADDR[4]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_ADDR[5]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports CFPMAC2_ADDR[0]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports CFPMAC2_ADDR[1]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports CFPMAC2_ADDR[2]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports CFPMAC2_ADDR[3]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports CFPMAC2_ADDR[4]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports CFPMAC2_ADDR[5]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_DATA_CFG[0]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_DATA_CFG[1]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_EN]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_RD_EN]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_WR_DONE]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RD_DONE]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_R_DATA[0]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_R_DATA[1]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_R_DATA[2]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_R_DATA[3]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_R_DATA[4]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_R_DATA[5]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_R_DATA[6]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_R_DATA[7]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_R_DATA[8]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_R_DATA[9]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_R_DATA[10]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_R_DATA[11]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_R_DATA[12]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_R_DATA[13]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_R_DATA[14]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_R_DATA[15]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_R_DATA[16]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_R_DATA[17]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_R_DATA[18]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_R_DATA[19]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_R_DATA[20]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_R_DATA[21]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_R_DATA[22]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_R_DATA[23]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_R_DATA[24]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_R_DATA[25]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_R_DATA[26]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_R_DATA[27]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_R_DATA[28]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_R_DATA[29]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_R_DATA[30]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_R_DATA[31]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_R_DATA[32]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_R_DATA[33]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_R_DATA[34]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_R_DATA[35]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_R_DATA[36]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_R_DATA[37]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_R_DATA[38]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_R_DATA[39]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_R_DATA[40]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_R_DATA[41]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_R_DATA[42]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_R_DATA[43]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_R_DATA[44]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_R_DATA[45]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_R_DATA[46]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_R_DATA[47]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_R_DATA[48]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_R_DATA[49]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_R_DATA[50]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_R_DATA[51]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_R_DATA[52]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_R_DATA[53]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_R_DATA[54]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_R_DATA[55]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_R_DATA[56]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_R_DATA[57]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_R_DATA[58]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_R_DATA[59]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_R_DATA[60]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_R_DATA[61]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_R_DATA[62]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_R_DATA[63]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_R_DATA[64]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_R_DATA[65]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_R_DATA[66]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_R_DATA[67]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_R_DATA[68]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_R_DATA[69]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_R_DATA[70]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_R_DATA[71]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_R_DATA[72]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_R_DATA[73]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_R_DATA[74]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_R_DATA[75]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_R_DATA[76]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_R_DATA[77]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_R_DATA[78]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_R_DATA[79]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RIGHT_ROW_BASE_ADDR[0]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RIGHT_ROW_BASE_ADDR[1]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RIGHT_ROW_BASE_ADDR[2]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RIGHT_ROW_BASE_ADDR[3]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RIGHT_ROW_BASE_ADDR[4]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RIGHT_ROW_BASE_ADDR[5]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RIGHT_COL_BASE_ADDR]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RIGHT_FP_INT_MODE]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RIGHT_CIM_MEM_MODE]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RIGHT_MODE[0]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RIGHT_MODE[1]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RIGHT_MODE[2]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RIGHT_POLAR[0]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RIGHT_POLAR[1]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RIGHT_POLAR[2]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RIGHT_DATA[0]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RIGHT_DATA[1]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RIGHT_DATA[2]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RIGHT_DATA[3]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RIGHT_DATA[4]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RIGHT_DATA[5]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RIGHT_DATA[6]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RIGHT_DATA[7]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RIGHT_DATA[8]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RIGHT_DATA[9]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RIGHT_DATA[10]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RIGHT_DATA[11]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RIGHT_DATA[12]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RIGHT_DATA[13]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RIGHT_DATA[14]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RIGHT_DATA[15]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RIGHT_DATA[16]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RIGHT_DATA[17]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RIGHT_DATA[18]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RIGHT_DATA[19]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RIGHT_DATA[20]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RIGHT_DATA[21]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RIGHT_DATA[22]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RIGHT_DATA[23]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RIGHT_DATA[24]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RIGHT_DATA[25]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RIGHT_DATA[26]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RIGHT_DATA[27]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RIGHT_DATA[28]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RIGHT_DATA[29]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RIGHT_DATA[30]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RIGHT_DATA[31]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RIGHT_WRITE_DATA[0]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RIGHT_WRITE_DATA[1]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RIGHT_WRITE_DATA[2]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RIGHT_WRITE_DATA[3]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RIGHT_WRITE_DATA[4]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RIGHT_WRITE_DATA[5]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RIGHT_WRITE_DATA[6]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RIGHT_WRITE_DATA[7]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RIGHT_WRITE_DATA[8]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RIGHT_WRITE_DATA[9]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RIGHT_WRITE_DATA[10]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RIGHT_WRITE_DATA[11]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RIGHT_WRITE_DATA[12]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RIGHT_WRITE_DATA[13]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RIGHT_WRITE_DATA[14]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RIGHT_WRITE_DATA[15]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RIGHT_WRITE_DATA[16]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RIGHT_WRITE_DATA[17]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RIGHT_WRITE_DATA[18]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RIGHT_WRITE_DATA[19]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RIGHT_WRITE_DATA[20]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RIGHT_WRITE_DATA[21]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RIGHT_WRITE_DATA[22]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RIGHT_WRITE_DATA[23]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RIGHT_WRITE_DATA[24]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RIGHT_WRITE_DATA[25]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RIGHT_WRITE_DATA[26]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RIGHT_WRITE_DATA[27]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RIGHT_WRITE_DATA[28]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RIGHT_WRITE_DATA[29]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RIGHT_WRITE_DATA[30]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RIGHT_WRITE_DATA[31]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_RIGHT_COMPUTE_RESULT[0]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_RIGHT_COMPUTE_RESULT[1]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_RIGHT_COMPUTE_RESULT[2]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_RIGHT_COMPUTE_RESULT[3]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_RIGHT_COMPUTE_RESULT[4]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_RIGHT_COMPUTE_RESULT[5]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_RIGHT_COMPUTE_RESULT[6]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_RIGHT_COMPUTE_RESULT[7]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_RIGHT_COMPUTE_RESULT[8]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_RIGHT_COMPUTE_RESULT[9]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_RIGHT_COMPUTE_RESULT[10]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_RIGHT_COMPUTE_RESULT[11]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_RIGHT_COMPUTE_RESULT[12]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_RIGHT_COMPUTE_RESULT[13]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_RIGHT_COMPUTE_RESULT[14]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_RIGHT_COMPUTE_RESULT[15]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_RIGHT_COMPUTE_RESULT[16]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_RIGHT_COMPUTE_RESULT[17]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_RIGHT_COMPUTE_RESULT[18]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_RIGHT_COMPUTE_RESULT[19]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_RIGHT_COMPUTE_RESULT[20]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_RIGHT_COMPUTE_RESULT[21]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_RIGHT_COMPUTE_RESULT[22]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_RIGHT_COMPUTE_RESULT[23]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_RIGHT_COMPUTE_RESULT[24]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_RIGHT_COMPUTE_RESULT[25]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_RIGHT_COMPUTE_RESULT[26]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_RIGHT_COMPUTE_RESULT[27]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_RIGHT_COMPUTE_RESULT[28]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_RIGHT_COMPUTE_RESULT[29]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_RIGHT_COMPUTE_RESULT[30]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_RIGHT_COMPUTE_RESULT[31]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_RIGHT_COMPUTE_RESULT[32]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_RIGHT_READ_DATA[0]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_RIGHT_READ_DATA[1]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_RIGHT_READ_DATA[2]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_RIGHT_READ_DATA[3]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_RIGHT_READ_DATA[4]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_RIGHT_READ_DATA[5]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_RIGHT_READ_DATA[6]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_RIGHT_READ_DATA[7]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_RIGHT_READ_DATA[8]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_RIGHT_READ_DATA[9]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_RIGHT_READ_DATA[10]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_RIGHT_READ_DATA[11]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_RIGHT_READ_DATA[12]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_RIGHT_READ_DATA[13]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_RIGHT_READ_DATA[14]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_RIGHT_READ_DATA[15]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_RIGHT_READ_DATA[16]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_RIGHT_READ_DATA[17]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_RIGHT_READ_DATA[18]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_RIGHT_READ_DATA[19]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_RIGHT_READ_DATA[20]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_RIGHT_READ_DATA[21]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_RIGHT_READ_DATA[22]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_RIGHT_READ_DATA[23]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_RIGHT_READ_DATA[24]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_RIGHT_READ_DATA[25]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_RIGHT_READ_DATA[26]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_RIGHT_READ_DATA[27]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_RIGHT_READ_DATA[28]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_RIGHT_READ_DATA[29]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_RIGHT_READ_DATA[30]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_RIGHT_READ_DATA[31]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RIGHT_COMPUTE_EN]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_RIGHT_COMPUTE_DONE]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RIGHT_WRITE_EN]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_RIGHT_WRITE_DONE]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RIGHT_READ_EN]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_RIGHT_READ_DONE]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT4 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_B_DATA[0]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_B_DATA[1]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_B_DATA[2]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_B_DATA[3]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_B_DATA[4]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_B_DATA[5]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_B_DATA[6]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_B_DATA[7]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_B_DATA[8]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_B_DATA[9]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_B_DATA[10]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_B_DATA[11]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_B_DATA[12]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_B_DATA[13]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_B_DATA[14]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_B_DATA[15]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_B_DATA[16]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_B_DATA[17]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_B_DATA[18]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_B_DATA[19]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_B_DATA[20]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_B_DATA[21]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_B_DATA[22]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_B_DATA[23]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_B_DATA[24]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_B_DATA[25]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_B_DATA[26]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_B_DATA[27]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_B_DATA[28]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_B_DATA[29]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_B_DATA[30]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_B_DATA[31]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_B_DATA[32]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_B_DATA[33]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_B_DATA[34]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_B_DATA[35]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_B_DATA[36]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_B_DATA[37]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_B_DATA[38]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_B_DATA[39]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_B_DATA[40]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_B_DATA[41]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_B_DATA[42]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_B_DATA[43]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_B_DATA[44]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_B_DATA[45]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_B_DATA[46]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_B_DATA[47]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_B_DATA[48]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_B_DATA[49]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_B_DATA[50]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_B_DATA[51]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_B_DATA[52]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_B_DATA[53]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_B_DATA[54]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_B_DATA[55]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_B_DATA[56]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_B_DATA[57]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_B_DATA[58]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_B_DATA[59]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_B_DATA[60]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_B_DATA[61]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_B_DATA[62]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_B_DATA[63]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_B_DATA[64]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_B_DATA[65]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_B_DATA[66]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_B_DATA[67]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_B_DATA[68]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_B_DATA[69]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_B_DATA[70]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_B_DATA[71]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_B_DATA[72]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_B_DATA[73]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_B_DATA[74]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_B_DATA[75]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_B_DATA[76]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_B_DATA[77]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_B_DATA[78]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_B_DATA[79]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[0]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[1]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[2]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[3]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[4]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[5]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[6]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[7]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[8]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[9]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[10]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[11]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[12]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[13]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[14]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[15]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[16]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[17]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[18]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[19]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[20]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[21]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[22]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[23]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[24]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[25]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[26]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[27]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[28]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[29]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[30]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[31]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[32]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[33]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[34]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[35]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[36]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[37]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[38]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[39]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[40]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[41]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[42]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[43]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[44]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[45]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[46]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[47]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[48]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[49]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[50]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[51]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[52]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[53]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[54]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[55]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[56]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[57]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[58]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[59]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[60]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[61]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[62]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[63]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[64]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[65]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[66]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[67]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[68]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[69]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[70]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[71]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[72]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[73]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[74]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[75]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[76]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[77]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[78]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[79]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[80]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[81]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[82]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[83]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[84]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[85]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[86]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[87]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[88]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[89]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[90]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[91]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[92]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[93]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[94]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[95]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[96]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[97]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[98]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[99]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[100]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports I_WR_DATA[101]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RD_DATA[0]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RD_DATA[1]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RD_DATA[2]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RD_DATA[3]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RD_DATA[4]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RD_DATA[5]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RD_DATA[6]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RD_DATA[7]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RD_DATA[8]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RD_DATA[9]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RD_DATA[10]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RD_DATA[11]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RD_DATA[12]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RD_DATA[13]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RD_DATA[14]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RD_DATA[15]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RD_DATA[16]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RD_DATA[17]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RD_DATA[18]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RD_DATA[19]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RD_DATA[20]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RD_DATA[21]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RD_DATA[22]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RD_DATA[23]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RD_DATA[24]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RD_DATA[25]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RD_DATA[26]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RD_DATA[27]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RD_DATA[28]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RD_DATA[29]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RD_DATA[30]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RD_DATA[31]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RD_DATA[32]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RD_DATA[33]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RD_DATA[34]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RD_DATA[35]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RD_DATA[36]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RD_DATA[37]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RD_DATA[38]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RD_DATA[39]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RD_DATA[40]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RD_DATA[41]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RD_DATA[42]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RD_DATA[43]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RD_DATA[44]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RD_DATA[45]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RD_DATA[46]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RD_DATA[47]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RD_DATA[48]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RD_DATA[49]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RD_DATA[50]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RD_DATA[51]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RD_DATA[52]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RD_DATA[53]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RD_DATA[54]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RD_DATA[55]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RD_DATA[56]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RD_DATA[57]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RD_DATA[58]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RD_DATA[59]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RD_DATA[60]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RD_DATA[61]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RD_DATA[62]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RD_DATA[63]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RD_DATA[64]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RD_DATA[65]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RD_DATA[66]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RD_DATA[67]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RD_DATA[68]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RD_DATA[69]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RD_DATA[70]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RD_DATA[71]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RD_DATA[72]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RD_DATA[73]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RD_DATA[74]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RD_DATA[75]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RD_DATA[76]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RD_DATA[77]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RD_DATA[78]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}
set temp_ports [get_ports O_RD_DATA[79]]
foreach_in_collection p $temp_ports {
    set xy_location [get_location $p]
    set x_location  [lindex $xy_location 0]
    set y_location  [lindex $xy_location 1]
    set name [collection_to_list $p]
    set name_1 [string range $name 7 end-2]

    create_text -height 0.05 -layer $MnTXT3 -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1
}

save_mw_cel -design $top_name -as "$top_name\_gds_label"

#====================输出=====================

verify_pg_nets
verify_lvs

report_placement_utilization

define_name_rules "IS_rule" -max_length "255" -allowed "A-Z0-9_$"  -replacement_char "_" -type cell
define_name_rules "IS_rule" -max_length "255" -allowed "A-Z0-9_$"  -replacement_char "_" -type net
define_name_rules "IS_rule" -max_length "255" -allowed "A-Z0-9_$[]"  -replacement_char "_" -type port
change_names -rules "IS_rule" -hierarchy

save_mw_cel -as $top_name

report_timing -delay_type max -max_path 20 > $rpt_path/dfm_max.rpt
report_timing -delay_type min -max_path 20 > $rpt_path/dfm_min.rpt

set_write_stream_options -output_pin  { geometry }

write_verilog -no_core_filler_cells -no_tap_cells             $net_path/$top_name\.v
write_verilog -no_tap_cells                                   $net_path/$top_name\_filler.v
write_verilog -no_core_filler_cells                           $net_path/$top_name\_tap.v
write_verilog                                                 $net_path/$top_name\_all.v
write_verilog -no_tap_cells                                   $net_path/$top_name\_cds.v
write_stream -format gds -lib_name $top_name -cells $top_name $gds_path/$top_name\.gds
write_sdf -version 2.1                                        $net_path/$top_name\.sdf
write_parasitics -output                                      $net_path/$top_name\.spef
write_def -output                                             $net_path/$top_name\.def -pins

gui_write_window_image -window [gui_get_current_window -types Layout -mru] -file $rpt_path/$top_name\.png

save_mw_cel -design $top_name
quit