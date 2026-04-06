# Lagun Mill - LinuxCNC

## Docs

- [nc_files/MACROS.md](nc_files/MACROS.md) — macro subroutine reference (drill, pocket, frame, slot, bore, polygon)
- [nc_files/OFFSETS.md](nc_files/OFFSETS.md) — quick reference for work offsets, tool offsets, cutter comp
- [nc_files/TOOLS.md](nc_files/TOOLS.md) — deep-dive on tool changes, G10, G41/G42, GMOCCAPY interface
- [configs/lagun_gmoccapy/README.md](configs/lagun_gmoccapy/README.md) — machine config, wiring, HAL, pendant mapping

## Hardware TODO
- [ ] pendant buttons (wire ESTOP/START/STOP on GPIO 029/030/031)
- [ ] holders for wrenches etc
- [ ] permanent good fix for z axis bracket

## Software TODO
- [x] Use `#5410` (tool diameter from table) instead of `#<_td>` global
- [x] Reorder macro args to put mode argument first
- [x] Fix macro bugs (iteration limits, division guards, frame_circ lead-in clamp)
- [x] `o<z_home>` macro: rapids to machine Z=0 via `G53 G0 Z0`
- [NOT HAPPENNING] Set up auto tool measurement (tool setter probe + M6 remap)
- [NOT HAPPENNING] Auto-start LinuxCNC on boot (dwm + startx — see [config README](configs/lagun_gmoccapy/README.md#auto-start-setup))

## CAM options
- https://www.scorchworks.com/Fengrave/fengrave.html
- https://www.estlcam.de/
- https://www.grzsoftware.com/
