; LEDGER.asm
; -- The BLOOM ledger for adding custom scripts to Orchid's 'blooming' stage.
; -- In this file, users creating custom scripts will add their scripts from the ./scripts directory to Orchid's
; ---- bloom module. The files will be required to use

; Include your scripts here...
; Later on, creation of this file will be automatic with the COMPILE scripts.
; -- There will be a compiler section asking about the BLOOM scripts you'd like to add,
; ---- listing the files in the 'scripts' directory, and asking for your choices to include.
; ---- Based on those choices, the compiler will auto-append this file with the proper "includes" for you.
%include "bloom/scripts/TEST.asm"
