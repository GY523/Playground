#============================================================
# floorplan.tcl
# Version 1 - IO PLACEMENT
#
# Purpose:
#   1. Query floorplan/database information.
#   2. Discover PAD and BLOCK instances.
#   3. Identify required IO PADs.
#   4. Place required IO PADs adjacently on right side.
#
# IMPORTANT:
#   This version must NOT modify the Innovus database.
#============================================================

#============================================================
# 1. Banner
#============================================================

puts ""
puts "============================================================"
puts " FLOORPLAN VERSION 1 : IO PLACEMENT"
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
set die_coord [lindex [lindex $die_box 0] 0]
set core_box [dbget top.fPlan.coreBox]
set core_coord [lindex $core_box 0]
lassign $die_coord die_llx die_lly die_urx die_ury
lassign $core_coord core_llx core_lly core_urx core_ury

set core_site [dbget -e top.fPlan.coreSite.name]

puts ""
puts "Die Box           :$die_box"
puts "Core Box          : $core_box"
puts "Core site         : $core_site"

#============================================================
# 4. Discover Physical Objects
#============================================================
# IO instances 
set io_ptrs [dbget top.insts.cell.baseClass pad -p2 ]
set io_insts [dbget $io_ptrs.name ]

# BLock instances
set macro_ptrs [dbget top.insts.cell.baseClass block -p2]
set macro_insts [dbget $macro_ptrs.name]

#============================================================
# 5. Helper procedures
#============================================================

proc find_io_by_keyword { io_ptrs keyword} {

    # find the instance name that match with keyword then, check for the number of matches must be one 
    set matches [ dbget -e $io_ptrs.name "*$keyword*" ]

    if { [llength $matches ] == 0} {
        error "IO ERROR : no pad instance matched keyword: $keyword"
    }

    if {[llength $matches] > 1} {
        error "IO ERROR: Multiple PAD instances matched keyword '$keyword': $matches"
    }

    return [lindex $matches 0]
}

proc find_macro_by_keyword {macro_ptrs keyword} {
    set matches [dbget -e $macro_ptrs.name "*$keyword*"]

    if { [llength $matches ] == 0} {
        error "IO ERROR : no pad isntance matched keyword: $keyword"
    }

    if {[llength $matches] > 1} {
        error "IO ERROR: Multiple PAD instances matched keyword '$keyword': $matches"
    }

    return [lindex $matches 0]
}

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
# 6. Identify Required IO
#============================================================
set io_vdd    [find_io_by_keyword $io_ptrs "vdd"]
set io_vcc    [find_io_by_keyword $io_ptrs "vcc"]
set io_vss    [find_io_by_keyword $io_ptrs "vss"]
set io_scirst [find_io_by_keyword $io_ptrs "scirst"]
set io_sciclk [find_io_by_keyword $io_ptrs "sciclk"]
set io_sciio  [find_io_by_keyword $io_ptrs "sciio"]

#============================================================
# 7. Build required IO order
#============================================================

set ordered_io_insts [list \
    $io_vdd \
    $io_vcc \
    $io_vss \
    $io_scirst \
    $io_sciclk \
    $io_sciio \
]

#============================================================
# 8. Right-side IO Placement
#============================================================
# R0 -> N
# R90 -> W
# R180 -> S
# R270 -> E
# Rotate anti clockwise

set io_orient R90
set io_spacing 0.0

# ALL pad origins align to the right edge of core 
set io_x $core_urx 

# Starting Y = 75% of the total die height 
set die_height [expr {$die_ury - $die_lly}]
set io_top_y    [expr { $die_lly + 0.75 * $die_height}]

set cursor_y $io_top_y

foreach inst $ordered_io_insts {
    set inst_ptr [dbget -p -e top.insts.name $inst]
    set master_width [dbget $inst_ptr.cell.size_x]
    
    puts "Current IO = $inst"
    puts "Vertical height after R90 = $master_width"

    # Calculate the y placement point
    set cursor_y [expr { $cursor_y - $master_width}]

    # Place instance according to the order of the list
    placeInstance $inst_ptr $io_x $cursor_y $io_orient  

    # Move down cursor with value of space.
    set cursor_y [expr { $cursor_y - $io_spacing} ]

}


#============================================================
# 9. Identify required Analog macro
#============================================================

