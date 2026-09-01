# Innovus Floorplanning Tcl Script --- Implementation Plan

## 1. Objective

Develop a Tcl script that automates the **floorplanning / pre-placement
stage** of the `ft001_chipcore` design in Cadence Innovus 20.11.

The script should reproduce the physical-design intent given by the team
lead while remaining maintainable and reasonably parameterized.

The goal is **not** to build a general-purpose automatic floorplanning
optimizer. The first version should implement a deterministic floorplan
based on the known physical considerations, then validate that the
resulting floorplan satisfies those requirements.

------------------------------------------------------------------------

## 2. Current Design Context

### Innovus environment

-   Cadence Innovus: `20.11-s130_1`
-   Tcl version inside Innovus: `8.6.4`
-   Server OS: CentOS 7.9
-   Architecture: x86_64

### Current design

Top design:

``` text
ft001_chipcore
```

Core size:

``` text
978.085 x 975.8
```

Die size:

``` text
1178.085 x 1175.8
```

There are currently 8 block instances:

  ------------------------------------------------------------------------------------------------------------------
  Instance                                       Cell                            Type              Size
  ---------------------------------------------- ------------------------------- ----------------- -----------------
  `u1_ft001_digital/u07_fls_ctrl/u_flash_bist`   `HL55FHEF64KX32GSIA01`          Flash/memory      519 × 974.19

  `u1_ft001_digital/u08_ramctrl/u_system_sram`   `HL55FHHDSP1408x32B1M8W1SA05`   SRAM              374.5 × 143.12

  `u2_ft001_analog/u1_pori`                      `HL55FHPOR12GSA01`              Analog IP         54.79 × 80.83

  `u2_ft001_analog/u2_bgr`                       `HL55FHBGR08GSA01`              Analog IP         108.3 × 125.51

  `u2_ft001_analog/u3_hosc`                      `HL55FHOSC30MRSA01`             Analog IP         115.17 × 50.99

  `u2_ft001_analog/u4_vr12`                      `HL55FHLDO50T12L10mLPA01`       Analog IP / LDO   135 × 190

  `u2_ft001_analog/u5_bg_buffer`                 `HL55FHBGR08GS_BUFFA01`         Analog IP         42.53 × 63.55

  `u2_ft001_analog/u7_vde`                       `HL55FHVD6115GDA01`             Analog IP         97.57 × 92.88
  ------------------------------------------------------------------------------------------------------------------

Original placement status:

-   `u1_pori`: placed
-   Other 7 block instances: unplaced

`u1_pori` was placed manually during experimentation and should not be
treated as an existing floorplanning constraint.

Current orientations:

-   Most macros: `R0`
-   `u1_pori`: `R90`

------------------------------------------------------------------------

# 3. Physical Design Intent

The floorplan is based on physical considerations provided by the team.

## 3.1 Analog macro grouping

The analog IPs should be concentrated in a dedicated corner/region
rather than mixed with the digital standard-cell area.

Important relationships include:

-   LDO (`u4_vr12`) should be close to BGR (`u2_bgr`).
-   VDE (`u7_vde`) should be near the LDO/analog group.
-   BGR buffer (`u5_bg_buffer`) should be associated with BGR.
-   HOSC (`u3_hosc`) belongs to the analog group but should respect
    noise/isolation considerations.
-   POR (`u1_pori`) should use the required `R90` orientation and should
    be sufficiently separated from noise-sensitive regions/sources.

The reference arrangement shows the analog IP group concentrated toward
the upper/right side of the core.

Do not invent exact coordinates from the screenshot. Determine
coordinates from the actual core geometry and the intended relative
arrangement.

------------------------------------------------------------------------

## 3.2 Digital macro placement

The two large digital memories are:

-   Flash BIST: `u_flash_bist`
-   System SRAM: `u_system_sram`

Their placement should be considered after defining the analog region.

Important considerations:

-   Avoid the protected analog region.
-   Keep macros inside the legal core/die region.
-   Avoid overlap.
-   Leave sufficient routing/placement space around large memories.
-   Consider connectivity if available from the design/netlist.

Do not optimize purely for minimum area. Routing access and interaction
with the analog region are more important for this first implementation.

