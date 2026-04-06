# Tool Changes, Offsets & Work Coordinates in LinuxCNC

Reference for the Lagun mill config (non-random manual toolchanger, GMOCCAPY GUI, inch mode).

---

## Tool Table (`tool.tbl`)

Each line defines a tool:

```
T3   P3   D+0.187500            ;3/16in flat
T1   P1   D+0.187500 I+7.000000 ;0.201in DrillBit
T5   P5   D+0.250000            ;1/4
```

| Column | Meaning |
|--------|---------|
| **T** | Tool number (what programs reference with `T1`, `T5`, etc.) |
| **P** | Pocket number (our setup just uses P = T) |
| **Z** | Tool length offset (distance from spindle reference to tool tip) |
| **D** | Tool **diameter** (full width, not radius) |
| **;** | Comment |

**Important**: The D column stores **diameter**, but `G10 L1` sets it using **radius** (R word). This is a common source of confusion.

---

## Tool Change Sequence

```gcode
T1          ; select tool 1 (prepares it, does NOT load it)
M6          ; execute the change — pops up the manual tool change dialog
G43         ; activate that tool's length offset
```

- `T` alone only **selects** (prepares) a tool. Nothing physical happens.
- `M6` performs the actual change. On our machine this pops up a dialog prompting the operator to insert the tool and click OK.
- `G43` applies the tool's Z offset from the tool table. **Without this line, the machine has no idea how long the tool is.**
- `T1 M6` on one line is fine (and common).

After `M6`, the built-in parameter `#<_current_tool>` holds the loaded tool number, and `#5410` holds its diameter.

---

## Tool Length Offset (G43 / G49)

### Activating

