# Modes
Default mode (0) is:
- Climb milling
- One-way milling
- Helix entry
- Inside

+1: Conventional milling
+2: Both-ways milling
+4: Plunge entry
+8: Outside

# Fun stuff

Specifying a negative finish cut should cause macros to do all the roughing and leave the (positive) amount of material behind for a separate finishing op.

# Typical Header
```
#<_z_clearance> = 0.0 ; clearance height
#<_rampang>     = 5.0 ; ramp angle in degrees for helical entry

G10 L1 P1 Z0.0 R0.25 ; set tool P1 to Z-offset Z0.0 and radius R0.25
T1   ; set tool to T1
M06  ; manual toolchange

M101 ; enable z-axis
G90  ; absolute coordinates
G54  ; fixture #1

F5.0 ; feedrate
```


# Material removal

o<pocket_rect> call
o<pocket_circ> call

o<frame_rect>  call
o<frame_circ>  call

o<slot> call [x1][y1] [x2][y2] [width] [ztop][zbot] [finishcut]
o<bore> call [x][y] [stepdown] [ztop][zbot]

# Drilling

o<drill>      call [x][y] [ztop][zbot] [(peck)]; fully automoatic drilling op; drills at x,y from ztop to zbot in optional increments of peck (full retraction)

o<drill_man>  call [x][y] ; fully manual drilling op; z axis entirely disabled
o<drill_retr> call [x][y] ; semi-manual drilling op; z axis retracts, but disabled on downstroke

# Footer
```
M2 ; end program
```