------------------------------------------------------------------------

## 3.3 IO placement

The IOs are intended toward the **right side** of the design.

The provided physical guidance specifies an order for the relevant IOs:

``` text
Vdd → Vcc → Vss → scirst → sciclk → sciio
```

with an additional VSS below for ESD protection.

For the first implementation:

1.  Identify the relevant IO instances/terms.
2.  Determine their current locations and orientations.
3.  Place them on the right side.
4.  Preserve the required ordering.
5.  Validate that the order is correct.

Do not assume exact coordinates until they are obtained from the
design/reference.

------------------------------------------------------------------------

# 4. Placement Blockage Strategy

Placement blockages are part of the floorplanning strategy.

There are two concepts to implement.

## 4.1 Analog-region placement blockage

Create a placement-protected region around the analog IP group.

Purpose:

-   Prevent ordinary standard-cell placement from filling the analog
    region.
-   Preserve routing/isolation space.
-   Keep the analog area physically separated from digital logic.

The exact dimensions should be derived from the actual analog macro
arrangement and the team's expected margin.

------------------------------------------------------------------------

## 4.2 Macro density blockages

The team lead's recommended heuristic is:

-   **60% placement density on macro sides**
-   **30% placement density at macro corners**

These are placement-density guidelines, not hard technology
requirements.

Treat them as configurable parameters.

Example configuration:

``` tcl
set fp(analog_side_density)   60
set fp(analog_corner_density) 30
```

Do not interpret "60%" or "30%" as the physical width of a blockage.

The script must distinguish:

-   blockage geometry
-   blockage density

The physical width/extent of the side and corner regions should be
configurable and determined during implementation/testing.

------------------------------------------------------------------------

# 5. Script Architecture

The floorplanning code should be organized into logical sections.

Recommended structure:

``` text
prePlace.tcl
│
├── 1. Initialization / restore design
│
├── 2. Load floorplan parameters
│
├── 3. Query core/die geometry
│
├── 4. Identify required macro instances
│
├── 5. Calculate placement regions
│
├── 6. Place analog macros
│
├── 7. Place digital memories
│
├── 8. Create analog placement blockage
│
├── 9. Create macro density blockages
│
├── 10. Place / organize IOs
│
├── 11. Validate floorplan
│
└── 12. Save design
```

Keep each section independent enough that it can be tested separately.

------------------------------------------------------------------------

# 6. Phase 1 --- Parameterization

Extend the existing `scr/user_scr/pr_setting.tcl` rather than scattering
physical parameters throughout `prePlace.tcl`.

Possible parameters:

``` tcl
# Floorplan parameters
set fp(analog_side_density)   60
set fp(analog_corner_density) 30

# Margins / spacing
set fp(analog_margin)         <value>
set fp(macro_margin)          <value>
set fp(noise_margin)          <value>

# Required orientations
set fp(pori_orient)           R90

# IO side
set fp(io_side)               right
```

Do not choose arbitrary final values for parameters whose physical
meaning has not yet been established.

Use temporary experimental values while developing.

------------------------------------------------------------------------

# 7. Phase 2 --- Query Floorplan Geometry

Do not hard-code the core dimensions.

Obtain them from Innovus.

Conceptually:

``` tcl
set core_box [dbGet top.fplan.coreBox]
set die_box  [dbGet top.fplan.box]
```

Extract:

``` text
core_llx
core_lly
core_urx
core_ury
```

and derive:

``` text
core_width
core_height
```

Use these values to calculate macro positions.

This makes the script less dependent on the current floorplan
dimensions.

------------------------------------------------------------------------

# 8. Phase 3 --- Identify Macros Reliably

Avoid relying only on an arbitrary instance order.

Use hierarchical instance names or other stable database properties.

Create variables for the important macros:

``` tcl
set flash_bist ...
set system_sram ...
set pori ...
set bgr ...
set hosc ...
set ldo ...
set bg_buffer ...
set vde ...
```

Before placement, validate that every expected macro exists.

Example logic:

``` text
IF macro exists
    continue
ELSE
    print ERROR
    exit
```

This prevents a silent failure caused by a renamed or missing instance.

------------------------------------------------------------------------

# 9. Phase 4 --- Define the Analog Placement Region

