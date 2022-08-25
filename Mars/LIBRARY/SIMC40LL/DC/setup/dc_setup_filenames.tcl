puts "RM-Info: Running script [info script]\n"

#################################################################################
# Design Compiler Reference Methodology Filenames Setup
# Script: dc_setup_filenames.tcl
# Version: Q-2019.12 
# Copyright (C) 2010-2019 Synopsys, Inc. All rights reserved.
#################################################################################

#################################################################################
# Use this file to customize the filenames used in the Design Compiler
# Reference Methodology scripts.  This file is designed to be sourced at the
# beginning of the dc_setup.tcl file after sourcing the common_setup.tcl file.
#
# Note that the variables presented in this file depend on the type of flow
# selected when generating the reference methodology files.
#
# Example.
#    If you set DFT flow as FALSE, you will not see DFT related filename
#    variables in this file.
#
# When reusing this file for different flows or newer release, ensure that
# all the required filename variables are defined.  One way to do this is
# to source the default dc_setup_filenames.tcl file and then override the
# default settings as needed for your design.
#
# The default values are backwards compatible with older
# Design Compiler Reference Methodology releases.
#
# Note: Care should be taken when modifying the names of output files
#       that are used in other scripts or tools.
#################################################################################

#################################################################################
# General Flow Files
#################################################################################

##########################
# Milkyway Library Names #
##########################

set DCRM_MW_LIBRARY_NAME                                ${DESIGN_NAME}_LIB
set DCRM_FINAL_MW_CEL_NAME                              ${DESIGN_NAME}_DCT

###############
# Input Files #
###############

set DCRM_SDC_INPUT_FILE                                 ${DESIGN_NAME}.sdc
set DCRM_CONSTRAINTS_INPUT_FILE                         ${DESIGN_NAME}.constraints.tcl

###########
# Reports #
###########

set DCRM_CHECK_LIBRARY_REPORT                           ${DESIGN_NAME}.check_library.rpt

set DCRM_CONSISTENCY_CHECK_ENV_FILE                     ${DESIGN_NAME}.compile_ultra.env
set DCRM_CHECK_DESIGN_REPORT                            ${DESIGN_NAME}.check_design.rpt
set DCRM_ANALYZE_DATAPATH_EXTRACTION_REPORT             ${DESIGN_NAME}.analyze_datapath_extraction.rpt

set DCRM_FINAL_QOR_REPORT                               ${DESIGN_NAME}.mapped.qor.rpt
set DCRM_FINAL_TIMING_REPORT                            ${DESIGN_NAME}.mapped.timing.rpt

set DCRM_FINAL_RTL_SAIF_REPORT                        ${DESIGN_NAME}.rtl.saif.rpt
set DCRM_FINAL_SAIF_REPORT                                  ${DESIGN_NAME}.saif.rpt

set DCRM_FINAL_AREA_REPORT                              ${DESIGN_NAME}.mapped.area.rpt
set DCRM_FINAL_POWER_REPORT                             ${DESIGN_NAME}.mapped.power.rpt
set DCRM_FINAL_CLOCK_GATING_REPORT                      ${DESIGN_NAME}.mapped.clock_gating.rpt
set DCRM_FINAL_SELF_GATING_REPORT                       ${DESIGN_NAME}.mapped.self_gating.rpt
set DCRM_THRESHOLD_VOLTAGE_GROUP_REPORT                 ${DESIGN_NAME}.mapped.threshold.voltage.group.rpt
set DCRM_INSTANTIATE_CLOCK_GATES_REPORT                 ${DESIGN_NAME}.instantiate_clock_gates.rpt
set DCRM_FINAL_DESIGNWARE_AREA_REPORT                   ${DESIGN_NAME}.mapped.designware_area.rpt
set DCRM_FINAL_RESOURCES_REPORT                         ${DESIGN_NAME}.mapped.final_resources.rpt

set DCRM_MULTIBIT_CREATE_REGISTER_BANK_FILE             ${DESIGN_NAME}.register_bank.rpt
set DCRM_MULTIBIT_CREATE_REGISTER_BANK_REPORT           ${DESIGN_NAME}.register_bank_report_file.rpt 
set DCRM_MULTIBIT_COMPONENTS_REPORT                     ${DESIGN_NAME}.multibit.components.rpt
set DCRM_MULTIBIT_BANKING_REPORT                        ${DESIGN_NAME}.multibit.banking.rpt


################
# Output Files #
################

