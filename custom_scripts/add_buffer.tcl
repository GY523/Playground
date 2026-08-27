#--------------------------------------------------------------------
# eco_add_ip_buffers.tcl
# Insert buffers on IP input/output pins.
#
# - Skips manually routed pins/nets
# - Skips unconnected pins
# - Skips special IO pins: IE, PAD, PU
# - Uses CLK BUF for clock nets, BUF size 12 for non-clock
# - Fixes and dont_touch inserted buffer instances and related nets
#--------------------------------------------------------------------

set ip_insts {
    u2_ft001_analog/u2_bgr
    u1_ft001_digital/u07_fls_ctrl/u_flash_bist
}

# Cell names: change these if your library uses different names
set non_clk_buf BUFX12
set clk_buf     CLKBUFX12

set skip_pin_names {IE PAD PU}
set allowed_dirs   {input output}

#--------------------------------------------------------------------
# Helpers
#--------------------------------------------------------------------
proc is_no_net {net} {
    if { $net == "" || $net == "0" || $net == "0x0" || $net == "NULL" } { return 1 }
    if { [catch { set n [dbGet $net.name] } err] } { return 1 }
    if { $n == "" || $n == "NONE" } { return 1 }
    return 0
}

proc is_manual_routed {pin net} {
    foreach attr {| $v == "true" || $v == "Manual" || $v == "manual" } { return 1 }
        }isManualRouted routeStatus} {
        if { ![catch { set v [dbGet ${pin}.${attr}] } err] } {
            if { $v == 1 |
        if { ![catch { set v [dbGet ${net}.${attr}] } err] } {
            if { $v == 1 || $v == "true" || $v == "Manual" || $v == "manual" } { return 1 }
        }
    }
    return 0
}

proc is_clock_net {net} {
    if { ![catch { set c [dbGet ${net}.isClock] } err] } {
        if { $c == 1 || $c == "true" } { return 1 }
    }
    # Fallback name match
    if { ![catch { set n [dbGet $net.name] } err] } {
        if { [regexp -nocase {clk|clock} $n] } { return 1 }
    }
    return 0
}

proc dont_touch_net {net} {
    if { [is_no_net $net] } { return }
    catch { dbSet $net.dontTouch 1 }
    if { ![catch { set n [dbGet $net.name] } err] } {
        catch { setDontTouch -net $n true }
    }
}

#--------------------------------------------------------------------
# Main ECO insertion
#--------------------------------------------------------------------
setEcoMode -batchMode true

foreach inst $ip_insts {
    puts "INFO: Processing instance $inst"

    if { [catch { set inst_obj [dbGet top.insts.name $inst] } err] } {
        puts "WARNING: cannot find instance $inst : $err"
        continue
    }
    if { $inst_obj == "" } {
        puts "WARNING: instance $inst not found"
        continue
    }

    set pins [dbGet $inst_obj.pins]

    foreach pin $pins {
        if { [catch { set pin_name [dbGet $pin.name] } err] } {
            puts "  WARNING: cannot get pin name for $pin : $err"
            continue
        }
        if { [catch { set dir [dbGet $pin.direction] } err] } {
            puts "  WARNING: cannot get direction for pin $pin_name : $err"
            continue
        }

        set dir [string tolower $dir]
        set pin_name_upper [string toupper $pin_name]

        # Only input/output pins
        if { [lsearch -exact $allowed_dirs $dir] < 0 } { continue }

        # Skip special IO pins
        if { [lsearch -exact $skip_pin_names $pin_name_upper] >= 0 } {
            puts "  SKIP pin $pin_name : special IO pin"
            continue
        }

        # Check net connection
        set net [dbGet $pin.net]
        if { [is_no_net $net] } {
            puts "  SKIP pin $pin_name : no net connection"
            continue
        }

        # Skip manually routed pins/nets
        if { [is_manual_routed $pin $net] } {
            puts "  SKIP pin $pin_name : manually routed"
            continue
        }

        # Select buffer cell
        if { [is_clock_net $net] } {
            set buf_cell $clk_buf
        } else {
            set buf_cell $non_clk_buf
        }

        # Buffer location: pin XY, fallback to parent instance origin
        set loc {}
        if { ![catch { set loc [dbGet $pin.xy] } err] } {
            # ok
        }
        if { $loc == "" } {
            if { ![catch { set pin_inst [dbGet $pin.inst] } err] } {
                catch { set loc [dbGet $pin_inst.origin] }
            }
        }

        puts "  Adding buffer $buf_cell at pin $pin_name (net [dbGet $net.name])"

        if { [catch {
            if { $loc == "" } {
                set new_inst [ecoAddRepeater -term $pin -cell $buf_cell]
            } else {
                set new_inst [ecoAddRepeater -term $pin -cell $buf_cell -loc $loc]
            }
        } err] } {
            puts "  ERROR: ecoAddRepeater failed for pin $pin_name : $err"
            continue
        }

        # Resolve new buffer instance object/name
        set new_inst_name [lindex $new_inst 0]
        set new_inst_obj ""
        if { ![catch { set new_inst_obj [dbGet top.insts.name $new_inst_name] } err] } {
            # ok
        }
        if { $new_inst_obj == "" } {
            set new_inst_obj $new_inst_name
        }

        if { $new_inst_obj == "" } {
            puts "  WARNING: could not resolve new buffer instance for pin $pin_name"
            continue
        }

        set new_inst_name [dbGet $new_inst_obj.name]

        # Fix placement
        catch { setInstancePlacementStatus -name $new_inst_name -status fixed }

        # dont_touch instance and nets
        catch { dbSet $new_inst_obj.dontTouch 1 }
        catch { setDontTouch $new_inst_name true }

        dont_touch_net $net

        if { ![catch { set new_buf_pins [dbGet $new_inst_obj.pins] } err] } {
            foreach bp $new_buf_pins {
                set bn [dbGet $bp.net]
                dont_touch_net $bn
            }
        }

        puts "  Inserted buffer $new_inst_name on net [dbGet $net.name] for pin $pin_name"
    }
}

puts "INFO: Done adding IP interface buffers."
setEcoMode -batchMode false

