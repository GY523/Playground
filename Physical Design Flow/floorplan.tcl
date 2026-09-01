#============================================================
# floorplan.tcl
# Version 0 - QUERY ONLY
#
# Purpose:
#   Verify floorplan/database information before making
#   any physical placement modifications.
#
# IMPORTANT:
#   This version must NOT modify the Innovus database.
#============================================================

#============================================================
# 1. Banner
#============================================================

puts ""
puts "============================================================"
puts " FLOORPLAN VERSION 0 : QUERY ONLY"
puts "============================================================"

#============================================================
# 2. Design / technology information
#============================================================

set design_name [dbget top.name]
set db_units    [dbget head.dbUnits]
set mfg_grid    [dbget head.mfgGrid]

puts "Design            :$design_name"
puts "Database units    : $db_units"
puts "Manufacturing grid: $mfg_grid"

#============================================================
# 3. Floorplan geometry
#============================================================
set die_box [dbget top.fPlan.boxes]
set core_box [dbget top.fPlan.coreBox]
set core_site [dbget -e top.fPlan.coreSite.name]

puts ""
puts "Die Box           :$die_box"
puts "Core Box          : $core_box"
puts "Core site         : $core_site"

#============================================================
# 4. Expected IO instances
#============================================================

set io_ptrs [dbget top.insts.cell.baseClass pad -p2 ]
set io_insts [dbget $io_ptrs.name ]

#============================================================
# 5. Expected hard macros
#============================================================

set macro_ptrs [dbget top.insts.cell.baseClass block -p2]
set macro_insts [dbget $macro_ptrs.name]

#============================================================
# 6. Query/report procedure
#============================================================

proc report_instance { inst_name } {

    set inst_ptr [dbget -p -e top.insts.name $inst_name]

    set db_name     [dbget $inst_ptr.name]
    set cell_name   [dbget $inst_ptr.cell.name]
    
    set base_class  [dbget $inst_ptr.cell.baseClass]
    set sub_class   [dbget $inst_ptr.cell.subClass  ]
    
    set location    [dbget $inst_ptr.pt]
    set bbox        [dbget $inst_ptr.box]

    set width       [dbget $inst_ptr.box_sizex]
    set height      [dbget $inst_ptr.box_sizey]
    
    set orient      [dbget $inst_ptr.orient] 
    set pstatus     [dbget $inst_ptr.pStatus]

    puts "--"
    puts "Instance name      : $db_name"
    puts "Base cell          : $cell_name"
    puts "Base class         : $base_class"
    puts "Sub class          : $sub_class"
    puts "Location           : $location"
    puts "BBox               : $bbox"
    puts "BBox width         : $width"
    puts "BBox height        : $height"
    puts "Orientation        : $orient"
    puts "Placement status   : $pstatus"

    return 1

}

#============================================================
# 7. IO report
#============================================================

puts ""
puts "============================================================"
puts " IO INSTANCE REPORT"
puts "============================================================"

set io_found 0

foreach inst $io_insts {

    if { [report_instance $inst]} {
        incr io_found
    }
}

#============================================================
# 8. Macro report
#============================================================

puts ""
puts "============================================================"
puts " HARD MACRO REPORT"
puts "============================================================"

set macro_found 0

foreach inst $macro_insts {

    if {[report_instance $inst]} { 
        incr macro_found
    }
}

#============================================================
# 10. Summary
#============================================================

puts ""
puts "============================================================"
puts " VERSION 0 SUMMARY"
puts "============================================================"

puts "Found [llength $macro_insts] macro instances:"
foreach inst $macro_insts {
    puts "  $inst"
}

puts "Found [llength $io_insts] IO instances:"
foreach inst $io_insts {
    puts "  $inst"
}

puts ""
puts "QUERY-ONLY FLOORPLAN SCRIPT COMPLETE"
puts "No placement modifications performed."
puts "============================================================"