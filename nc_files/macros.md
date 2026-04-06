# Macros & Subroutines

Custom M-codes and G-code subroutines for the Lagun mill LinuxCNC configuration.

All macro `.ngc` files live in `nc_files/subs/` and are loaded automatically via the `SUBROUTINE_PATH` setting in the INI.

## Mode Flags (Bitmask)

All material-removal macros (except drill/bore) take `mode` as the **first argument**:

| Bit | Value | Set (1) | Clear (0) |
|-----|-------|---------|-----------|
| 0 | +1 | Conventional milling | Climb milling |
| 1 | +2 | Both-ways milling | One-way milling |
| 2 | +4 | Plunge entry | Helix entry |
| 3 | +8 | Outside | Inside |

Default mode (0) = climb, one-way, helix entry, inside.

## Global Named Parameters

| Parameter | Description | Required? |
|-----------|-------------|-----------|
| `#<_z_top>` | Top of material / start Z height | **Required** |
| `#<_z_bot>` | Final cut depth | **Required** |
| `#<_z_clearance>` | Safe Z retract height | Optional, falls back to `#<_z_top>` |
| `#<_rampang>` | Helix entry angle in degrees | Optional, defaults to 5.0 |
| `#<_stepover>` | Stepover distance | Optional, defaults to 40% of tool diameter |

Tool diameter is read automatically from `#5410` (the built-in LinuxCNC parameter for the current tool's diameter from the tool table). A tool must be loaded (`T M6 G43`) before calling any material-removal macro.

A negative `fincut` value causes macros to rough only, leaving that amount of material for a separate finishing pass.

## M-Codes (Shell Scripts)

### M101 - Enable Z-Axis
Sets HAL signal `z-override` to True, enabling CNC control of Z.

### M102 - Disable Z-Axis
Sets HAL signal `z-override` to False, allowing manual quill control.

## Utility Subroutines

### z_home - Rapid to Machine Z0
Rapids the quill to machine Z=0 (fully up) using G53 to bypass all offsets.

```
o<z_home> call
```

## Drilling Subroutines

### drill - Peck Drill

```
o<drill> call [x][y] [peck]
```

Calls M101 to enable Z. Retracts to Z Top between pecks with 0.020" rapid-approach gap.

### drill_man - Manual Drill

```
o<drill_man> call [x][y]
```

Calls M102 to disable Z, then M0 pause. No Z globals needed.

### drill_retr - Semi-Manual Drill with Retract

```
o<drill_retr> call [x][y]
```

## Material Removal Subroutines

### pocket_circ - Circular Pocket

```
o<pocket_circ> call [mode] [x][y] [diameter] [fincut]
```

### pocket_rect - Rectangular Pocket (Zigzag)

```
o<pocket_rect> call [mode] [x1][y1] [x2][y2] [fincut]
```

Zigzag along the long axis, stepping by `#<_stepover>`. Perimeter cleanup pass at the end.

### frame_rect - Rectangular Frame

```
o<frame_rect> call [mode] [x1][y1] [x2][y2] [radius]
```

### frame_circ - Circular Frame

```
o<frame_circ> call [mode] [x][y] [diameter] [fincut]
```

### slot - Slot / Obround

```
o<slot> call [mode] [x1][y1] [x2][y2] [width] [fincut]
```

### bore - Helical Bore

```
o<bore> call [x][y] [d] [stepdown]
```

No mode arg. Uses `#<_z_top>`, `#<_z_bot>`, and `#5410`.

### poly_frame - Polygon Perimeter

```
o<poly_frame> call [mode] [x][y] [n_sides] [apothem] [rotation] [fincut]
```

Apothem = flat-to-flat / 2. Rotation in degrees (0 = first vertex on +X, CCW positive).

### poly_pocket - Polygon Pocket

```
o<poly_pocket> call [mode] [x][y] [n_sides] [apothem] [rotation] [fincut]
```

## Typical Program Header

```gcode
#<_z_clearance> = 0.2
#<_rampang>     = 5.0
#<_z_top>       = 0.05
#<_z_bot>       = -0.25

G10 L1 P1 Z0.0 R0.125    ; set tool 1 offset and 1/4" radius
T1 M6                      ; load tool (sets #5410 = 0.250)
G43                         ; activate TLO

M101                        ; enable z-axis
G90                         ; absolute coordinates
G54                         ; fixture #1
F5.0                        ; feedrate

o<pocket_circ> call [0] [0][0] [1.0] [0]
```

## Known Bugs & Limitations

1. **Some combinations of values cause hangs.** LinuxCNC has no stall/timeout detection; a macro stuck in an infinite loop hangs the whole machine. Iteration limits have been added to pocket_circ's spiral loop as a safety measure.

2. **Slot arc directions may be wrong under some combinations** — inverted arc ends seen under certain mode/geometry combinations.
