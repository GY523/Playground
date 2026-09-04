##############################################################################
# set variable && restoreDesign 
##############################################################################

#source -echo -verbose alias.tcl
#source -echo -verbose proc.tcl

set design_name		[dbGet top.name]
set prev_stage 		"init"
set curr_stage 		"prePlace"
set stamp 		[exec date +%m%d%H%M]



##############################################################################
# set global design
##############################################################################

source ../scr/user_scr/setup.tcl
source ../scr/user_scr/pr_setting.tcl
#source ../DB/${design_name}_${prev_stage}_${PR_VER}.enc
source ../scr/user_scr/set_globals_mode_constraint.tcl
setMultiCpuUsage -localCpu $MAX_CORES

##############################################################################
# fplan
##############################################################################

##### defIn 
# 
#core2die :

# plan ports
#pin_assign ...

# FPlan : memory/IP/IO/HLB/ESDcell...
#checkPlace 


# addHardBlk For memory/IP/IO/HLB/ESDcell...

set preplace_script_dir [file dirname [file normalize [info script]]]

source [file join $preplace_script_dir floorplan.tcl]

##############################################################################
# add MTCMOS // Level shift 
##############################################################################
#source 



##############################################################################
# add physical cell 
##############################################################################

## Add boundary cells 
#setEndCapMode -lefEdge $vars(cell,boundary,left) -rightEdge $vars(cell,boundary,right)
#addEndCap -prefix Bndry -powerDomain PDCORTEXA53
#addEndCap -prefix Bndry

setEndCapMode -reset
setEndCapMode -leftEdge SVH_TAP_DS -rightEdge SVH_TAP_DS
setEndCapMode -leftTopEdge SVH_TAP_DS -leftBottomEdge SVH_TAP_DS
setEndCapMode -rightTopEdge SVH_TAP_DS -rightBottomEdge SVH_TAP_DS
setEndCapMode -leftBottomCorner SVH_TAP_DS -rightBottomCorner SVH_TAP_DS
setEndCapMode -leftTopCorner SVH_TAP_DS -rightTopCorner SVH_TAP_DS
setEndCapMode -topEdge $vars(cell,endcap) -bottomEdge $vars(cell,endcap)
addEndCap -prefix ENDCAP

## Add WELLTAP 
#addWellTap -cell $vars(cell,tap_cell) -cellInterval $vars(cell,tap_distance) -prefix WELLTAP -checkBoard -powerDomain PDCORTEXA53
#addWellTap -cell $vars(cell,tap_cell) -cellInterval $vars(cell,tap_distance) -prefix WELLTAP -checkBoard -domain
addWellTap -checkerBoard -cell $vars(cell,tap_cell) -cellInterval $vars(cell,tap_distance) -prefix WELLTAP  

 
## Add GFILL


# addsoftblockage
#source 

##############################################################################
# power Plan
##############################################################################
# addroutingblk For power
#source 


# add MTCMOS/Level shift power


# add core power
source ../scr/pg_connect.tcl ;## memory enhance/IP/core
#source SCRIPTS/power_plan.tcl


##############################################################################
# add Buffer (test1)
##############################################################################

# place iso

# add port buffer 
#attachIOBuffer -baseName IOBUF -in TISCL7CNMV0_BUF_4 -out TISCL7CNMV0_BUF_8 -excNetFile ./clk_port.txt -status fixed
#dbSet top.terms.net.dontTouch true
# add memory buffer

# add IP buffer


##############################################################################
# add Place Guide 
##############################################################################
# add place guide For BES

# add place guide For DFT

# add place guide For BUS

#addrouting blk For routing congestion


##############################################################################
# saveDesign 
##############################################################################

set stamp [exec date +%m%d%H%M]
saveDesign -tcon ../DB/${design_name}_${curr_stage}_${PR_VER}.enc


##############################################################################
# writeOut
##############################################################################

#set layer 
#writeLef


##############################################################################
# exit innovus
##############################################################################

exit

