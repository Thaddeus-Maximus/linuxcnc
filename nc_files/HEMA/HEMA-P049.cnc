#<_z_clearance> = 0.5
#<_rampang>     = 10
;#<_stepover>  = 0.1

;#<_overlap> = 0

; mode refernce
; +1: Conventional milling
; +2: Both-ways milling
; +4: Plunge entry
; +8: Outside


G20  ; G21 mm / G20 inch
G10 L1 P1 Z0.0 R[1/4/2] ; set tool
T1   ; set tool to T1
M06  ; manual toolchange
G54  ; absolute coordinates
F15  ; inch or mm/min (300 mm/min = about 1 ft/min)



; 12 mm holes
o<pocket_circ> call [.591] [-.433] [12/25.4] [0.1][-.3] [0][4]
o<pocket_circ> call [.591] [-.984] [12/25.4] [0.1][-.3] [0][4]
o<pocket_circ> call [3.937] [-.433] [12/25.4] [0.1][-.3] [0][4]
o<pocket_circ> call [3.937] [-.984] [12/25.4] [0.1][-.3] [0][4]

; m5 holes

;o<drill_man> call [1.634] [-.315] 
;o<drill_man> call [1.634] [-.709] 
;o<drill_man> call [1.634] [-1.102]

;o<drill_man> call [2.894] [-.315] 
;o<drill_man> call [2.894] [-.709] 
;o<drill_man> call [2.894] [-1.102]


M2 ; end program