set macro_vr12      [find_macro_by_keyword $macro_ptrs "vr12"]
set macro_bgr       [find_macro_by_keyword $macro_ptrs "bgr"]
set macro_bg_buffer [find_macro_by_keyword $macro_ptrs "bg_buffer"]
set macro_vde       [find_macro_by_keyword $macro_ptrs "u7_vde"]

#============================================================
# 10. Query width and height
#============================================================

set vr12_ptr [dbget -p -e top.insts.name $macro_vr12]
set bgr_ptr         [dbget -p -e top.insts.name $macro_bgr]
set bg_buffer_ptr   [dbget -p -e top.insts.name $macro_bg_buffer]
set vde_ptr       [dbget -p -e top.insts.name $macro_vde]

set vr12_w          [dbget $vr12_ptr.cell.size_x]
set vr12_h          [dbget $vr12_ptr.cell.size_y]

set bgr_w [dbget $bgr_ptr.cell.size_x]
set bgr_h [dbget $bgr_ptr.cell.size_y]

set bg_buffer_w [dbget $bg_buffer_ptr.cell.size_x]
set bg_buffer_h [dbget $bg_buffer_ptr.cell.size_y]

set vde_w [dbget $vde_ptr.cell.size_x]
set vde_h [dbget $vde_ptr.cell.size_y]

#============================================================
# 11. Chaining the Macros
#============================================================

# Analog placement Parameter
set analog_right_margin 20.0
set analog_top_margin   20.0
set macro_spacing       30.0

# VR12 - upper right anchor
set vr12_x [expr {
    $core_urx - $analog_right_margin - $vr12_w
}]
set vr12_y [expr {
    $core_ury - $analog_top_margin - $vr12_h
}]

# BGR - left of VR12, top aligned
set bgr_x [expr {
    $vr12_x - $macro_spacing - $bgr_w
}]
set bgr_y [expr {
    $core_ury - $analog_right_margin - $bgr_h
}]

# bgr_buffer - below BGR
set bg_buffer_x $bgr_x
set bg_buffer_y [expr {
    $bgr_y - $macro_spacing - $bg_buffer_h
}]

# VDE - below VR12
set vde_x $vr12_x
set vde_y [expr {
    $vr12_y - $macro_spacing - $vde_h
}]

puts "VR12      : ($vr12_x, $vr12_y)"
puts "BGR       : ($bgr_x, $bgr_y)"
puts "BG buffer : ($bg_buffer_x, $bg_buffer_y)"
puts "VDE       : ($vde_x, $vde_y)"

#============================================================
# 12. Analog Macro Placement
#============================================================

placeInstance $macro_vr12 $vr12_x $vr12_y 
placeInstance $macro_bgr $bgr_x $bgr_y MY
placeInstance $macro_bg_buffer $bg_buffer_x $bg_buffer_y MY
placeInstance $macro_vde $vde_x $vde_y 

#============================================================
# 13. Query width and height + calculation of xy
#============================================================

set macro_hosc [find_macro_by_keyword $macro_ptrs "hosc"]
set macro_pori [find_macro_by_keyword $macro_ptrs "pori"]

set hosc_ptr    [dbget top.insts.name $macro_hosc -p]
set pori_ptr    [dbget top.insts.name $macro_pori -p]

set hosc_w [dbget $hosc_ptr.cell.size_x]
set hosc_h [dbget $hosc_ptr.cell.size_y]

# R90
set pori_w [dbget $pori_ptr.cell.size_y]
set pori_h [dbget $pori_ptr.cell.size_x]

# pori - R90, x aligned with bgr and below bg buffer 
set pori_x $bgr_x
set pori_y [expr {
    $bg_buffer_y - $macro_spacing - $pori_h
}]

# hosc - below with VDE, but separate from analog area cause it's noisy
set noise_margin 50

set hosc_x $vde_x
set hosc_y [expr {
    $vde_y - $noise_margin - $hosc_h
}]

puts "PORI : ($pori_x, $pori_y) R90"
puts "HOSC : ($hosc_x, $hosc_y) R0"

#Placement of HOSC and PORI
#============================================================
placeInstance $macro_hosc $hosc_x $hosc_y 
placeInstance $macro_pori $pori_x $pori_y R90

#============================================================
# Digital Macro Identification
#============================================================
set macro_flash [find_macro_by_keyword $macro_ptrs "flash_bist"]
set macro_sram  [find_macro_by_keyword $macro_ptrs "system_sram"]

echo off
#============================================================
# 9. IO report
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
