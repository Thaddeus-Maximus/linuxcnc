#<_z_clearance> = 0.4
#<_rampang>     = 5

;#<_overlap> = 0

; +1: Conventional milling
; +2: Both-ways milling
; +4: Plunge entry
; +8: Outside


G10 L1 P1 Z0.0 R[8/25.4 /2] ; set tool
T1   ; set tool to T1
M06  ; manual toolchange
G54  ; absolute coordinates
F10  ; 10 ft/min

#1 = 1

o10 if [#1 EQ 1]
	o<drill> call [ 0.75][-.75] [0.1][-0.45]
	o<drill> call [ 2.35][-.75] [0.1][-0.45]
	;o<drill> call [ 3.35][-.75] [0.1][-0.45]
	o<drill> call [ 4.35][-.75] [0.1][-0.45]
	;o<drill> call [ 5.35][-.75] [0.1][-0.45]

o10 else if [#1 EQ 2]
	o<slot_chop> call [2.35][-.75] [3.35][-.75] [.35] [0.1][-0.45] [0.01] [+4]
	o<slot_chop> call [3.35][-.75] [4.35][-.75] [.35] [0.1][-0.45] [0.01] [+4]

o10 endif


M2 ; end program
