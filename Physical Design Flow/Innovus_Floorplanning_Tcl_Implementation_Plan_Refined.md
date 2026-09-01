# Innovus Floorplanning Tcl Script — Refined Implementation Plan

## 1. Objective

Develop a Tcl-based floorplanning stage for `ft001_chipcore` in Cadence Innovus 20.11 that converts the provided physical-design guidance into a reproducible, deterministic implementation.

The final solution should use **native Innovus Tcl** as the automation mechanism. DEF export/import may still be used for experimentation and comparison, but the production flow should not depend on manually editing DEF.

The floorplanning stage should automate:

```text
IO placement
    ↓
Macro placement
    ↓
Analog-region protection
    ↓
Macro-density blockages
    ↓
Floorplan validation
    ↓
saveDesign
```

## 2. Current Environment

- Innovus: `20.11-s130_1`
- Tcl patchlevel inside Innovus: `8.6.4`
- Server OS: CentOS 7.9
- Existing flow: `init.tcl → prePlace.tcl → place.tcl → cts.tcl → route.tcl`

`prePlace.tcl` is the correct integration point for floorplanning. Add a dedicated:

```text
scr/floorplan.tcl
```

and source it from `prePlace.tcl` before endcap/welltap insertion and PG connection.

## 3. Floorplan Geometry

### Die

```text
LL = (0.000, 0.000)
UR = (1178.085, 1175.800)
Size = 1178.085 × 1175.800 µm
```

### Core

```text
LL = (100.000, 100.000)
UR = (1078.085, 1075.800)
Size = 978.085 × 975.800 µm
```

The final Tcl should query the core/die boxes from Innovus instead of hard-coding them whenever possible.

## 4. Components

### IO-related instances

```text
u2_ft001_analog/u_vdd_tp
u2_ft001_analog/u_vcc
u2_ft001_analog/u_vss
u2_ft001_analog/u_scirst
u2_ft001_analog/u_sciclk
u2_ft001_analog/u_sciio
```

Their current DEF locations are default/import placements and are **not** the intended final floorplan.

### Hard macros

```text
u1_ft001_digital/u07_fls_ctrl/u_flash_bist
u1_ft001_digital/u08_ramctrl/u_system_sram
u2_ft001_analog/u1_pori
u2_ft001_analog/u2_bgr
u2_ft001_analog/u3_hosc
u2_ft001_analog/u4_vr12
u2_ft001_analog/u5_bg_buffer
u2_ft001_analog/u7_vde
```

Treat the init database as essentially un-floorplanned. PORI is currently placed only because of earlier experimentation.

## 5. Physical Design Intent

### Analog group

The analog IPs should occupy a protected corner/region, currently interpreted as the upper-right area of the core.

Important relationships:

```text
LDO / VR12 ↔ BGR
BGR ↔ BG buffer
VDE near LDO/BGR
HOSC in analog area, but with noise/isolation awareness
PORI rotated R90 and kept away from noisy sources
```

Do not treat analog placement as generic packing. Encode the physical intent explicitly.

### Digital macros

Place Flash BIST and SRAM after reserving the analog region and IO corridor.

The Flash macro is approximately `519 × 974.19 µm`, almost the full core height, so orientation, routing access, and available channels must be checked carefully.

## 6. IO Placement — Latest Requirement

IO placement is part of the floorplanning script.

The training slide specifies:

- place IOs on the **right side**;
- place them adjacently;
- preserve the required order.

Required order:

```text
Vdd
↓
Vcc
↓
Vss
↓
scirst
↓
sciclk
↓
sciio
```

An additional VSS may be required below for ESD protection if such an instance exists or must be added according to the lab requirements.

Implementation tasks:

1. Identify all six IO instances.
2. Query their dimensions.
3. Determine legal right-side coordinates.
4. Place them adjacently in the required order.
5. Apply legal/correct orientations.
6. Fix placement if appropriate.
7. Validate right-side placement and order.

Do **not** copy the current DEF locations.

## 7. Placement Blockage Strategy

Two blockage concepts are required.

### 7.1 Analog-region blockage

After analog placement:

```text
query analog macro bboxes
    ↓
compute combined analog bounding region
    ↓
expand by configurable margin
    ↓
create analog placement blockage
```

