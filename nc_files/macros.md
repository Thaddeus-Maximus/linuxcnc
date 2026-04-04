# Macros & Subroutines

Custom M-codes and G-code subroutines for the Lagun mill LinuxCNC configuration.

## Mode Flags (Bitmask)

Several macros (`pocket_circ`, `pocket_rect`, `frame_rect`, `frame_circ`, `slot`) accept a `mode` parameter as a bitmask:

| Bit | Value | Set (1) | Clear (0) |
|-----|-------|---------|-----------|
| 0 | +1 | Conventional milling | Climb milling |
| 1 | +2 | Both-ways milling | One-way milling |
| 2 | +4 | Plunge entry | Helix entry |
| 3 | +8 | Outside | Inside |

Default mode (0) = climb, one-way, helix entry, inside.

## Global Named Parameters

These optional globals configure macro behavior when set before calling:

| Parameter | Description | Default |
|-----------|-------------|---------|
| `#<_td>` | Tool diameter (from tool table) | **Required** - used by all material-removal macros |
| `#<_z_clearance>` | Safe Z retract height | Falls back to ztop param |
| `#<_rampang>` | Ramp/helix entry angle in degrees | 5.0 |
| `#<_stepover>` | Stepover distance for spiral pocketing | 40% of tool diameter |

A negative `fincut` value causes macros to rough only, leaving material for a separate finishing pass.

## M-Codes (Shell Scripts)

### M101 - Enable Z-Axis
Sets HAL signal `z-override` to True, enabling CNC control of Z.

### M102 - Disable Z-Axis
Sets HAL signal `z-override` to False, allowing manual quill control.

## Drilling Subroutines

### drill.ngc - Peck Drill
Fully automatic drilling with optional peck cycle.

```
o<drill> call [x][y] [ztop][zbot] [peck]
```

| # | Name | Description |
|---|------|-------------|
| #1 | X | Hole X position |
| #2 | Y | Hole Y position |
| #3 | Z Start | Top of material / start Z |
| #4 | Z End | Final drill depth |
| #5 | Peck | Depth per peck (0 = no peck) |

Calls M101 to enable Z-axis. Retracts to Z Start between pecks with 0.020" rapid-approach gap.

### drill_man.ngc - Manual Drill
Positions XY then pauses for operator to manually plunge.

```
o<drill_man> call [x][y]
```

Calls M102 to disable Z-axis, then M0 pause.

### drill_retr.ngc - Semi-Manual Drill with Retract
Positions XY, retracts Z to clearance, disables Z for manual plunge, then re-enables and retracts on resume.

```
o<drill_retr> call [x][y] [z_clearance]
```

## Material Removal Subroutines

### pocket_circ.ngc - Circular Pocket
Cuts a circular pocket using an outward spiral from center.

```
o<pocket_circ> call [x][y] [diameter] [ztop][zbot] [fincut] [mode]
```

| # | Name | Description |
|---|------|-------------|
| #1 | X | Center X |
| #2 | Y | Center Y |
| #3 | Diameter | Pocket diameter |
| #4 | Z Top | Start Z |
| #5 | Z Bottom | Final depth |
| #6 | Finish Cut | Finish allowance (negative = rough only) |
| #7 | Mode | Bitmask (see above) |

Supports helix or plunge entry. Spirals outward with stepover, then does a pre-finish circle and optional finish circle at full diameter.

### pocket_rect.ngc - Rectangular Pocket
Cuts a rectangular pocket. Uses helical or straight plunge, then an outward spiral that transitions to linear passes when the spiral hits the rectangle boundary.

```
o<pocket_rect> call [x1][y1] [x2][y2] [zstart][zend] [fincut] [mode]
```

| # | Name | Description |
|---|------|-------------|
| #1,#2 | X1, Y1 | First corner |
| #3,#4 | X2, Y2 | Opposite corner |
| #5 | Z Start | Start Z |
| #6 | Z End | Final depth |
| #7 | Finish Cut | Finish allowance |
| #8 | Mode | 0=CCW/helix, 1=CW/helix, 2=CCW/plunge, 3=CW/plunge |

Contains internal sub `o<xp>` for filling corners after the spiral exceeds the rectangle bounds.

### frame_rect.ngc - Rectangular Frame
Cuts along the perimeter of a rectangle (inside or outside).

```
o<frame_rect> call [x1][y1] [x2][y2] [ztop][zbot] [mode] [radius]
```

| # | Name | Description |
|---|------|-------------|
| #1,#2 | X1, Y1 | First corner |
| #3,#4 | X2, Y2 | Opposite corner |
| #5 | Z Top | Start Z |
| #6 | Z Bottom | Final depth |
| #7 | Mode | Bitmask |
| #8 | Radius | Corner radius (0 = sharp corners) |

