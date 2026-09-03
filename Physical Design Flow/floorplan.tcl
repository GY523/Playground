#============================================================
# floorplan.tcl
# Version 4 - Parameterized Placement
#
#============================================================

#============================================================
# 1. Banner
#============================================================

puts ""
puts "============================================================"
puts " FLOORPLAN Version 4 - Parameterized Placement"
puts "============================================================"

#============================================================
# 2. Load configs
#============================================================
set floorplan_script_dir [file dirname [file normalize [info script]]]
source [file join $floorplan_script_dir user_scr pr_setting.tcl]
puts "IO spacing       : $fp(io_spacing)"
puts "Macro spacing    : $fp(macro_spacing)"
puts "Noise margin     : $fp(noise_margin)"
puts "Analog top margin: $fp(analog_top_margin)"

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
# 4. Disco ver Physical Objects
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
        error "MACRO ERROR : no pad isntance matched keyword: $keyword"
    }

    if {[llength $matches] > 1} {
        error "MACRO ERROR: Multiple PAD instances matched keyword '$keyword': $matches"
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

proc get_combined_bbox {inst_list} {
    set first 1
    foreach inst $inst_list {
        set ptr [dbget -p -e top.insts.name $inst ]
        set bbox [dbget $ptr.box]

        lassign [lindex $bbox 0] llx lly urx ury 

        if {$first} {
            set min_x $llx
            set min_y $lly 
            set max_x $urx
            set max_y $ury
            set first 0
        } else {
            if {$min_x > $llx} {set min_x $llx}
            if {$min_y > $lly} {set min_y $lly}
            if {$max_x < $urx} {set max_x $urx}
            if {$max_y < $ury} {set max_y $ury}
        }
    }
    return [list $min_x $min_y $max_x $max_y]
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
    placeInstance $inst_ptr $io_x $cursor_y $fp(io_orient)

    # Move down cursor with value of space.
    set cursor_y [expr { $cursor_y - $fp(io_spacing) } ]

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

# Analog placement Parameter at pr_settings.tcl

# VR12 - upper right anchor
set vr12_x [expr {
    $core_urx - $fp(analog_right_margin) - $vr12_w
}]
set vr12_y [expr {
    $core_ury - $fp(analog_top_margin) - $vr12_h
}]

# BGR - left of VR12, top aligned
set bgr_x [expr {
    $vr12_x - $fp(macro_spacing) - $bgr_w
}]
set bgr_y [expr {
    $core_ury - $fp(analog_top_margin) - $bgr_h
}]

# bgr_buffer - below BGR
set bg_buffer_x $bgr_x
set bg_buffer_y [expr {
    $bgr_y - $fp(macro_spacing) - $bg_buffer_h
}]

# VDE - below VR12
set vde_x $vr12_x
set vde_y [expr {
    $vr12_y - $fp(macro_spacing) - $vde_h
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
    $bg_buffer_y - $fp(macro_spacing) - $pori_h
}]

# hosc - below with VDE, but separate from analog area cause it's noisy
set hosc_x $vde_x
set hosc_y [expr {
    $vde_y - $fp(noise_margin) - $hosc_h
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

#get pointer from name
set flash_ptr [dbget top.insts.name $macro_flash -p]
set sram_ptr [dbget top.insts.name $macro_sram -p]

# get width and height: no rotation
set flash_w [dbget $flash_ptr.cell.size_x]
set flash_h [dbget $flash_ptr.cell.size_y]
# R270
set sram_w  [dbget $sram_ptr.cell.size_y]
set sram_h  [dbget $sram_ptr.cell.size_x]

# set xy
set flash_x $core_llx
set flash_y [expr {
    $core_ury - $flash_h
}]

set sram_x [expr {
    $core_urx - $fp(digital_macro_margin) - $sram_w
}]
set sram_y [expr {
    $core_lly + $fp(digital_macro_margin)
}]
puts "Flash : ($flash_x, $flash_y) R0"
puts "SRAM  : ($sram_x, $sram_y) R270"

placeInstance $macro_flash $flash_x $flash_y 
placeInstance $macro_sram  $sram_x $sram_y R270

#============================================================
# BLOCKAGE PLACEMENT: Identify analog macros
#============================================================

set analog_macro_insts [list \
    $macro_vr12 \
    $macro_bgr \
    $macro_bg_buffer\
    $macro_vde \
    $macro_hosc \
    $macro_pori
]

foreach inst $analog_macro_insts {
    set ptr [dbget -p -e top.insts.name $inst]
    set bbox [dbget $ptr.box]

    puts "$inst -> $bbox"
}

set analog_bbox [get_combined_bbox $analog_macro_insts]

lassign $analog_bbox analog_llx analog_lly analog_urx analog_ury

set blockage_llx [expr {
    $analog_llx - $fp(analog_margin)
}]
set blockage_lly [expr {
    $analog_lly - $fp(analog_margin)
}]
set blockage_urx [expr {
    $analog_urx + $fp(analog_margin)
}]
set blockage_ury [expr {
    $analog_ury + $fp(analog_margin)
}]

if {$blockage_llx < $core_llx } {set blockage_llx $core_llx}
if {$blockage_lly < $core_lly } {set blockage_lly $core_lly}
if {$blockage_urx > $core_urx} {set blockage_urx $core_urx}
if {$blockage_ury > $core_ury} {set blockage_ury $core_ury}

puts ""
puts "============================================"
puts " ANALOG REGION"
puts "============================================"

puts "Combined analog bbox : $analog_bbox"

puts "Protected region     : $blockage_llx $blockage_lly $blockage_urx $blockage_ury"

createPlaceBlockage -name ANALOG_REGION_BLOCKAGE -type hard -box [list $blockage_llx $blockage_lly $blockage_urx $blockage_ury]

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