Purpose:

- keep digital standard cells out of the sensitive analog area;
- preserve routing/isolation space;
- prevent the placer from filling gaps between analog macros.

### 7.2 Macro-density blockages

Team-lead heuristic:

```text
macro side regions   → 60% placement density
macro corner regions → 30% placement density
```

These percentages are density values, not physical widths.

Keep geometry and density as separate configuration parameters, e.g.:

```tcl
set fp(side_density)          60
set fp(corner_density)        30
set fp(side_blockage_width)   <value>
set fp(corner_blockage_size)  <value>
```

Start with one macro, verify visually, then generalize into a reusable procedure.

## 8. Configuration Strategy

Store tunable floorplanning values in:

```text
scr/user_scr/pr_setting.tcl
```

Suggested additions:

```tcl
set fp(side_density)          60
set fp(corner_density)        30

set fp(analog_margin)         <value>
set fp(macro_spacing)         <value>
set fp(noise_margin)          <value>

set fp(side_blockage_width)   <value>
set fp(corner_blockage_size)  <value>

set fp(pori_orient)           R90
set fp(io_side)               right
```

Unknown values should stay explicit as TODO/configuration items rather than hidden as arbitrary constants.

## 9. Tcl Programming Style

For this Lab 2 design, prefer:

- procedures;
- lists/dicts/arrays;
- Innovus database queries.

Do **not** use TclOO for the first implementation. Innovus Tcl 8.6.4 supports TclOO, but OOP adds unnecessary complexity for 8 macros and 6 IO components.

Recommended procedures:

```tcl
proc check_instance_exists {inst} {...}
proc place_io {inst x y orient} {...}
proc place_macro {inst x y orient} {...}
proc check_macro_placement {inst} {...}
```

## 10. Recommended `floorplan.tcl` Structure

```text
floorplan.tcl
│
├── 1. Setup/banner
├── 2. Query die/core geometry
├── 3. Validate IO + macro instances
├── 4. Query component dimensions
├── 5. Define placement regions
├── 6. Place IOs
├── 7. Place analog macros
├── 8. Place digital macros
├── 9. Create analog-region blockage
├── 10. Create 60% side-density blockages
├── 11. Create 30% corner-density blockages
├── 12. Run floorplan checks
├── 13. Print validation summary
└── 14. Return to prePlace.tcl
```

`prePlace.tcl` remains responsible for:

```text
restore init DB
source floorplan.tcl
add endcaps
add well taps
PG connection
saveDesign
exit
```

## 11. Development Phases

### Version 0 — Query only

No placement changes.

Print:

```text
die/core box
instance name
base cell
bbox
location
orientation
place status
```

Goal: verify database access and names.

### Version 1 — IO placement

Implement only the right-side IO arrangement.

Goal:

```text
all six IOs on right
correct order
correct orientation
adjacent/legal placement
```

Verify in GUI before continuing.

### Version 2 — Analog macro placement

Place in dependency order:

```text
1. LDO / VR12
2. BGR
3. BG buffer
4. VDE
5. HOSC
6. PORI
```

Use coordinate relationships such as:

```text
reference macro coordinate
+ macro dimension
+ spacing parameter
```

rather than unrelated hard-coded coordinates.

### Version 3 — Digital macro placement

Place Flash and SRAM after reserving:

```text
right-side IO corridor
+
upper-right analog region
```

Check:

- legal boundary;
- no overlap;
- routing access;
- orientation;
- usable standard-cell area.

### Version 4 — Parameterize placement

Replace arbitrary absolute values with core/macro-geometry-derived calculations.

### Version 5 — Analog-region blockage

Compute protected region from analog macro bboxes plus margin.

### Version 6 — 60% / 30% macro density blockages

Generate side/corner regions around selected macros.

### Version 7 — Validation

Add PASS/FAIL checks.

### Version 8 — Flow integration

Source from `prePlace.tcl` and verify that `place.tcl` can continue from the resulting checkpoint.

## 12. Validation Requirements

### IO checks

```text
[ ] all expected IO instances exist
[ ] all IOs placed
[ ] all are on the right side
[ ] required order is correct
[ ] orientations are correct/legal
```

