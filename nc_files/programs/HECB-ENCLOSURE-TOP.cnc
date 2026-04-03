#<_z_clearance> = 0.3
#<_rampang>     = 20

; mode refernce
; +1: Conventional milling
; +2: Both-ways milling
; +4: Plunge entry
; +8: Outside

G20  ; G21 mm / G20 inch
G10 L1 P1 Z0.0 R[5/32/2] ; set tool
T1   ; set tool to T1
M06  ; manual toolchange
G54  ; absolute coordinates
F15  ; inch or mm/min (300 mm/min = about 1 ft/min)

#<zt> = +0.1
#<zb> = -0.2

#<da> = .250

o<pocket_circ> call [-2.250][+.984] [#<da>] [#<zt>][#<zb>]
o<pocket_circ> call [-2.742][+.197] [#<da>] [#<zt>][#<zb>]
o<pocket_circ> call [-1.758][-.197] [#<da>] [#<zt>][#<zb>]
o<pocket_circ> call [-2.250][-.984] [#<da>] [#<zt>][#<zb>]

o<drill> call [0.571][-0.151] [#<zt>][#<zb>]
o<drill> call [2.511][-0.151] [#<zt>][#<zb>]
o<drill> call [1.225][-1.997] [#<zt>][#<zb>]
o<drill> call [2.520][-2.426] [#<zt>][#<zb>]

o<frame_rect> call [.723][.307] [2.360][-.609] [#<zt>][#<zb>] [0] [.250]
o<frame_rect> call [1.377][-1.567] [2.368][-2.426] [#<zt>][#<zb>] [0] [.250]

M2 ; end program
