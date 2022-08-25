
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
# quit