### Macro checks

```text
[ ] all 8 hard macros exist
[ ] all 8 hard macros placed
[ ] no macro overlap
[ ] all macros within legal boundaries
[ ] PORI orientation = R90
```

### Analog checks

```text
[ ] analog macros inside intended analog region
[ ] LDO/BGR proximity satisfied
[ ] VDE proximity satisfied
[ ] BG buffer near BGR
[ ] required HOSC/PORI isolation preserved
```

### Blockage checks

```text
[ ] analog-region blockage exists
[ ] 60% side-density regions exist
[ ] 30% corner-density regions exist
```

## 13. DEF Usage

Use DEF for:

- quick experiments;
- manual floorplan exploration;
- comparison/reference;
- debugging.

Do not make the final automation:

```text
DEF OUT → manually edit → DEF IN
```

Final flow should be:

```text
init DB
→ floorplan.tcl
→ IO placement
→ macro placement
→ blockages
→ checks
→ saveDesign
```

## 14. Recommended File Organization

```text
INNOVUS_ft001_chipcore/
│
├── scr/
│   ├── flow.tcl
│   ├── init.tcl
│   ├── prePlace.tcl
│   ├── floorplan.tcl
│   ├── place.tcl
│   ├── cts.tcl
│   ├── route.tcl
│   │
│   ├── common/
│   │   └── ...
│   │
│   └── user_scr/
│       ├── setup.tcl
│       ├── pr_setting.tcl
│       └── ...
│
├── DB/
├── data/
├── rpts/
└── output/
```

Only split helper procedures into `scr/common/floorplan_proc.tcl` after `floorplan.tcl` becomes large enough to justify it.

## 15. Questions Still to Resolve During Coding

1. Exact right-side IO spacing.
2. Exact legal orientation for each IO cell.
3. Whether an additional VSS instance for ESD already exists or must be instantiated.
4. Required LDO↔BGR spacing.
5. Required VDE↔LDO/BGR spacing.
6. Required HOSC isolation.
7. Required PORI isolation.
8. Final Flash orientation.
9. Physical width of 60% side-density regions.
10. Physical size of 30% corner-density regions.
11. Whether the density blockage heuristic applies to every macro or only selected macros.
12. Whether routing blockages are also required around specific analog IPs.

## 16. Engineering Principles

- **Physical intent first:** state what requirement each Tcl section implements.
- **Avoid magic numbers:** derive coordinates from geometry where possible.
- **Separate configuration from implementation:** tuning values in `pr_setting.tcl`, algorithm in `floorplan.tcl`.
- **Validate assumptions:** check objects before using them.
- **Fail clearly:** missing critical macros/IOs should generate explicit errors.
- **Keep Version 1 deterministic:** do not attempt automatic optimization yet.

## 17. Final Success Criteria

```text
[✓] Starts from clean init checkpoint
[✓] Queries die/core geometry
[✓] Finds all 6 required IO instances
[✓] Places IOs on right side in required order
[✓] Finds all 8 hard macros
[✓] Places analog macros according to physical intent
[✓] PORI uses R90
[✓] Places Flash and SRAM legally
[✓] No macro overlap
[✓] Creates protected analog region
[✓] Implements 60% side-density blockage policy
[✓] Implements 30% corner-density blockage policy
[✓] Reports floorplan validation
[✓] Saves prePlace checkpoint
[✓] Existing place.tcl can continue
```

## 18. Immediate Work Order

Proceed in this order:

```text
1. Build query-only Tcl
        ↓
2. Implement right-side IO placement
        ↓
3. Verify IO result in GUI
        ↓
4. Place LDO/BGR/BG-buffer/VDE
        ↓
5. Add HOSC and PORI
        ↓
6. Verify analog arrangement
        ↓
7. Place Flash and SRAM
        ↓
8. Verify complete floorplan
        ↓
9. Parameterize coordinates
        ↓
10. Add analog-region blockage
        ↓
11. Add 60% / 30% density blockages
        ↓
12. Add validation
        ↓
13. Integrate with prePlace.tcl
```

This is the current recommended implementation path for the Lab 2 floorplanning assignment.
