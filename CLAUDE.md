# CLAUDE.md

## Project
LinuxCNC configuration and custom G-code macro library for a Lagun milling machine.

## Structure
- `configs/lagun_gmoccapy/` — machine config (INI, HAL, tool table, pendant)
- `nc_files/subs/` — macro subroutines (auto-loaded via SUBROUTINE_PATH)
- `nc_files/programs/` — standalone part programs
- `nc_files/HEMA/`, `HEMS/`, `HEQJ/` — project-specific part programs
- `nc_files/*.ngc` — older part programs (root level)
- `datasheets/` — Mesa board PDFs

## Key docs
- `nc_files/MACROS.md` — macro API reference
- `nc_files/OFFSETS.md` — work offsets, tool offsets, cutter comp quick reference
- `nc_files/TOOLS.md` — deep dive on tool changes and GMOCCAPY interface
- `configs/lagun_gmoccapy/README.md` — machine config, wiring, HAL, pendant mapping

## Macro conventions
- All macros in `nc_files/subs/` use lowercase filenames (LinuxCNC matches `o<name>` to `name.ngc`)
- Mode bitmask is always the FIRST positional arg (#1) for macros that accept it
- Z heights come from globals `#<_z_top>` and `#<_z_bot>`, not positional args
- Tool diameter comes from `#5410` (built-in LinuxCNC param, requires T M6 G43 first)
- Optional globals: `#<_z_clearance>`, `#<_rampang>`, `#<_stepover>`
- M101/M102 enable/disable Z-axis CNC control (for manual quill operation)

## When editing macros
- Do not change functional behavior without asking — these run on a real mill
- The `o<number>` labels (o1, o101, etc.) must be unique within each file
- LinuxCNC G-code uses `[expressions]` for math, `#<name>` for named params, `#N` for positional args
- `G90.1` = absolute arc centers (I/J), `G91.1` = incremental arc centers — check which mode each macro uses
- Test calls should never appear after `endsub` (they execute on every load)

## When editing caller programs
- Programs set `#<_z_top>` and `#<_z_bot>` before macro calls
- Mode arg is first: `o<pocket_circ> call [0] [x][y] [d] [fincut]`
- Commented-out calls (`;o<...>`) should keep their format consistent with active calls

## Machine details
- 3-axis mill: X (+-24"), Y (+-12"), Z (-4" to +1")
- Mesa 5i24 FPGA + 7i52 servo interface + 7i37-TA isolated I/O
- Dual PID on X and Y (motor encoder + linear scale, outputs summed)
- Z has special override mechanism (M101/M102 via logic AND gate)
- GMOCCAPY GUI, XHC WHB04B-6 wireless pendant
- Units: inches
- Manual tool change (no ATC)
