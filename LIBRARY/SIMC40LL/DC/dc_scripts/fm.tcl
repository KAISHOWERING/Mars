set CURRENT_PATH                  "OLD_CURRENT_PATH" ;

source -echo -verbose ${CURRENT_PATH}/Synthesis/DC/setup/dc_setup.tcl

#################################################################################
# Formality Verification Script for
# Design Compiler Reference Methodology Script for Top-Down Flow
# Script: fm.tcl
# Version: Q-2019.12  
# Copyright (C) 2007-2019 Synopsys, Inc. All rights reserved.
#################################################################################

#################################################################################
# Synopsys Auto Setup Mode
#################################################################################

set_app_var synopsys_auto_setup true

# Note: The Synopsys Auto Setup mode is less conservative than the Formality default 
# mode, and is more likely to result in a successful verification out-of-the-box.
#
# Using the Setting this variable will change the default values of the variables 
# listed here below. You may change any of these variables back to their default 
# settings to be more conservative. Uncomment the appropriate lines below to revert 
# back to their default settings:

	# set_app_var hdlin_ignore_parallel_case true
	# set_app_var hdlin_ignore_full_case true
	# set_app_var verification_verify_directly_undriven_output true
	# set_app_var hdlin_ignore_embedded_configuration false
	# set_app_var svf_ignore_unqualified_fsm_information true
	# set_app_var signature_analysis_allow_subset_match true

# Other variables with changed default values are described in the next few sections.

#################################################################################
# Setup for handling undriven signals in the design
#################################################################################

# The Synopsys Auto Setup mode sets undriven signals in the reference design to
# "0" or "BINARY" (as done by DC), and the undriven signals in the impl design are
# forced to "BINARY".  This is done with the following setting:

	# set_app_var verification_set_undriven_signals synthesis

# Uncomment the next line to revert back to the more conservative default setting:

	# set_app_var verification_set_undriven_signals BINARY:X

#################################################################################
# Setup for simulation/synthesis mismatch messaging
#################################################################################

# The Synopsys Auto Setup mode will produce warning messages, not error messages,
# when Formality encounters potential differences between simulation and synthesis.
# Uncomment the next line to revert back to the more conservative default setting:

	# remove_mismatch_message_filter -all

#################################################################################
# Setup for Clock-gating
#################################################################################

# The Synopsys Auto Setup mode, along with the SVF file, will appropriately set 
# the clock-gating variable. Otherwise, the user will need to notify Formality 
# of clock-gating by uncommenting the next line:

	# set_app_var verification_clock_gate_hold_mode any

#################################################################################
# Setup for instantiated DesignWare or function-inferred DesignWare components
#################################################################################

# The Synopsys Auto Setup mode, along with the SVF file, will automatically set 
# the hdlin_dwroot variable to the top-level of the Design Compiler tree used for 
# synthesis.  Otherwise, the user will need to set this variable if the design 
# contains instantiated DW or function-inferred DW.

	# set_app_var hdlin_dwroot "" ;# Enter the pathname to the top-level of the DC tree

#################################################################################
# Setup for handling missing design modules
#################################################################################

# If the design has missing blocks or missing components in both the reference and 
# implementation designs, uncomment the following variable so that Formality can 
# complete linking each design:

	# set_app_var hdlin_unresolved_modules black_box

#################################################################################
# Read in the SVF file(s)
#################################################################################

# Set this variable to point to individual SVF file(s) or to a directory containing SVF files.

set_svf ${RESULTS_DIR}/${DCRM_SVF_OUTPUT_FILE}

#################################################################################
# Read in the libraries
#################################################################################

foreach tech_lib "${TARGET_LIBRARY_FILES} ${ADDITIONAL_LINK_LIB_FILES}" {
  read_db -technology_library $tech_lib
}

#################################################################################
# Read in the Reference Design as verilog/vhdl source code
#################################################################################

read_verilog -r ${RTL_SOURCE_FILES} -work_library WORK

