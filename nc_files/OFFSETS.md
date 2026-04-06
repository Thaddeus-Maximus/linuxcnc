# Offsets Quick Reference

## Coordinate Stack

```
What you see = machine position + work offset (G54...) + G52/G92 + tool length offset (G43)
```

`G53` bypasses everything and moves in machine coords.

## Work Offsets (G54–G59.3)

9 available coordinate systems. G54 is default. Persist across power cycles (stored in `linuxcnc.var`).

### Touching off work zero

**In GMOCCAPY**: Jog to desired zero, click the axis letter (X/Y/Z) in the DRO, enter `0`. Done.
Internally: `G10 L20 P0 <axis> 0`

**Pendant**: Macro 5/6/7 = zero X/Y/Z. Macro 1/2 = halve X/Y (center-finding: zero one edge, jog to other edge, halve).

**In G-code**:
```gcode
G10 L20 P1 X0 Y0 Z0    ; set G54 origin to current position
G10 L20 P0 X0           ; set current system's X to 0
```

### Switching systems

```gcode
G55    ; all coords now relative to work offset 2
```

In GMOCCAPY: Offset page > click row > "Set Active".

### Editing numerically

In GMOCCAPY: Offset page > double-click a cell > type value. This uses `G10 L2` (absolute set), not touch-off.

### Temporary offsets

```gcode
G52 X1 Y1    ; shift on top of active G5x (good for pattern repeats)
G52 X0 Y0    ; cancel
```

Avoid `G92` — it persists across program runs and causes confusion. Use `G92.1` to clear if needed.

## Tool Length

### Setting up a tool (first time)

1. In GMOCCAPY Tool page: set diameter (D column) and any known Z offset. Click "Apply Changes".
2. Or in G-code: `G10 L1 P1 Z-2.5 R0.125` (R = **radius**, stored as D = diameter = 2R)

### Loading a tool

```gcode
T1 M6    ; select + change (pops up dialog, operator confirms)
G43      ; activate its Z offset — REQUIRED or Z is wrong
```

### Touching off tool length

Jog tool tip down to top of workpiece, then in MDI:

```gcode
G10 L10 P1 Z0    ; "tip is at Z=0, calculate and store the offset"
G43               ; activate it
```

Or: GMOCCAPY DRO > click Z letter > enter `0` (but this sets the **work offset**, not the tool offset — different thing).

### Canceling

```gcode
G49    ; cancel tool length offset
```

Standard practice: `G49` before each tool change, `G43` after.

## Cutter Radius Compensation (G41/G42)

Offsets the toolpath left or right of the programmed line by the tool's radius. Program the actual part edge; the machine handles the rest.

```gcode
G41      ; offset LEFT of path (climb milling outside profiles)
G42      ; offset RIGHT
G40      ; cancel
```

The D word in G41/G42 is a **tool number** (not a diameter): `G41 D1` looks up tool 1's diameter from the table. Omit D to use the current tool.

Rules:
- Lead-in move after G41/G42 must be >= tool radius
- Lead-out move with G40 must be >= tool radius
- Must be in G17 (XY plane)

```gcode
G41                  ; comp on
G1 X0 Y0 F10        ; lead-in (this IS the first compensated move)
G1 X2 Y0            ; cut along part edge — tool rides 1 radius to the left
G1 X2 Y2
G40                  ; comp off (next linear move is lead-out)
G0 X-1 Y-1
```

Dynamic variant: `G41.1 D0.250` — D is a literal diameter value, not a tool number.

**Our macros** handle radius compensation internally via `#<_td>`. Don't use G41/G42 with macro calls.

## Tool Table Columns (mill)

| Column | Meaning |
|--------|---------|
| T | Tool number |
| P | Pocket (we use P = T) |
| Z | Length offset |
| D | Diameter (not radius) |

## DRO Modes (click axis value to cycle)

| Mode | Color | Shows |
|------|-------|-------|
| Relative | Black | Work coords (what G-code sees) |
| Absolute | Blue | Machine coords (G53) |
| DTG | Yellow | Distance to go |

Green digits = homed. Red = unhomed.

## Named Parameters

| Parameter | Value |
|-----------|-------|
| `#<_current_tool>` / `#5400` | Tool in spindle |
| `#5410` | Current tool diameter |
| `#<_td>` | Our macros' tool diameter (user-set, not built-in) |