Determine the analog corner/region from the physical intent.

The region should have enough space for:

``` text
LDO
BGR
BG buffer
VDE
HOSC
```

while respecting:

-   relative proximity
-   noise isolation
-   macro dimensions
-   spacing
-   core boundaries

Calculate the region rather than hard-coding a collection of unrelated
coordinates.

The region can conceptually be represented as:

``` text
+--------------------------------------+
|              ANALOG REGION           |
|                                      |
|             LDO                      |
|                                      |
|       HOSC       BGR   VDE            |
|                    BG_BUF             |
|                                      |
+--------------------------------------+
```

The exact arrangement should follow the team's reference floorplan.

------------------------------------------------------------------------

# 10. Phase 5 --- Place Analog Macros

Place the analog macros in a deliberate order.

Recommended dependency order:

``` text
1. LDO
2. BGR
3. BG buffer
4. VDE
5. HOSC
6. POR
```

The reason is that LDO/BGR form an important physical relationship, and
the other analog blocks can then be positioned relative to them.

For each placement:

1.  Determine required orientation.
2.  Determine legal coordinate.
3.  Check core boundary.
4.  Check overlap.
5.  Place the macro.
6.  Verify the resulting location.

Avoid beginning with absolute coordinates copied from the screenshot.

Instead, calculate locations using:

``` text
reference macro position
+
macro dimensions
+
required spacing
```

For example:

``` text
BGR_X = LDO_X + LDO_WIDTH + spacing
```

This is preferable to:

``` tcl
placeInstance BGR 812.5 823.2 R0
```

------------------------------------------------------------------------

# 11. Phase 6 --- Place Digital Memories

After establishing the analog region:

1.  Place Flash BIST.
2.  Place SRAM.
3.  Keep both outside protected analog areas.
4.  Check overlap and core boundaries.
5.  Consider routing access.

Because Flash BIST is approximately:

``` text
519 × 974.19
```

it is extremely tall relative to the approximately `975.8`-unit core
height.

Therefore, pay special attention to:

-   orientation
-   whether it fits within the intended core boundary
-   interaction with the core boundary
-   available routing space

Do not assume `R0` is necessarily the final orientation. Verify the
legal/desired orientation using the technology/design constraints.

------------------------------------------------------------------------

# 12. Phase 7 --- Create Analog Placement Blockage

After macro placement, derive the analog blockage from the actual analog
region.

The blockage should protect the analog area rather than simply surround
each macro independently.

Recommended conceptual flow:

``` text
Place analog macros
       ↓
Determine analog bounding region
       ↓
Add required margin
       ↓
Create placement blockage
       ↓
Verify blockage covers intended area
```

This avoids hard-coded blockage coordinates becoming inconsistent when
macro positions change.

------------------------------------------------------------------------

# 13. Phase 8 --- Create Side/Corner Density Blockages

Implement the team lead's heuristic using configurable density values:

``` text
side   = 60%
corner = 30%
```

Conceptually:

``` text
                 corner
              30% density
          ┌─────────────────┐
          │░░░░░░░░░░░░░░░░░│
          │░░             ░░│
          │60%             ░░│
          │side   MACRO    ░░│
          │60%             ░░│
          │░░             ░░│
          │░░░░░░░░░░░░░░░░░│
          └─────────────────┘
              corner
            30% density
```

Implement this only after confirming the appropriate Innovus
placement-blockage command and geometry semantics in Innovus 20.11.

Do not blindly copy commands from newer Innovus documentation.

------------------------------------------------------------------------

# 14. Phase 9 --- IO Placement

Once the IO requirements are fully understood:

1.  Find relevant IO terms/instances.
2.  Determine their dimensions.
3.  Place them on the right side.
4.  Apply the required ordering.
5.  Set orientation as necessary.
6.  Verify that they remain inside the legal die/IO region.

Keep IO placement separate from macro placement so it can be modified
without affecting the macro algorithm.

------------------------------------------------------------------------

# 15. Phase 10 --- Floorplan Validation

This should be a first-class part of the script.

At minimum, validate:

## Macro checks

``` text
[ ] All 8 expected macros exist
[ ] All 8 macros are placed
[ ] No macro overlap
[ ] All macros are within legal boundaries
[ ] Required orientations are correct
```

