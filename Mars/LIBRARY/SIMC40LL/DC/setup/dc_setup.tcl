set CURRENT_PATH                  "OLD_CURRENT_PATH" ;

source -echo -verbose ${CURRENT_PATH}/Synthesis/DC/setup/common_setup.tcl
source -echo -verbose ${CURRENT_PATH}/Synthesis/DC/setup/dc_setup_filenames.tcl

puts "RM-Info: Running script [info script]\n"

#################################################################################
# Design Compiler Reference Methodology Setup for Top-Down Flow
# Script: dc_setup.tcl
# Version: Q-2019.12 
# Copyright (C) 2007-2019 Synopsys, Inc. All rights reserved.
#################################################################################



#################################################################################
# Setup Variables
#
# Modify settings in this section to customize your Design Compiler Reference 
# Methodology run.
# Portions of dc_setup.tcl may be used by other tools so program name checks
# are performed where necessary.
#################################################################################

if {$synopsys_program_name != "mvrc" && $synopsys_program_name != "vsi" && $synopsys_program_name != "vcst"}  {
  # The following setting removes new variable info messages from the end of the log file
  set_app_var sh_new_variable_message false
}

if { $synopsys_program_name == "mvrc"}  {
   # Choose the stage you want to run MVRC. Allowed values are RTL or NETLIST
   set MVRC_RUN "NETLIST"
}

if { $synopsys_program_name == "vsi" || $synopsys_program_name == "vcst"}  {
  # Choose the stage you want to run VC Static. Allowed values are RTL or NETLIST
  set VCLP_RUN "NETLIST"
}

if {$synopsys_program_name == "dc_shell" || $synopsys_program_name == "dcnxt_shell"}  {

  #################################################################################
  # Design Compiler Setup Variables
  #################################################################################

  # Use the set_host_options command to enable multicore optimization to improve runtime.
  # This feature has special usage and license requirements.  Refer to the 
  # "Support for Multicore Technology" section in the Design Compiler User Guide
  # for multicore usage guidelines.
  # Note: This is a DC Ultra feature and is not supported in DC Expert.

   set_host_options -max_cores 16

  if {[shell_is_dcnxt_shell]} {
  set_host_options -max_cores 16
  }


  # Change alib_library_analysis_path to point to a central cache of analyzed libraries
  # to save runtime and disk space.  The following setting only reflects the
  # default value and should be changed to a central location for best results.

  set_app_var alib_library_analysis_path "${CURRENT_PATH}/DC/Temp"

  # In cases where RTL has VHDL generate loops or SystemVerilog structs, switching 
  # activity annotation from SAIF may be rejected, the following variable setting 
  # improves SAIF annotation, by making sure that synthesis object names follow same 
  # naming convention as used by RTL simulation. 

  set_app_var hdlin_enable_upf_compatible_naming true
  
  # Enable the Golden UPF mode to use same originla UPF script file throughout the synthesis,
  # physical implementation, and verification flow.

  set_app_var enable_golden_upf false

  # By default the tool will create supply set handles. If your UPF has domain dependent
  # supply nets, please uncomment the following line:

  # set_app_var upf_create_implicit_supply_sets false
  
  # Add any additional Design Compiler variables needed here

}

set RTL_SOURCE_FILES  "OLD_RTL_SOURCE_FILES"      ;# Enter the list of source RTL files if reading from RTL

# The following variables are used by scripts in the rm_dc_scripts folder to direct 
# the location of the output files.

set REPORTS_DIR "reports"
set RESULTS_DIR "results"

file mkdir ${REPORTS_DIR}
file mkdir ${RESULTS_DIR}

#set variable OPTIMIZATION_FLOW from following RM+ flows
#High Performance Low Power (hplp)
#High Connectivity (hc)
#Runtime Exploration (rtm_exp)

