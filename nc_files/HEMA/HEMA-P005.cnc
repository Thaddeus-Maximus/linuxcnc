#<_z_clearance> = 0.4
#<_rampang>     = 5

; mode reference
; +1: Conventional milling
; +2: Both-ways milling
; +4: Plunge entry
; +8: Outside


G21  ; mm
G10 L1 P1 Z0.0 R5.0 ; set tool
T1   ; set tool to T1
M06  ; manual toolchange
G54  ; absolute coordinates
F3000  ; mm/min (300 mm/min = about 1 ft/min)

o<drill> call [20][-10] [1][-8] [3]
o<drill> call [20][-40] [1][-8] [3]


M2 ; end program