set DCRM_AUTOREAD_RTL_SCRIPT                            ${DESIGN_NAME}.autoread_rtl.tcl
set DCRM_ELABORATED_DESIGN_DDC_OUTPUT_FILE              ${DESIGN_NAME}.elab.ddc
set DCRM_COMPILE_ULTRA_DDC_OUTPUT_FILE                  ${DESIGN_NAME}.compile_ultra.ddc
set DCRM_FINAL_DDC_OUTPUT_FILE                          ${DESIGN_NAME}.mapped.ddc
set DCRM_FINAL_PG_VERILOG_OUTPUT_FILE                   ${DESIGN_NAME}.mapped.pg.v
set DCRM_FINAL_VERILOG_OUTPUT_FILE                      ${DESIGN_NAME}.mapped.v
set DCRM_FINAL_SDC_OUTPUT_FILE                          ${DESIGN_NAME}.mapped.sdc
set DCRM_FINAL_DESIGN_ICC2                              ICC2_files


#################################################################################
# DCT Flow Files
#################################################################################

###################
# DCT Input Files #
###################

set DCRM_DCT_DEF_INPUT_FILE                             ${DESIGN_NAME}.def
set DCRM_DCT_FLOORPLAN_INPUT_FILE                       ${DESIGN_NAME}.fp
set DCRM_DCT_PHYSICAL_CONSTRAINTS_INPUT_FILE            ${DESIGN_NAME}.physical_constraints.tcl


###############
# DCT Reports #
###############

set DCRM_DCT_PHYSICAL_CONSTRAINTS_REPORT                ${DESIGN_NAME}.physical_constraints.rpt

set DCRM_DCT_FINAL_CONGESTION_REPORT                    ${DESIGN_NAME}.mapped.congestion.rpt
set DCRM_DCT_FINAL_CONGESTION_MAP_OUTPUT_FILE           ${DESIGN_NAME}.mapped.congestion_map.png
set DCRM_DCT_FINAL_CONGESTION_MAP_WINDOW_OUTPUT_FILE    ${DESIGN_NAME}.mapped.congestion_map_window.png
set DCRM_ANALYZE_RTL_CONGESTION_REPORT_FILE             ${DESIGN_NAME}.analyze_rtl_congetion.rpt

set DCRM_DCT_FINAL_QOR_SNAPSHOT_FOLDER                  ${DESIGN_NAME}.qor_snapshot
set DCRM_DCT_FINAL_QOR_SNAPSHOT_REPORT                  ${DESIGN_NAME}.qor_snapshot.rpt

####################
# DCT Output Files #
####################

set DCRM_DCT_FLOORPLAN_OUTPUT_FILE                      ${DESIGN_NAME}.initial.fp

set DCRM_DCT_FINAL_FLOORPLAN_OUTPUT_FILE                ${DESIGN_NAME}.mapped.fp
set DCRM_DCT_FINAL_SPEF_OUTPUT_FILE                     ${DESIGN_NAME}.mapped.spef
set DCRM_DCT_FINAL_SDF_OUTPUT_FILE                      ${DESIGN_NAME}.mapped.sdf

# Uncomment the DCRM_DCT_SPG_PLACEMENT_OUTPUT_FILE variable setting to save the
# standard cell placement for physical guidance flow when ASCII hand-off to IC Compiler 
# is used.  

# set DCRM_DCT_SPG_PLACEMENT_OUTPUT_FILE                  ${DESIGN_NAME}.mapped.std_cell.def

#################################################################################
# DFT Flow Files
#################################################################################

###################
# DFT Input Files #
###################

set DCRM_DFT_SIGNAL_SETUP_INPUT_FILE                    ${DESIGN_NAME}.dft_signal_defs.tcl
set DCRM_DFT_AUTOFIX_CONFIG_INPUT_FILE                  ${DESIGN_NAME}.dft_autofix_config.tcl

###############
# DFT Reports #
###############

set DCRM_DFT_DRC_CONFIGURED_VERBOSE_REPORT              ${DESIGN_NAME}.dft_drc_configured.rpt
set DCRM_DFT_SCAN_CONFIGURATION_REPORT                  ${DESIGN_NAME}.scan_config.rpt
set DCRM_DFT_COMPRESSION_CONFIGURATION_REPORT           ${DESIGN_NAME}.compression_config.rpt
set DCRM_DFT_PREVIEW_CONFIGURATION_REPORT               ${DESIGN_NAME}.report_dft_insertion_config.preview_dft.rpt
set DCRM_DFT_PREVIEW_DFT_SUMMARY_REPORT                 ${DESIGN_NAME}.preview_dft_summary.rpt
set DCRM_DFT_PREVIEW_DFT_ALL_REPORT                     ${DESIGN_NAME}.preview_dft.rpt