## Analog checks

``` text
[ ] Analog macros are inside the intended analog region
[ ] LDO and BGR satisfy proximity requirement
[ ] VDE satisfies proximity requirement
[ ] BG buffer is appropriately positioned relative to BGR
[ ] POR has required orientation
[ ] Required isolation/margins exist
```

## Blockage checks

``` text
[ ] Analog placement blockage exists
[ ] Blockage covers intended analog region
[ ] Side density blockage exists
[ ] Corner density blockage exists
```

## IO checks

``` text
[ ] IOs are on the right side
[ ] IO order is correct
[ ] Required ESD-related VSS is present
```

Use clear PASS/FAIL messages.

------------------------------------------------------------------------

# 16. Phase 11 --- Save the Floorplan Checkpoint

Once validation passes:

``` tcl
saveDesign -tcon ../DB/${design_name}_${curr_stage}_${PR_VER}.enc
```

The floorplanning stage should produce a checkpoint that the subsequent
placement stage can restore.

The existing flow already follows this staged checkpoint methodology:

``` text
init
 ↓
prePlace
 ↓
place
 ↓
CTS
 ↓
route
```

Do not redesign this flow unless necessary.

------------------------------------------------------------------------

# 17. Development Strategy

Do not write the complete script in one attempt.

Use incremental development.

## Version 0 --- Query only

Write a script that prints:

``` text
core box
die box
macro names
macro sizes
macro locations
macro orientations
placement status
```

No placement changes.

Goal: confirm database queries.

------------------------------------------------------------------------

## Version 1 --- Manual deterministic placement

Place all 8 macros using calculated coordinates.

Goal:

``` text
Correct relative arrangement
No overlap
Legal boundaries
Correct orientations
```

Do not add sophisticated blockages yet.

------------------------------------------------------------------------

## Version 2 --- Parameterize coordinates

Replace fixed coordinates with calculations based on:

``` text
core geometry
macro dimensions
spacing
relative placement
```

Goal: make the floorplan maintainable.

------------------------------------------------------------------------

## Version 3 --- Add analog blockage

Create the dedicated analog placement blockage.

Goal:

``` text
Protect analog region from standard-cell placement.
```

------------------------------------------------------------------------

## Version 4 --- Add 60% / 30% density blockages

Implement the team lead's placement-density heuristic.

Goal:

``` text
Macro sides   → 60%
Macro corners → 30%
```

Keep these values configurable.

------------------------------------------------------------------------

## Version 5 --- Add IO placement

Automate right-side IO placement and ordering.

------------------------------------------------------------------------

## Version 6 --- Add validation

Turn the script into a self-checking floorplanning stage.

------------------------------------------------------------------------

## Version 7 --- Integrate with the flow

Run:

``` text
flow.tcl
    ↓
init.tcl
    ↓
prePlace.tcl
    ↓
place.tcl
```

Confirm that the generated checkpoint can be consumed by the existing
`place.tcl`.

------------------------------------------------------------------------

# 18. DEF vs Tcl During Development

Use both, but for different purposes.

## DEF

Use DEF as an **exploration/debugging tool**.

For example:

``` text
DEF OUT
    ↓
modify placement
    ↓
DEF IN
    ↓
inspect Innovus
```

This is useful for quickly testing physical ideas.

## Tcl

Use Tcl as the **final automation mechanism**.

The final flow should be:

``` text
Clean initial database
        ↓
Tcl floorplanning script
        ↓
Deterministic floorplan
        ↓
Validation
        ↓
saveDesign
```

Do not make the final solution dependent on manually editing a DEF file.

------------------------------------------------------------------------

# 19. Recommended File Organization

Use the existing project structure.

``` text
INNOVUS_ft001_chipcore/
│
├── scr/
│   ├── init.tcl
│   ├── prePlace.tcl          ← main floorplanning implementation
│   ├── place.tcl
│   ├── cts.tcl
│   ├── route.tcl
│   │
│   └── user_scr/
│       ├── setup.tcl
│       ├── pr_setting.tcl    ← floorplan parameters
│       └── ...
│
├── DB/
├── data/
├── rpts/
└── output/
```