set OPTIMIZATION_FLOW  "hplp" ;# Specify one flow out of hplp | hc | rtm_exp
#################################################################################
# Search Path Setup
#
# Set up the search path to find the libraries and design files.
#################################################################################

  set_app_var search_path ". ${ADDITIONAL_SEARCH_PATH} $search_path"

  # For a hierarchical UPF flow, add the results directory to the search path for
  # Formality to find the output UPF files.

  lappend search_path ${RESULTS_DIR}

#################################################################################
# Library Setup
#
# This section is designed to work with the settings from common_setup.tcl
# without any additional modification.
#################################################################################

if {$synopsys_program_name != "mvrc" && $synopsys_program_name != "vsi" && $synopsys_program_name != "vcst"}  {

  # Milkyway variable settings

  # Make sure to define the Milkyway library variable
  # mw_design_library, it is needed by write_milkyway command

  set mw_reference_library ${MW_REFERENCE_LIB_DIRS}
  set mw_design_library ${DCRM_MW_LIBRARY_NAME}

  set mw_site_name_mapping { {CORE unit} {Core unit} {core unit} }

}

if {$synopsys_program_name == "mvrc"}  {
  set_app_var link_library "$TARGET_LIBRARY_FILES $ADDITIONAL_LINK_LIB_FILES"
}

if {$synopsys_program_name == "vsi" || $synopsys_program_name == "vcst"}  {
  set_app_var link_library "$TARGET_LIBRARY_FILES $ADDITIONAL_LINK_LIB_FILES"
}


# The remainder of the setup below should only be performed in Design Compiler
if {$synopsys_program_name == "dc_shell" || $synopsys_program_name == "dcnxt_shell"}  {

  set_app_var target_library ${TARGET_LIBRARY_FILES}
  set_app_var synthetic_library dw_foundation.sldb

   if { $OPTIMIZATION_FLOW == "hplp" } {
  # Enabling the usage of DesignWare minPower Components requires additional DesignWare-LP license
  # set_app_var synthetic_library "dw_minpower.sldb  dw_foundation.sldb"
   }

  set_app_var link_library "* $target_library $ADDITIONAL_LINK_LIB_FILES $synthetic_library"

  # Set min libraries if they exist
  foreach {max_library min_library} $MIN_LIBRARY_FILES {
    set_min_library $max_library -min_version $min_library
  }

  # Set the variable to use Verilog libraries for Test Design Rule Checking
  # (See dc.tcl for details)

  # set_app_var test_simulation_library <list of Verilog library files>

  if {[shell_is_in_topographical_mode]} {

    # To activate the extended layer mode to support 4095 layers uncomment the extend_mw_layers command 
    # before creating the Milkyway library. The extended layer mode is permanent and cannot be reverted 
    # back to the 255 layer mode once activated.

    # extend_mw_layers

    # Only create new Milkyway design library if it doesn't already exist
    if {![file isdirectory $mw_design_library ]} {
      create_mw_lib   -technology $TECH_FILE \
                      -mw_reference_library $mw_reference_library \
                      $mw_design_library
    } else {
      # If Milkyway design library already exists, ensure that it is consistent with specified Milkyway reference libraries
      set_mw_lib_reference $mw_design_library -mw_reference_library $mw_reference_library
    }

    open_mw_lib     $mw_design_library

    set_check_library_options -upf
    check_library > ${REPORTS_DIR}/${DCRM_CHECK_LIBRARY_REPORT}

    set_tlu_plus_files -max_tluplus $TLUPLUS_MAX_FILE \
                       -min_tluplus $TLUPLUS_MIN_FILE \
                       -tech2itf_map $MAP_FILE

    check_tlu_plus_files
  }

  #################################################################################
  # Library Modifications
  #
  # Apply library modifications after the libraries are loaded.
  #################################################################################

  if {[file exists [which ${LIBRARY_DONT_USE_FILE}]]} {
    puts "RM-Info: Sourcing script file [which ${LIBRARY_DONT_USE_FILE}]\n"
    source -echo -verbose ${LIBRARY_DONT_USE_FILE}
  }
}

puts "RM-Info: Completed script [info script]\n"