set DCRM_DFT_FINAL_SCAN_PATH_REPORT                     ${DESIGN_NAME}.mapped.scanpath.rpt
set DCRM_DFT_DRC_FINAL_REPORT                           ${DESIGN_NAME}.mapped.dft_drc_inserted.rpt
set DCRM_DFT_FINAL_SCAN_COMPR_SCAN_PATH_REPORT          ${DESIGN_NAME}.mapped.scanpath.scan_compression.rpt
set DCRM_DFT_DRC_FINAL_SCAN_COMPR_REPORT                ${DESIGN_NAME}.mapped.dft_drc_inserted.scan_compression.rpt
set DCRM_DFT_FINAL_CHECK_SCAN_DEF_REPORT                ${DESIGN_NAME}.mapped.check_scan_def.rpt
set DCRM_DFT_FINAL_DFT_SIGNALS_REPORT                   ${DESIGN_NAME}.mapped.dft_signals.rpt

####################
# DFT Output Files #
####################

set DCRM_DFT_FINAL_SCANDEF_OUTPUT_FILE                  ${DESIGN_NAME}.mapped.scandef
set DCRM_DFT_FINAL_EXPANDED_SCANDEF_OUTPUT_FILE         ${DESIGN_NAME}.mapped.expanded.scandef
set DCRM_DFT_FINAL_CTL_OUTPUT_FILE                      ${DESIGN_NAME}.mapped.ctl
set DCRM_DFT_FINAL_PROTOCOL_OUTPUT_FILE                 ${DESIGN_NAME}.mapped.scan.spf
set DCRM_DFT_FINAL_SCAN_COMPR_PROTOCOL_OUTPUT_FILE      ${DESIGN_NAME}.mapped.scancompress.spf


#################################################################################
# MV Flow Files
#################################################################################

###################
# MV Input Files  #
###################

set DCRM_MV_UPF_INPUT_FILE                              ${DESIGN_NAME}.upf
set DCRM_MV_SET_VOLTAGE_INPUT_FILE                      ${DESIGN_NAME}.set_voltage.tcl
set DCRM_MV_DCT_VOLTAGE_AREA_INPUT_FILE                 ${DESIGN_NAME}.create_voltage_area.tcl

##############
# MV Reports #
##############

set DCRM_MV_DRC_FINAL_SUMMARY_REPORT                    ${DESIGN_NAME}.mv_drc.final_summary.rpt
set DCRM_MV_DRC_FINAL_VERBOSE_REPORT                    ${DESIGN_NAME}.mv_drc.final.rpt
set DCRM_MV_FINAL_POWER_DOMAIN_REPORT                   ${DESIGN_NAME}.mapped.power_domain.rpt
set DCRM_MV_FINAL_POWER_SWITCH_REPORT                   ${DESIGN_NAME}.mapped.power_switch.rpt
set DCRM_MV_FINAL_SUPPLY_NET_REPORT                     ${DESIGN_NAME}.mapped.supply_net.rpt
set DCRM_MV_FINAL_PST_REPORT                            ${DESIGN_NAME}.mapped.pst.rpt
set DCRM_MV_FINAL_LEVEL_SHIFTER_REPORT                  ${DESIGN_NAME}.mapped.level_shifter.rpt
set DCRM_MV_FINAL_ISOLATION_CELL_REPORT                 ${DESIGN_NAME}.mapped.isolation_cell.rpt
set DCRM_MV_FINAL_RETENTION_CELL_REPORT                 ${DESIGN_NAME}.mapped.retention_cell.rpt

####################
# MV Output Files  #
####################

set DCRM_MV_FINAL_UPF_OUTPUT_FILE                       ${DESIGN_NAME}.supplement.upf
set DCRM_MV_FINAL_LINK_LIBRARY_OUTPUT_FILE              ${DESIGN_NAME}.link_library.tcl

#################################################################################
# Formality Flow Files
#################################################################################

set DCRM_SVF_OUTPUT_FILE                                ${DESIGN_NAME}.mapped.svf

set FMRM_UNMATCHED_POINTS_REPORT                        ${DESIGN_NAME}.fmv_unmatched_points.rpt

set FMRM_FAILING_SESSION_NAME                           ${DESIGN_NAME}
set FMRM_FAILING_POINTS_REPORT                          ${DESIGN_NAME}.fmv_failing_points.rpt
set FMRM_ABORTED_POINTS_REPORT                          ${DESIGN_NAME}.fmv_aborted_points.rpt
set FMRM_ANALYZE_POINTS_REPORT                          ${DESIGN_NAME}.fmv_analyze_points.rpt

puts "RM-Info: Completed script [info script]\n"
