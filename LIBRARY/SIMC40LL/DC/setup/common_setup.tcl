puts "RM-Info: Running script [info script]\n"

##########################################################################################
# Variables common to all reference methodology scripts
# Script: common_setup.tcl
# Version: Q-2019.12 
# Copyright (C) 2007-2019 Synopsys, Inc. All rights reserved.
##########################################################################################

set DESIGN_NAME                   "OLD_DESIGN_NAME"  ;#  The name of the top-level design

set CURRENT_PATH                  "OLD_CURRENT_PATH" ; 

set DESIGN_REF_DATA_PATH          "${CURRENT_PATH}/Source"  ; 

                                                                                          #  Absolute path prefix variable for library/design data.
                                                                                            #  Use this variable to prefix the common absolute path  
                                                                                            #  to the common variables defined below.
                                                                                            #  Absolute paths are mandatory for hierarchical 
                                                                                            #  reference methodology flow.


##########################################################################################
# Hierarchical Flow Design Variables
##########################################################################################

set HIERARCHICAL_DESIGNS           "" ;# List of hierarchical block design names "DesignA DesignB" ...
set HIERARCHICAL_CELLS             "" ;# List of hierarchical block cell instance names "u_DesignA u_DesignB" ...

##########################################################################################
# Library Setup Variables
##########################################################################################

# For the following variables, use a blank space to separate multiple entries.
# Example: set TARGET_LIBRARY_FILES "lib1.db lib2.db lib3.db"

set ADDITIONAL_SEARCH_PATH        "/export/yfxie02/library/SMIC40LL/STDCELL/SCC40NLL_VHSC40_RVT_V0.1/SCC40NLL_VHSC40_RVT_V0p1/liberty/1.1v\
                                  ${CURRENT_PATH}/Synthesis/SDC \
                                  ${CURRENT_PATH}/Synthesis/SAIF \
                                  ${CURRENT_PATH}/Synthesis/DONT_USE"  ;#  Additional search path to be added to the default search path

set TARGET_LIBRARY_FILES          "scc40nll_vhsc40_rvt_tt_v1p1_125c_ccs.db"  ;#  Target technology logical libraries

set ADDITIONAL_LINK_LIB_FILES     "scc40nll_vhsc40_rvt_tt_v1p1_125c_ccs.db"  ;#  Extra link logical libraries not included in TARGET_LIBRARY_FILES

set MIN_LIBRARY_FILES             ""  ;#  List of max min library pairs "max1 min1 max2 min2 max3 min3"...

set MW_REFERENCE_LIB_DIRS         "/export/yfxie02/library/SMIC40LL/STDCELL/SCC40NLL_VHSC40_RVT_V0.1/SCC40NLL_VHSC40_RVT_V0p1/astro/scc40nll_vhsc40_rvt"  ;#  Milkyway reference libraries (include IC Compiler ILMs here)

set MW_REFERENCE_CONTROL_FILE     ""  ;#  Reference Control file to define the Milkyway reference libs

set TECH_FILE                     "/export/yfxie02/library/SMIC40LL/STDCELL/SCC40NLL_VHSC40_RVT_V0.1/SCC40NLL_VHSC40_RVT_V0p1/astro/tf/scc40nll_vhs_7lm_1tm.tf "  ;#  Milkyway technology file
set MAP_FILE                      "/export/yfxie02/library/SMIC40LL/STDCELL/SCC40NLL_VHSC40_RVT_V0.1/SCC40NLL_VHSC40_RVT_V0p1/astro/tluplus/TD-LO40-XS-2002v1R_1PxM_1TM9k_ALPA14.5k/1P7M_1TM/StarRC_40LL_1P7M_1TM_cell.map"  ;#  Mapping file for TLUplus
set TLUPLUS_MAX_FILE             "/export/yfxie02/library/SMIC40LL/STDCELL/SCC40NLL_VHSC40_RVT_V0.1/SCC40NLL_VHSC40_RVT_V0p1/astro/tluplus/TD-LO40-XS-2002v1R_1PxM_1TM9k_ALPA14.5k/1P7M_1TM/StarRC_40LL_1P7M_1TM_RCMAX.tluplus"  ;#  Max TLUplus file
set TLUPLUS_MIN_FILE              "/export/yfxie02/library/SMIC40LL/STDCELL/SCC40NLL_VHSC40_RVT_V0.1/SCC40NLL_VHSC40_RVT_V0p1/astro/tluplus/TD-LO40-XS-2002v1R_1PxM_1TM9k_ALPA14.5k/1P7M_1TM/StarRC_40LL_1P7M_1TM_RCMIN.tluplus"  ;#  Min TLUplus file

set MIN_ROUTING_LAYER            "M2"   ;# Min routing layer
set MAX_ROUTING_LAYER            "M7"   ;# Max routing layer

set LIBRARY_DONT_USE_FILE        "dont_use.tcl"   ;# Tcl file with library modifications for dont_use
set LIBRARY_DONT_USE_PRE_COMPILE_LIST ""; #Tcl file for customized don't use list before first compile
set LIBRARY_DONT_USE_PRE_INCR_COMPILE_LIST "";# Tcl file with library modifications for dont_use before incr compile
##########################################################################################
# Multivoltage Common Variables
#
# Define the following multivoltage common variables for the reference methodology scripts 
# for multivoltage flows. 
# Use as few or as many of the following definitions as needed by your design.
##########################################################################################

# set PD1                          ""           ;# Name of power domain/voltage area  1
# set VA1_COORDINATES              {}           ;# Coordinates for voltage area 1
# set MW_POWER_NET1                "VDD1"       ;# Power net for voltage area 1

# set PD2                          ""           ;# Name of power domain/voltage area  2
# set VA2_COORDINATES              {}           ;# Coordinates for voltage area 2
# set MW_POWER_NET2                "VDD2"       ;# Power net for voltage area 2

# set PD3                          ""           ;# Name of power domain/voltage area  3
# set VA3_COORDINATES              {}           ;# Coordinates for voltage area 3
# set MW_POWER_NET3                "VDD3"       ;# Power net for voltage area 3

# set PD4                          ""           ;# Name of power domain/voltage area  4
# set VA4_COORDINATES              {}           ;# Coordinates for voltage area 4
# set MW_POWER_NET4                "VDD4"       ;# Power net for voltage area 4

puts "RM-Info: Completed script [info script]\n"

