#<_z_clearance> = 0.5
#<_rampang>     = 5
;#<_stepover>  = 0.08

;#<_overlap> = 0

; +1: Conventional milling
; +2: Both-ways milling
; +4: Plunge entry
; +8: Outside


G20  ; G21 mm / G20 inch
G10 L1 P1 Z0.0 R.125 ; set tool
T1   ; set tool to T1
M06  ; manual toolchange
G54  ; absolute coordinates
;F5   ; inch or mm/min (300 mm/min = about 1 ft/min)

#<prog> = 3

#<w>    = 3.0
#<bolt_r> = [40/25.4]


o10 if [#<prog> EQ 1]
	F3
	o<drill_man> call [#<w>/2][-#<w>/2] [0.1][-0.5]

	o<drill_man> call [#<w>/2+#<bolt_r>/SQRT[2]][-#<w>/2+#<bolt_r>/SQRT[2]] [0.1][-0.5]
	o<drill_man> call [#<w>/2+#<bolt_r>/SQRT[2]][-#<w>/2-#<bolt_r>/SQRT[2]] [0.1][-0.5]
	o<drill_man> call [#<w>/2-#<bolt_r>/SQRT[2]][-#<w>/2-#<bolt_r>/SQRT[2]] [0.1][-0.5]
	o<drill_man> call [#<w>/2-#<bolt_r>/SQRT[2]][-#<w>/2+#<bolt_r>/SQRT[2]] [0.1][-0.5]
	

o10 elseif [#<prog> EQ 2]
	F8
	; exterior
	o<spquircle_boss> call [#<w>/2][-#<w>/2] [#<w>][40/25.4] [0.02] [-0.125] [0.01]

	; center pocket
	o<spquircle_pocket> call [#<w>/2][-#<w>/2] [.937] [0.02][-.19] [0.01] [0]
	o<spquircle_pocket> call [#<w>/2][-#<w>/2] [.937] [-.19][-.45] [0.01] [+4]
	
	; cleanup the corners
	o<drill> call [#<w>/2+.38][-#<w>/2+.38] [0.02][-0.45]
	o<drill> call [#<w>/2-.38][-#<w>/2+.38] [0.02][-0.45]
	o<drill> call [#<w>/2-.38][-#<w>/2-.38] [0.02][-0.45]
	o<drill> call [#<w>/2+.38][-#<w>/2-.38] [0.02][-0.45]

o10 elseif [#<prog> EQ 3]
	F10
	#<b> = .96
	o<frame_rect> call [#<w>/2+#<b>/2][-#<w>/2+#<b>/2] [#<w>/2-#<b>/2][-#<w>/2-#<b>/2] [0.02][-.45]

o10 endif


M2 ; end program
