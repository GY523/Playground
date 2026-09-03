##############################################################################
# set dontTouch & sizeOnly
##############################################################################

#set_dont_Touch $vars(cell,dont_touch) true

##############################################################################
# set dontUse
##############################################################################

#set_dont_use $vars(cell,dont_use) true


##############################################################################
# set ALL
##############################################################################
set PR_VER 1
# density
set place_max_density "75"
set max_density "75"
set maxLocalDensity "75"


# gap
set place_gap "2"


# route layer
set bottom_routeing_layer "2"
set top_routing_layer "5"


# netlength
set max_net_length "800"


#opt target slack
set setup_target "0.00"
set hold_target "0.00"
set drcMargin "0.050"



# uncertainty
set setup_uncertainty_place "0.7"
set hold_uncertainty_place "0.6"

set setup_uncertainty_cts  "0.6"
set hold_uncertainty_cts "0.5"

set setup_uncertainty_route  "0.5"
set hold_uncertainty_route "0.5"

set setup_uncertainty_global  "0.200"
set hold_uncertainty_global "0.110"


# Trans
set max_transition "0.5"
set max_transition_clock "0.5"
set target_max_trans "0.450"

# fanout
set max_fanout "40"
set max_fanout_clock "40"


# cts cells

set vars(cell,clock_invert,lvt) "SVH_INV_S_4 SVH_INV_S_6 SVH_INV_S_8 SVH_INV_S_12 SVH_INV_S_16"
set vars(cell,clock_buffer,lvt) ""
set vars(cell,clock_logic,lvt) ""
set vars(cell,clock_gate,lvt) ""


# tie cell
set Tiecell_maxFanout "1"
set Tiecell_maxDistance "20"
set vars(cell,tie) "SVH_TIE0_1 SVH_TIE1_1"

# ant cell
set vars(cell,ant) ""

# Filler cell
set vars(cell,decap) " " 
set vars(cell,endcap) "SVH_FILL1 SVH_FILL16 SVH_FILL2 SVH_FILL32 SVH_FILL4 SVH_FILL64 SVH_FILL8" 
set vars(cell,fillers) "SVH_FILL1 SVH_FILL16 SVH_FILL2 SVH_FILL32 SVH_FILL4 SVH_FILL64 SVH_FILL8 SVH_FILL_ECO1 SVH_DCAP16 SVH_DCAP32 SVH_DCAP64 SVH_DCAP8 SVH_DCAP4"

# welltap cell
set vars(cell,tap_cell) "SVH_TAP_DS"
set vars(cell,tap_distance) "40"

#============================================================
# Floorplan Settings
#============================================================

#------------------------------------------------------------
# IO placement
#------------------------------------------------------------

set fp(io_orient)          R90
set fp(io_spacing)         0.0
set fp(io_y_ratio)         0.75


#------------------------------------------------------------
# Analog macro placement
#------------------------------------------------------------

set fp(analog_right_margin) 20.0
set fp(analog_top_margin)   20.0
set fp(analog_margin)       20.0

set fp(macro_spacing)       30.0
set fp(noise_margin)        50.0

# Partial Blockage Density
set fp(side_density)    60
set fp(corner_density)  30

# Physical size of blockage regions
# Density blockage demensions are measured from the macro boundary.
# They may overlap the placement halo intentionally.
set fp(side_blockage_width)     20.0
set fp(corner_blockage_size)    20.0

#------------------------------------------------------------
# Digital macro placement
#------------------------------------------------------------

set fp(digital_macro_margin) 20.0

#------------------------------------------------------------
# Macro halos
#------------------------------------------------------------
# Placement keepout around digital macros
set fp(place_halo) 5.0
set fp(route_halo) 5.0

# Routing halo
set fp(route_halo_space)        <TODO>