Supports all four combinations of inside/outside and climb/conventional. Plunges at center (inside) or corner (outside), then traces the rectangle with optional corner radii.

### frame_circ.ngc - Circular Frame
Cuts along the perimeter of a circle (inside or outside).

```
o<frame_circ> call [x][y] [diameter] [ztop][zbot] [fincut] [mode]
```

| # | Name | Description |
|---|------|-------------|
| #1 | X | Center X |
| #2 | Y | Center Y |
| #3 | Diameter | Circle diameter |
| #4 | Z Top | Start Z |
| #5 | Z Bottom | Final depth |
| #6 | Finish Cut | Finish allowance |
| #7 | Mode | Bitmask |

Uses a small arc entry/exit move (capped at 15% of diameter) for smooth engagement.

### slot.ngc - Slot
Cuts a slot (obround/stadium shape) between two points.

```
o<slot> call [x1][y1] [x2][y2] [width] [ztop][zbot] [fincut] [mode]
```

| # | Name | Description |
|---|------|-------------|
| #1,#2 | X1, Y1 | Slot start center |
| #3,#4 | X2, Y2 | Slot end center |
| #5 | Width | Slot width |
| #6 | Z Top | Start Z |
| #7 | Z Bottom | Final depth |
| #8 | Finish Cut | Finish allowance |
| #9 | Mode | Bitmask |

Plunges at start, cuts to end, then traces the obround profile. Supports optional pre-finish pass when fincut > 0.

### bore.ngc - Helical Bore
Helical-interpolation boring subroutine.

```
o<bore> call [x][y] [d] [zstart][zend] [stepdown]
```

| # | Name | Description |
|---|------|-------------|
| #1 | X | Center X |
| #2 | Y | Center Y |
| #3 | D | Bore diameter |
| #4 | Z Start | Start Z |
| #5 | Z End | Final depth |
| #6 | Stepdown | Depth per helical pass |

Spirals down in full-circle passes, then does a partial-arc cleanup and spring pass at final depth. Returns to center and Z0.

## Typical Program Header
```
#<_z_clearance> = 0.0
#<_rampang>     = 5.0

G10 L1 P1 Z0.0 R0.25  ; set tool P1 offset and radius
T1   ; select tool
M06  ; manual toolchange

M101 ; enable z-axis
G90  ; absolute coordinates
G54  ; fixture #1

F5.0 ; feedrate
```

## Known Bugs

1. **drill_retr.ngc: Sub name mismatch.** Opened as `o<drill_retr>` (line 1) but closed as `o<drill_man_retract>` (line 23). This will cause a runtime error - LinuxCNC requires matching sub/endsub names.

2. **bore.ngc: Parameter comment is wrong.** The inline comment says `; x, y, d, stepdown, zstart, zend` but the actual parameter order used by the code is `x, y, d, zstart, zend, stepdown`. Anyone calling based on the comment would get wrong results.

3. **bore.ngc: Undocumented `#<_td>` dependency.** Uses global `#<_td>` for tool-diameter compensation but never validates it. If unset (defaults to 0), the bore toolpath radius becomes `D/2` instead of `(D - tool_dia)/2`, cutting an oversized bore.

4. **drill.ngc: First peck cycle is a no-op.** The loop initializes `#<h> = #3` (Z Start) then immediately does `G1 Z#<h>` - moving to where the tool already is. First real cut happens on the second iteration. Wastes one retract cycle.

5. **pocket_circ.ngc: Suspicious angle calculation.** Line 66 has a `TODO` comment from the author: `; TODO: what the heck is the denominator here doing?` The finish-plunge angle divides by `[#4-#5]` (ztop - zbot). If ztop is 0 this produces a division by a potentially small number, which may cause unexpected arc endpoints.

6. **pocket_rect.ngc: Incomplete rectangular clearing.** The spiral-to-rectangle transition has commented-out code (lines 141-151) and a note saying "subroutines might be the best way to do this". The `o<xp>` helper sub attempts to fill the remaining area but uses a different algorithm. Corners may not be fully cleared depending on geometry.

7. **slot.ngc: Test code after endsub.** Lines 79-83 contain hardcoded test calls that execute whenever the file is loaded. These should be removed or moved to a separate test file. The test calls also only provide 7 of 9 parameters (fincut and mode default to 0).

8. **frame_circ.ngc: lead-in arcs can be larger than actual pocket size.** this causes overcutting. not good.

9. **some combination of values will cause hangs.** This is in several macros. linuxcnc does not have stall/timeout detection; if a macro gets stuck in an infinite loop, it hangs linuxcnc.

## Other Todos

1. Change macros to use UPPERCASE_WITH_UNDERSCORES naming (both the filenames, and the usage of them in all .ngc files)
2. Purge all .cnc programs
3. Maybe: Use tool diameter instead of the td global. (we will use tool change stuff)