# Note: If retention registers are instantiated in the RTL then replace the
#       technology retention register models here.  See the implementation read
#       section below for details.  This should be done before set_top.
#       Most designs do not have retention registers until after mapping so
#       this is not needed.

# The following setting is needed to exclude instantiated ICG cells from being
# retained inside retention domains (same behavior as Design Compiler)

set_app_var upf_use_additional_db_attributes true

set_top r:/WORK/${DESIGN_NAME}

#################################################################################
# For a UPF MV flow, read in the UPF file for the Reference Design
#################################################################################

load_upf -r ${DCRM_MV_UPF_INPUT_FILE}

#################################################################################
# Read in the Implementation Design from DC-RM results
#
# Choose the format that is used in your flow.
#################################################################################

# For DDC
#read_ddc -i ${RESULTS_DIR}/${DCRM_FINAL_DDC_OUTPUT_FILE}

# OR

# For Verilog
read_verilog -i ${RESULTS_DIR}/${DCRM_FINAL_VERILOG_OUTPUT_FILE}

# Note: Milkyway design format is not supported with UPF flow in Formality.


#################################################################################
# Read in Retention Register Simulation Models
#################################################################################

# If you are mapping to retention registers in your design, you need to replace the
# technology library models of those cells with Verilog simulation models for
# Formality verification.  Please see the following SolvNet article for details:

# https://solvnet.synopsys.com/retrieve/024106.html

# set_top should be run only after the retention register models have been replaced. 

set_top i:/WORK/${DESIGN_NAME}

#################################################################################
# For a UPF MV flow, read in the UPF file for the Implementation Design
#################################################################################

load_upf -i -strict_check false -target dc_netlist ${DCRM_MV_UPF_INPUT_FILE} \
         -supplemental ${RESULTS_DIR}/${DCRM_MV_FINAL_UPF_OUTPUT_FILE}


#################################################################################
# Configure constant ports
#
# When using the Synopsys Auto Setup mode, the SVF file will convey information
# automatically to Formality about how to disable scan.
#
# Otherwise, manually define those ports whose inputs should be assumed constant
# during verification.
#
# Example command format:
#
#   set_constant -type port i:/WORK/${DESIGN_NAME}/<port_name> <constant_value> 
#
#################################################################################

#################################################################################
# Report design statistics, design read warning messages, and user specified setup
#################################################################################

# report_setup_status will create a report showing all design statistics,
# design read warning messages, and all user specified setup.  This will allow
# the user to check all setup before proceeding to run the more time consuming
# commands "match" and "verify".

# report_setup_status

#################################################################################
# Note in using the UPF MV flow with Formality:
#
# By default Formality verifies low power designs with all UPF supplies 
# constrained to their ON state.  This is only a partial verification result.
# To cover all operational power states, uncomment the following variable setting:
#
      # set_app_var verification_force_upf_supplies_on false
#
#################################################################################

#################################################################################
# Match compare points and report unmatched points 
#################################################################################

match

report_unmatched_points > ${REPORTS_DIR}/${FMRM_UNMATCHED_POINTS_REPORT}


#################################################################################
# Verify and Report
#
# If the verification is not successful, the session will be saved and reports
# will be generated to help debug the failed or inconclusive verification.
#################################################################################

if { ![verify] }  {  
  save_session -replace ${REPORTS_DIR}/${FMRM_FAILING_SESSION_NAME}
  report_failing_points > ${REPORTS_DIR}/${FMRM_FAILING_POINTS_REPORT}
  report_aborted > ${REPORTS_DIR}/${FMRM_ABORTED_POINTS_REPORT}
  # Use analyze_points to help determine the next step in resolving verification
  # issues. It runs heuristic analysis to determine if there are potential causes
  # other than logical differences for failing or hard verification points. 
  analyze_points -all > ${REPORTS_DIR}/${FMRM_ANALYZE_POINTS_REPORT}
}

exit