If the floorplanning logic becomes large, consider splitting it into
helper procedures later:

``` text
scr/common/floorplan_proc.tcl
```

For the first version, however, keeping the logic in `prePlace.tcl` is
easier to debug.

------------------------------------------------------------------------

# 20. Important Engineering Principles

### Principle 1 --- Physical intent first

Do not begin with Tcl syntax.

Start with:

``` text
What physical requirement am I implementing?
```

Then determine the Innovus command.

------------------------------------------------------------------------

### Principle 2 --- Avoid magic numbers

Prefer:

``` tcl
set x [expr {$ldo_x + $ldo_width + $spacing}]
```

over:

``` tcl
set x 653.27
```

------------------------------------------------------------------------

### Principle 3 --- Separate configuration from implementation

Put adjustable values in:

``` text
user_scr/pr_setting.tcl
```

and implementation logic in:

``` text
prePlace.tcl
```

------------------------------------------------------------------------

### Principle 4 --- Validate assumptions

Whenever the script assumes something about the database, query it.

For example:

``` text
Does this macro exist?
What is its size?
Is it already placed?
What is its orientation?
```

------------------------------------------------------------------------

### Principle 5 --- Make failure obvious

Prefer:

``` text
ERROR: u2_bgr was not found.
```

over silently continuing with an invalid floorplan.

------------------------------------------------------------------------

### Principle 6 --- Do not over-engineer Version 1

The first objective is:

> Automatically generate the intended floorplan reliably.

Optimization can come later.

------------------------------------------------------------------------

# 21. Suggested Final Deliverable

The completed floorplanning stage should ideally provide:

``` text
prePlace.tcl
    │
    ├── deterministic macro placement
    ├── analog region protection
    ├── macro density blockages
    ├── IO placement
    ├── physical validation
    └── checkpoint generation
```

and produce a result that can be inspected in Innovus GUI.

The final script should be understandable enough that another engineer
can change:

``` text
macro spacing
analog margin
blockage density
IO side/order
orientation
```

without rewriting the placement algorithm.

------------------------------------------------------------------------

# 22. Questions to Resolve During Implementation

Before fixing final coordinates, obtain/confirm:

1.  Exact intended analog macro order/relative arrangement.
2.  Required minimum spacing between the analog IPs.
3.  Required isolation distance around noise-sensitive IPs.
4.  Exact meaning/extent of the 60% side blockage regions.
5.  Exact meaning/extent of the 30% corner blockage regions.
6.  Required orientation of each macro.
7.  Whether Flash BIST should remain `R0` or use another legal
    orientation.
8.  Exact IO instance/term names and required ordering.
9.  Whether there are additional power/ground or routing restrictions
    around analog IPs.
10. Whether there are minimum macro-to-core-edge distances specified by
    the team.

Do not invent these values if they are not known. Use the team's
physical-design guidance or verify them with the team lead.

------------------------------------------------------------------------

# 23. Success Criteria

The implementation is complete when:

``` text
[✓] Script runs from the clean initial Innovus database
[✓] All required macros are identified automatically
[✓] Analog macros are placed according to physical intent
[✓] Digital memories are placed without conflicting with the analog region
[✓] Required orientations are applied
[✓] Analog placement blockage is created
[✓] 60% / 30% density blockage strategy is implemented
[✓] IOs are placed according to the required side/order
[✓] Floorplan validation reports PASS
[✓] prePlace checkpoint is saved
[✓] Existing place.tcl can restore/use the checkpoint
```

------------------------------------------------------------------------

# 24. Recommended Immediate Next Step

Do **not** start by implementing the blockage.

Start with **Version 0**:

``` text
Query:
    core/die geometry
    macro name
    macro size
    macro location
    macro orientation
    placement status
```

Then write Version 1 to place the eight macros.

Once the macro placement is visually correct in Innovus, add the
blockages.

This gives you a controlled progression:

``` text
Database queries
       ↓
Macro placement
       ↓
Parameterization
       ↓
Analog blockage
       ↓
60/30% density blockage
       ↓
IO placement
       ↓
Validation
       ↓
Flow integration
```

This is the recommended implementation path for the current OJT
assignment.