| Command | Effect |
|---------|--------|
| `G43` | Apply TLO of the **currently loaded** tool (from last M6) |
| `G43 H1` | Apply TLO of tool **1** from the table (doesn't have to match spindle tool) |
| `G43.1 Z0.5` | Dynamic TLO: set Z offset to 0.5 directly (doesn't write to table) |
| `G43.2 H1` | Cumulative: **add** tool 1's offset on top of the current offset |

`G43` shifts all subsequent Z moves by the tool's Z offset. No motion occurs on the G43 line itself — the offset applies on the next move.

### Canceling

```gcode
G49     ; cancel tool length offset
```

### Typical multi-tool workflow

```gcode
T1 M6               ; load tool 1
G43                  ; activate its TLO
; ... do work ...
G49                  ; cancel TLO before next change
T2 M6               ; load tool 2
G43                  ; activate tool 2's TLO
```

---

## Setting Tool Offsets with G10

### G10 L1 — Write directly to the tool table

```gcode
G10 L1 P<tool#> Z<length> R<radius>
```

- **P**: tool number to update
- **Z**: tool length offset (direct value)
- **R**: tool **radius** (half the diameter). LinuxCNC stores this as `D = 2 * R` in the tool table.

Examples:

```gcode
G10 L1 P1 Z-2.500 R0.125   ; tool 1: length=-2.5", radius=0.125" (1/4" endmill, D=0.250)
G10 L1 P1 R[3/16/2]        ; just update radius: 3/16" tool -> R=0.09375 -> D=0.1875
```

After `G10 L1`, re-issue `G43` to pick up the new offset if that tool is already loaded.

### G10 L10 — Set offset by touching off (work coords as reference)

```gcode
G10 L10 P<tool#> Z<desired_coord>
```

Calculates what Z offset the tool table needs so that, with the current work coordinate system active and the machine at its current position, the Z display would read the specified value.

Touch-off workflow:
1. Load tool, jog Z down until it touches the workpiece surface
2. `G10 L10 P1 Z0` — "the tip is at Z=0, calculate the offset"

### G10 L11 — Touch off using G59.3 as reference

Same as L10 but uses G59.3 (with no G52/G92) as the reference frame. Useful if you have a fixed tool-length probe at a known machine position stored in G59.3.

---

## Cutter Radius Compensation (G41 / G42 / G40)

Cutter comp shifts the toolpath left or right of the programmed path by the tool's radius. This lets you program to the part geometry (the actual edge you want) and let LinuxCNC offset the toolpath by the tool radius automatically.

### Basics

```gcode
G41         ; compensate LEFT of the programmed path (climb milling on outside profiles)
G42         ; compensate RIGHT of the programmed path (conventional milling on outside profiles)
G40         ; cancel compensation — return to programming on centerline
```

"Left" and "right" are from the perspective of looking down the tool axis in the direction of travel.

### The D word

```gcode
G41 D1      ; use tool 1's diameter from the table for the offset amount
G42         ; no D = use the currently loaded tool's diameter
```

**The D word in G41/G42 is a tool number**, not a diameter value. LinuxCNC looks up that tool's D column (diameter), halves it, and uses that as the offset distance.

### Rules and gotchas

- The **lead-in move** (first move after G41/G42) must be **at least as long as the tool radius**. A rapid (G0) is fine.
- The **lead-out move** (move on the same line as G40) must also be linear and at least as long as the tool radius.
- **Inside corners**: the path is shortened to prevent gouging.
- **Outside corners**: the path is extended (the tool wraps around the corner).
- **U-turns and tight inside corners** where the tool can't physically fit will cause an error.
- Cutter comp only works in **G17** (XY plane). For G18/G19 it compensates in the respective plane.
- You **cannot** start cutter comp while already in cutter comp — must G40 first.

### Example: cutting an outside profile

```gcode
G10 L1 P1 R[1/4/2]          ; tool 1 = 1/4" endmill (R=0.125, D=0.250)
T1 M6
G43

G0 X-1 Y-1                  ; position away from the part
G41                          ; turn on left comp (uses current tool's D)
G1 X0 Y0 F10                ; lead-in move to first corner (must be >= tool radius)
G1 X0 Y2                    ; cut along left edge
G1 X3 Y2                    ; cut along top edge
G1 X3 Y0                    ; cut along right edge
G1 X0 Y0                    ; cut along bottom edge, back to start
G40                          ; cancel comp
G0 X-1 Y-1                  ; lead-out / retract
```

The programmed path (X0 Y0 to X3 Y2) is the actual part edge. The tool centerline runs 0.125" outside of it.

### Dynamic variant

```gcode
G41.1 D0.250    ; compensate left by 0.250" diameter (= 0.125" offset) directly
G42.1 D0.250    ; compensate right
```

Here the D word **IS** a diameter value (not a tool number). Useful when you want to specify the offset directly without looking it up from the table.

### Cutter comp vs. our macros

Our macros (`pocket_circ`, `frame_rect`, etc.) do their own tool-diameter compensation internally using `#<_td>`. They do **not** use G41/G42. So:

- Use **G41/G42** when you're writing raw G-code profiles (manually programmed contours).
- Use **`#<_td>`** when calling our subroutines — they handle the offset math themselves.
- Don't use both at the same time on the same toolpath.

---

## Work Offsets (G54–G59.3)

Work offsets define where "zero" is on your workpiece relative to the machine's home position.

### Available coordinate systems

| G-code | Name | P number (for G10) |
|--------|------|--------------------|
| G54 | Work offset 1 (default) | P1 |
| G55 | Work offset 2 | P2 |
| G56 | Work offset 3 | P3 |
| G57 | Work offset 4 | P4 |
| G58 | Work offset 5 | P5 |
| G59 | Work offset 6 | P6 |
| G59.1 | Work offset 7 | P7 |
| G59.2 | Work offset 8 | P8 |
| G59.3 | Work offset 9 | P9 |

These **persist across power cycles** — they're stored in `linuxcnc.var`.

### Setting work offsets

**Touch-off method** (most common): jog to where you want zero, then:

```gcode
G10 L20 P1 X0 Y0    ; "right here is G54 X0 Y0"
G10 L20 P0 Z0        ; "right here is Z0 in the currently active system"
```

- `P0` = whichever G5x is currently active
- You only need to specify the axes you want to set

**Direct method**: if you know the machine-coordinate position of your fixture:

```gcode
G10 L2 P1 X-12.500 Y-6.000 Z0.000    ; G54 origin is at machine X-12.5 Y-6.0 Z0.0
```

**Switching** between coordinate systems:

```gcode
G55    ; now all coords are relative to work offset 2
```

### Practical use

- **One fixture, one part**: Just use G54. Touch off XYZ zero on your stock.
- **Multiple fixtures / vises**: G54 for vise 1, G55 for vise 2. Touch off each.
- **Multiple setups on one part**: Flip the part, touch off new Z in G54.

### G52 and G92 (temporary offsets)

`G52 X1 Y1` adds a temporary offset on top of the active G5x. Useful for pattern repeats.

`G92 X0 Y0` says "my current position IS X0 Y0" (like G10 L20 but temporary). **Caution**: G92 offsets persist across program runs until cleared with `G92.1`. This is a common gotcha. Prefer G52 over G92.

### Your pendant buttons

| Button | MDI Command | What it does |
|--------|------------|--------------|
| Macro 5 | `G10 L20 P0 X0` | Zero X in current work offset |
| Macro 6 | `G10 L20 P0 Y0` | Zero Y in current work offset |
| Macro 7 | `G10 L20 P0 Z0` | Zero Z in current work offset |
| Macro 1 | `G10 L20 P0 X[#<_x>/2.0]` | Halve X (center-finding) |
| Macro 2 | `G10 L20 P0 Y[#<_y>/2.0]` | Halve Y (center-finding) |

The halve trick: touch one edge of the stock and zero it, jog to the other edge, press the halve button — now you're at the center.

---

## Coordinate System Hierarchy

```
Displayed position = Machine position
                   + G5x work offset (G54, G55, ... set by G10 L2/L20)
                   + G52/G92 offset
                   + G43 tool length offset
```

`G53` bypasses all offsets and moves in raw machine coordinates (useful for "go to tool change position" moves).

---

## GMOCCAPY Interface

### DRO (Digital Readout)

The DRO has three display modes, toggled by **clicking any axis value**:

| Mode | Background | Shows |
|------|------------|-------|
| **Relative** | Black | Position in current work coordinate system (G5x + tool offset + G92). This is what your G-code program sees. |
| **Absolute** | Blue | Machine coordinates (G53). Position relative to machine home. |
| **DTG** | Yellow | Distance To Go — remaining distance to the programmed endpoint during motion. |

DRO digit colors indicate homing status:
- **Green** = homed (reference established)
- **Red** = unhomed (position is not trustworthy)

### Touch-Off via the DRO

**Click the axis letter** (the "X", "Y", or "Z" label, not the number) to open a popup dialog. Enter the coordinate value you want the current position to represent (usually `0`). This issues `G10 L20 P0 <axis> <value>` internally.

### Offset Page

The Offset page (accessible from the notebook tabs) shows a table of all work coordinate systems (G54–G59.3) plus G92 and tool offsets. The currently active system is highlighted.

- **Double-click a cell** to edit a value directly. This issues `G10 L2 P<n> <axis> <value>` (sets the offset to the value you typed, NOT touch-off style).
- **"Zero G92" button**: sends `G92.1` to cancel G92 offsets.
- **"Set Active" button**: switches the active coordinate system (e.g., click the G55 row, then "Set Active" to switch to G55).

**Key distinction**: Editing the offset page sets offsets with `G10 L2` (absolute). Touching off via the DRO uses `G10 L20` (calculated from current position). These are different operations.

### Tool Page

Shows the tool table with columns for tool number, pocket, diameter, and Z offset.

- **Click a cell** to edit. Changes are NOT live until you click **"Apply Changes"**.
- After applying, you must **re-issue `G43`** (in MDI) if the active tool's offset changed. GMOCCAPY does not do this automatically.
- The top of the page shows the currently loaded tool's active offsets (fed by the `gmoccapy.tooloffset-x` and `gmoccapy.tooloffset-z` HAL pins).

### Tool Change Dialog

When a program executes `M6`, GMOCCAPY pops up a dialog showing the tool number and its description from the tool table comment. The operator physically changes the tool and clicks OK (or presses a physical confirm button wired to `gmoccapy.toolchange-confirm`).

Our config currently uses `hal_manualtoolchange` instead of GMOCCAPY's built-in dialog (wired in `lagun.hal`). The behavior is similar — a popup appears, operator confirms.

### Auto Tool Measurement (not currently configured)

GMOCCAPY supports automatic tool length measurement using a fixed probe on the machine table. This requires:

1. A `[TOOLSENSOR]` INI section with the probe's machine coordinates
2. A `[CHANGE_POSITION]` INI section for safe tool-change position
3. Remapping M6 to a `change.ngc` script that probes after each tool swap
4. The probe input wired to `motion.probe-input`

When enabled, every M6 automatically: moves to the change position, swaps the tool, drives to the probe, measures the tool, stores the offset with `G10 L1`, and activates it with `G43`. This eliminates manual tool touch-off.

We don't have this set up yet, but it's a natural next step if a tool setter is installed on the machine.

---

## Named Parameters for Tool Info

| Parameter | Value |
|-----------|-------|
| `#<_current_tool>` | Tool number in the spindle |
| `#<_selected_tool>` | Tool number from last `T` word (before M6) |
| `#5400` | Same as `#<_current_tool>` |
| `#5401`–`#5409` | Active TLO values (X through W) |
| `#5410` | **Tool diameter** of current tool (D column value) |

### About `#<_td>` in our macros

`#<_td>` is **not** a built-in LinuxCNC parameter. It is a user-defined global that our macros read for tool diameter. Programs must set it manually:

```gcode
#<_td> = [3/16]   ; 3/16" endmill
```

A future improvement would be to replace `#<_td>` with `#5410` (the built-in diameter parameter), but this requires proper tool table setup with correct D values and a `T M6 G43` sequence before cutting.

---

## Quick Reference

### Full setup with tool change and cutter comp
```gcode
G10 L1 P1 Z-2.5 R[1/4/2]   ; tool 1: Z offset and 1/4" endmill radius
T1 M6                        ; load tool 1
G43                           ; activate TLO
G41                           ; cutter comp left (uses tool 1's D from table)
F10
G1 X0 Y0                     ; lead-in (>= tool radius long)
G1 X2 Y0                     ; cut along edge
G40                           ; cancel comp (with lead-out move)
G0 X-1 Y-1
```

### Touch off tool length
```gcode
T1 M6                        ; load tool
; jog Z down until tool touches top of workpiece
G10 L10 P1 Z0                ; store: "this position = Z0"
G43                           ; activate the new offset
```

### Touch off work zero
```gcode
; jog to front-left corner of stock
G10 L20 P1 X0 Y0             ; set G54 origin here
; jog Z to top of stock
G10 L20 P1 Z0                ; set G54 Z origin here
```

### Our current macro workflow
```gcode
#<_td> = [1/4]                ; tell macros the tool is 1/4"
#<_z_top> = 0.05
#<_z_bot> = -0.25
#<_z_clearance> = 0.2

G10 L1 P1 Z0.0 R[1/4/2]      ; also set it in the table for cutter comp
T1 M6
G43
M03
F5

o<pocket_circ> call [0][0] [1.0] [0] [0]
```
