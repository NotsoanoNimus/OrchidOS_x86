; FONT.asm
; -- Draft the 4KiB needed for system fonts and characters in GUI mode.

MONOSPACE_FONT: ;Global tag used to reference the font masks table for the video driver.
; Font space starts from ASCII 32d (space) to ASCII 126d (~)
; -- A simple calculation into the index of the font is: Index = [ASCII val] - 32d

FONT_SPACE:
    .0:  db 00000000b
    .1:  db 00000000b
    .2:  db 00000000b
    .3:  db 00000000b
    .4:  db 00000000b
    .5:  db 00000000b
    .6:  db 00000000b
    .7:  db 00000000b
    .8:  db 00000000b
    .9:  db 00000000b
    .10: db 00000000b
    .11: db 00000000b
    .12: db 00000000b
    .13: db 00000000b
    .14: db 00000000b
    .15: db 00000000b

FONT_EXCLAMATION_MARK:
    .0:  db 00000000b
    .1:  db 00111000b
    .2:  db 00111000b
    .3:  db 00111000b
    .4:  db 00111000b
    .5:  db 00111000b
    .6:  db 00010000b
    .7:  db 00010000b
    .8:  db 00000000b
    .9:  db 00000000b
    .10: db 00111000b
    .11: db 00111000b
    .12: db 00111000b
    .13: db 00000000b
    .14: db 00000000b
    .15: db 00000000b

FONT_DOUBLE_QUOTES:
    .0:  db 00000000b
    .1:  db 00100010b
    .2:  db 01000100b
    .3:  db 01100110b
    .4:  db 01100110b
    .5:  db 00000000b
    .6:  db 00000000b
    .7:  db 00000000b
    .8:  db 00000000b
    .9:  db 00000000b
    .10: db 00000000b
    .11: db 00000000b
    .12: db 00000000b
    .13: db 00000000b
    .14: db 00000000b
    .15: db 00000000b

FONT_POUND_SIGN:
    .0:  db 00000000b
    .1:  db 00000000b
    .2:  db 00000000b
    .3:  db 01000100b
    .4:  db 01000100b
    .5:  db 11111110b
    .6:  db 11111110b
    .7:  db 01000100b
    .8:  db 01000100b
    .9:  db 11111110b
    .10: db 11111110b
    .11: db 01000100b
    .12: db 01000100b
    .13: db 00000000b
    .14: db 00000000b
    .15: db 00000000b

FONT_DOLLAR_SIGN:
    .0:  db 00000000b
    .1:  db 00010000b
    .2:  db 00010000b
    .3:  db 01111100b
    .4:  db 11010110b
    .5:  db 11010110b
    .6:  db 01110000b
    .7:  db 00111000b
    .8:  db 00011100b
    .9:  db 00010110b
    .10: db 11010110b
    .11: db 11010110b
    .12: db 01111100b
    .13: db 00111000b
    .14: db 00010000b
    .15: db 00000000b

FONT_PERCENT_SIGN:
    .0:  db 00000000b
    .1:  db 00000000b
    .2:  db 00000000b
    .3:  db 11100010b
    .4:  db 10100100b
    .5:  db 10101000b
    .6:  db 11101000b
    .7:  db 00010000b
    .8:  db 00011110b
    .9:  db 00101010b
    .10: db 00101010b
    .11: db 01001110b
    .12: db 10000000b
    .13: db 00000000b
    .14: db 00000000b
    .15: db 00000000b

FONT_AMPERSAND:
    .0:  db 00000000b
    .1:  db 00000000b
    .2:  db 00000000b
    .3:  db 01111000b
    .4:  db 11001100b
    .5:  db 11001100b
    .6:  db 01111100b
    .7:  db 01111000b
    .8:  db 11001100b
    .9:  db 11001110b
    .10: db 01100110b
    .11: db 01101110b
    .12: db 00111011b
    .13: db 00000000b
    .14: db 00000000b
    .15: db 00000000b

FONT_APOSTROPHE:
    .0:  db 00000000b
    .1:  db 00001000b
    .2:  db 00010000b
    .3:  db 00011000b
    .4:  db 00011000b
    .5:  db 00000000b
    .6:  db 00000000b
    .7:  db 00000000b
    .8:  db 00000000b
    .9:  db 00000000b
    .10: db 00000000b
    .11: db 00000000b
    .12: db 00000000b
    .13: db 00000000b
    .14: db 00000000b
    .15: db 00000000b

FONT_LEFT_PARENTHESIS:
    .0:  db 00000000b
    .1:  db 00000000b
    .2:  db 00000100b
    .3:  db 00001100b
    .4:  db 00011000b
    .5:  db 00110000b
    .6:  db 00110000b
    .7:  db 00110000b
    .8:  db 00110000b
    .9:  db 00110000b
    .10: db 00110000b
    .11: db 00011000b
    .12: db 00001100b
    .13: db 00000100b
    .14: db 00000000b
    .15: db 00000000b

FONT_RIGHT_PARENTHESIS:
    .0:  db 00000000b
    .1:  db 00000000b
    .2:  db 01000000b
    .3:  db 01100000b
    .4:  db 00110000b
    .5:  db 00011000b
    .6:  db 00011000b
    .7:  db 00011000b
    .8:  db 00011000b
    .9:  db 00011000b
    .10: db 00011000b
    .11: db 00110000b
    .12: db 01100000b
    .13: db 01000000b
    .14: db 00000000b
    .15: db 00000000b

FONT_ASTERISK:
    .0:  db 00000000b
    .1:  db 00000000b
    .2:  db 00010000b
    .3:  db 01010100b
    .4:  db 00111000b
    .5:  db 00111000b
    .6:  db 01000100b
    .7:  db 00000000b
    .8:  db 00000000b
    .9:  db 00000000b
    .10: db 00000000b
    .11: db 00000000b
    .12: db 00000000b
    .13: db 00000000b
    .14: db 00000000b
    .15: db 00000000b

FONT_PLUS:
    .0:  db 00000000b
    .1:  db 00000000b
    .2:  db 00000000b
    .3:  db 00000000b
    .4:  db 00000000b
    .5:  db 00000000b
    .6:  db 00011000b
    .7:  db 00011000b
    .8:  db 11111110b
    .9:  db 00011000b
    .10: db 00011000b
    .11: db 00000000b
    .12: db 00000000b
    .13: db 00000000b
    .14: db 00000000b
    .15: db 00000000b

FONT_COMMA:
    .0:  db 00000000b
    .1:  db 00000000b
    .2:  db 00000000b
    .3:  db 00000000b
    .4:  db 00000000b
    .5:  db 00000000b
    .6:  db 00000000b
    .7:  db 00000000b
    .8:  db 00000000b
    .9:  db 00000000b
    .10: db 00000000b
    .11: db 00011000b
    .12: db 00011000b
    .13: db 00001000b
    .14: db 00010000b
    .15: db 00000000b

FONT_MINUS:
FONT_HYPHEN:
    .0:  db 00000000b
    .1:  db 00000000b
    .2:  db 00000000b
    .3:  db 00000000b
    .4:  db 00000000b
    .5:  db 00000000b
    .6:  db 00000000b
    .7:  db 01111110b
    .8:  db 00000000b
    .9:  db 00000000b
    .10: db 00000000b
    .11: db 00000000b
    .12: db 00000000b
    .13: db 00000000b
    .14: db 00000000b
    .15: db 00000000b

FONT_PERIOD:
    .0:  db 00000000b
    .1:  db 00000000b
    .2:  db 00000000b
    .3:  db 00000000b
    .4:  db 00000000b
    .5:  db 00000000b
    .6:  db 00000000b
    .7:  db 00000000b
    .8:  db 00000000b
    .9:  db 00000000b
    .10: db 00000000b
    .11: db 00110000b
    .12: db 00110000b
    .13: db 00000000b
    .14: db 00000000b
    .15: db 00000000b

FONT_SLASH:
    .0:  db 00000000b
    .1:  db 00000000b
    .2:  db 00000000b
    .3:  db 00000010b
    .4:  db 00000110b
    .5:  db 00001100b
    .6:  db 00001100b
    .7:  db 00011000b
    .8:  db 00110000b
    .9:  db 01100000b
    .10: db 01100000b
    .11: db 11000000b
    .12: db 10000000b
    .13: db 00000000b
    .14: db 00000000b
    .15: db 00000000b

FONT_0:
    .0:  db 00000000b
    .1:  db 00000000b
    .2:  db 00000000b
    .3:  db 00111000b
    .4:  db 01101100b
    .5:  db 11000110b
    .6:  db 11001110b
    .7:  db 11010110b
    .8:  db 11010110b
    .9:  db 11010110b
    .10: db 11100110b
    .11: db 11000110b
    .12: db 01101100b
    .13: db 00111000b
    .14: db 00000000b
    .15: db 00000000b

FONT_1:
    .0:  db 00000000b
    .1:  db 00000000b
    .2:  db 00000000b
    .3:  db 00111000b
    .4:  db 01011000b
    .5:  db 00011000b
    .6:  db 00011000b
    .7:  db 00011000b
    .8:  db 00011000b
    .9:  db 00011000b
    .10: db 00011000b
    .11: db 10011010b
    .12: db 11111110b
    .13: db 00000000b
    .14: db 00000000b
    .15: db 00000000b

FONT_2:
    .0:  db 00000000b
    .1:  db 00000000b
    .2:  db 00000000b
    .3:  db 00111000b
    .4:  db 01101100b
    .5:  db 11000110b
    .6:  db 00000110b
    .7:  db 00001100b
    .8:  db 00011000b
    .9:  db 00110000b
    .10: db 01100000b
    .11: db 11000000b
    .12: db 11111110b
    .13: db 00000000b
    .14: db 00000000b
    .15: db 00000000b

FONT_3:
    .0:  db 00000000b
    .1:  db 00000000b
    .2:  db 00000000b
    .3:  db 00111000b
    .4:  db 01101100b
    .5:  db 11000110b
    .6:  db 00000110b
    .7:  db 00001100b
    .8:  db 00111000b
    .9:  db 00001100b
    .10: db 11000110b
    .11: db 01100110b
    .12: db 00111100b
    .13: db 00000000b
    .14: db 00000000b
    .15: db 00000000b

FONT_4:
    .0:  db 00000000b
    .1:  db 00000000b
    .2:  db 00000000b
    .3:  db 00001100b
    .4:  db 00011100b
    .5:  db 00110100b
    .6:  db 01100100b
    .7:  db 11000100b
    .8:  db 11111110b
    .9:  db 00000100b
    .10: db 00000100b
    .11: db 00000100b
    .12: db 00000100b
    .13: db 00000000b
    .14: db 00000000b
    .15: db 00000000b

FONT_5:
    .0:  db 00000000b
    .1:  db 00000000b
    .2:  db 00000000b
    .3:  db 11111110b
    .4:  db 11000000b
    .5:  db 11000000b
    .6:  db 11000000b
    .7:  db 11111100b
    .8:  db 10000110b
    .9:  db 00000110b
    .10: db 00000110b
    .11: db 11000110b
    .12: db 01111100b
    .13: db 00000000b
    .14: db 00000000b
    .15: db 00000000b

FONT_6:
    .0:  db 00000000b
    .1:  db 00000000b
    .2:  db 00000000b
    .3:  db 00000110b
    .4:  db 00001100b
    .5:  db 00011000b
    .6:  db 00110000b
    .7:  db 01111000b
    .8:  db 11001100b
    .9:  db 11000110b
    .10: db 11000110b
    .11: db 01100110b
    .12: db 00111100b
    .13: db 00000000b
    .14: db 00000000b
    .15: db 00000000b

FONT_7:
    .0:  db 00000000b
    .1:  db 00000000b
    .2:  db 00000000b
    .3:  db 11111110b
    .4:  db 00000110b
    .5:  db 00001100b
    .6:  db 00011000b
    .7:  db 00110000b
    .8:  db 01100000b
    .9:  db 01100000b
    .10: db 11000000b
    .11: db 11000000b
    .12: db 11000000b
    .13: db 00000000b
    .14: db 00000000b
    .15: db 00000000b

FONT_8:
    .0:  db 00000000b
    .1:  db 00000000b
    .2:  db 00000000b
    .3:  db 00111000b
    .4:  db 01101100b
    .5:  db 01101100b
    .6:  db 00111000b
    .7:  db 01101100b
    .8:  db 11000110b
    .9:  db 11000110b
    .10: db 11000110b
    .11: db 01101100b
    .12: db 00111000b
    .13: db 00000000b
    .14: db 00000000b
    .15: db 00000000b

FONT_9:
    .0:  db 00000000b
    .1:  db 00000000b
    .2:  db 00000000b
    .3:  db 00111100b
    .4:  db 11000110b
    .5:  db 11000110b
    .6:  db 01111110b
    .7:  db 00000110b
    .8:  db 00000110b
    .9:  db 00001100b
    .10: db 00001100b
    .11: db 00011000b
    .12: db 00110000b
    .13: db 00000000b
    .14: db 00000000b
    .15: db 00000000b

FONT_COLON:
    .0:  db 00000000b
    .1:  db 00000000b
    .2:  db 00000000b
    .3:  db 00000000b
    .4:  db 00000000b
    .5:  db 00011000b
    .6:  db 00011000b
    .7:  db 00000000b
    .8:  db 00000000b
    .9:  db 00011000b
    .10: db 00011000b
    .11: db 00000000b
    .12: db 00000000b
    .13: db 00000000b
    .14: db 00000000b
    .15: db 00000000b

FONT_SEMICOLON:
    .0:  db 00000000b
    .1:  db 00000000b
    .2:  db 00000000b
    .3:  db 00000000b
    .4:  db 00000000b
    .5:  db 00011000b
    .6:  db 00011000b
    .7:  db 00000000b
    .8:  db 00000000b
    .9:  db 00011000b
    .10: db 00011000b
    .11: db 00001000b
    .12: db 00010000b
    .13: db 00000000b
    .14: db 00000000b
    .15: db 00000000b

FONT_LEFT_ANGLE_BRACKET:
    .0:  db 00000000b
    .1:  db 00000000b
    .2:  db 00000000b
    .3:  db 00000000b
    .4:  db 00000000b
    .5:  db 00001100b
    .6:  db 00011000b
    .7:  db 00110000b
    .8:  db 00110000b
    .9:  db 00011000b
    .10: db 00001100b
    .11: db 00000000b
    .12: db 00000000b
    .13: db 00000000b
    .14: db 00000000b
    .15: db 00000000b

FONT_EQUAL_SIGN:
    .0:  db 00000000b
    .1:  db 00000000b
    .2:  db 00000000b
    .3:  db 00000000b
    .4:  db 00000000b
    .5:  db 00000000b
    .6:  db 00000000b
    .7:  db 01111110b
    .8:  db 00000000b
    .9:  db 00000000b
    .10: db 01111110b
    .11: db 00000000b
    .12: db 00000000b
    .13: db 00000000b
    .14: db 00000000b
    .15: db 00000000b

FONT_RIGHT_ANGLE_BRACKET:
    .0:  db 00000000b
    .1:  db 00000000b
    .2:  db 00000000b
    .3:  db 00000000b
    .4:  db 00000000b
    .5:  db 00000000b
    .6:  db 00110000b
    .7:  db 00011000b
    .8:  db 00001100b
    .9:  db 00001100b
    .10: db 00011000b
    .11: db 00110000b
    .12: db 00000000b
    .13: db 00000000b
    .14: db 00000000b
    .15: db 00000000b

FONT_QUESTION_MARK:
    .0:  db 00000000b
    .1:  db 00000000b
    .2:  db 00000000b
    .3:  db 00111100b
    .4:  db 01100110b
    .5:  db 00000110b
    .6:  db 00000110b
    .7:  db 00001100b
    .8:  db 00011000b
    .9:  db 00011000b
    .10: db 00000000b
    .11: db 00011000b
    .12: db 00011000b
    .13: db 00000000b
    .14: db 00000000b
    .15: db 00000000b

FONT_AT_SIGN:
    .0:  db 00000000b
    .1:  db 00000000b
    .2:  db 00000000b
    .3:  db 00111000b
    .4:  db 01000100b
    .5:  db 10000010b
    .6:  db 10111010b
    .7:  db 10101010b
    .8:  db 10101010b
    .9:  db 10111010b
    .10: db 10001100b
    .11: db 10000000b
    .12: db 01000100b
    .13: db 00111000b
    .14: db 00000000b
    .15: db 00000000b

FONT_A:
    .0:  db 00000000b
    .1:  db 00000000b
    .2:  db 00000000b
    .3:  db 00010000b
    .4:  db 00111000b
    .5:  db 01101100b
    .6:  db 11000110b
    .7:  db 11000110b
    .8:  db 11111110b
    .9:  db 11000110b
    .10: db 11000110b
    .11: db 11000110b
    .12: db 11000110b
    .13: db 00000000b
    .14: db 00000000b
    .15: db 00000000b

FONT_B:
    .0:  db 00000000b
    .1:  db 00000000b
    .2:  db 00000000b
    .3:  db 11111000b
    .4:  db 11001100b
    .5:  db 11001100b
    .6:  db 11011000b
    .7:  db 11110000b
    .8:  db 11111000b
    .9:  db 11011100b
    .10: db 11001110b
    .11: db 11011100b
    .12: db 11110000b
    .13: db 00000000b
    .14: db 00000000b
    .15: db 00000000b

FONT_C:
    .0:  db 00000000b
    .1:  db 00000000b
    .2:  db 00000000b
    .3:  db 00111000b
    .4:  db 01101100b
    .5:  db 11000110b
    .6:  db 11000000b
    .7:  db 11000000b
    .8:  db 11000000b
    .9:  db 11000000b
    .10: db 11000110b
    .11: db 01101100b
    .12: db 00111000b
    .13: db 00000000b
    .14: db 00000000b
    .15: db 00000000b

FONT_D:
    .0:  db 00000000b
    .1:  db 00000000b
    .2:  db 00000000b
    .3:  db 11110000b
    .4:  db 11011000b
    .5:  db 11001100b
    .6:  db 11000110b
    .7:  db 11000110b
    .8:  db 11000110b
    .9:  db 11000110b
    .10: db 11001100b
    .11: db 11011000b
    .12: db 11110000b
    .13: db 00000000b
    .14: db 00000000b
    .15: db 00000000b

FONT_E:
    .0:  db 00000000b
    .1:  db 00000000b
    .2:  db 00000000b
    .3:  db 11111110b
    .4:  db 11000000b
    .5:  db 11000000b
    .6:  db 11000000b
    .7:  db 11111000b
    .8:  db 11000000b
    .9:  db 11000000b
    .10: db 11000000b
    .11: db 11000000b
    .12: db 11111110b
    .13: db 00000000b
    .14: db 00000000b
    .15: db 00000000b

FONT_F:
    .0:  db 00000000b
    .1:  db 00000000b
    .2:  db 00000000b
    .3:  db 11111110b
    .4:  db 11000000b
    .5:  db 11000000b
    .6:  db 11000000b
    .7:  db 11111000b
    .8:  db 11000000b
    .9:  db 11000000b
    .10: db 11000000b
    .11: db 11000000b
    .12: db 11000000b
    .13: db 00000000b
    .14: db 00000000b
    .15: db 00000000b

FONT_G:
    .0:  db 00000000b
    .1:  db 00000000b
    .2:  db 00000000b
    .3:  db 01111000b
    .4:  db 11101100b
    .5:  db 11000110b
    .6:  db 11000000b
    .7:  db 11000000b
    .8:  db 11011110b
    .9:  db 11010110b
    .10: db 11000110b
    .11: db 11000110b
    .12: db 11111100b
    .13: db 00000000b
    .14: db 00000000b
    .15: db 00000000b

FONT_H:
    .0:  db 00000000b
    .1:  db 00000000b
    .2:  db 00000000b
    .3:  db 11000110b
    .4:  db 11000110b
    .5:  db 11000110b
    .6:  db 11000110b
    .7:  db 11111110b
    .8:  db 11111110b
    .9:  db 11000110b
    .10: db 11000110b
    .11: db 11000110b
    .12: db 11000110b
    .13: db 00000000b
    .14: db 00000000b
    .15: db 00000000b

FONT_I:
    .0:  db 00000000b
    .1:  db 00000000b
    .2:  db 00000000b
    .3:  db 11111110b
    .4:  db 11111110b
    .5:  db 00010000b
    .6:  db 00010000b
    .7:  db 00010000b
    .8:  db 00010000b
    .9:  db 00010000b
    .10: db 00010000b
    .11: db 11111110b
    .12: db 11111110b
    .13: db 00000000b
    .14: db 00000000b
    .15: db 00000000b

FONT_J:
    .0:  db 00000000b
    .1:  db 00000000b
    .2:  db 00000000b
    .3:  db 11111110b
    .4:  db 11111110b
    .5:  db 00011000b
    .6:  db 00011000b
    .7:  db 00011000b
    .8:  db 00011000b
    .9:  db 01011000b
    .10: db 11011000b
    .11: db 11011000b
    .12: db 01110000b
    .13: db 00000000b
    .14: db 00000000b
    .15: db 00000000b

FONT_K:
    .0:  db 00000000b
    .1:  db 00000000b
    .2:  db 00000000b
    .3:  db 11000110b
    .4:  db 11001100b
    .5:  db 11011000b
    .6:  db 11110000b
    .7:  db 11011000b
    .8:  db 11001100b
    .9:  db 11001100b
    .10: db 11000110b
    .11: db 11000110b
    .12: db 11000110b
    .13: db 00000000b
    .14: db 00000000b
    .15: db 00000000b

FONT_L:
    .0:  db 00000000b
    .1:  db 00000000b
    .2:  db 00000000b
    .3:  db 11100000b
    .4:  db 11000000b
    .5:  db 11000000b
    .6:  db 11000000b
    .7:  db 11000000b
    .8:  db 11000000b
    .9:  db 11000000b
    .10: db 11000010b
    .11: db 11111110b
    .12: db 11111110b
    .13: db 00000000b
    .14: db 00000000b
    .15: db 00000000b

FONT_M:
    .0:  db 00000000b
    .1:  db 00000000b
    .2:  db 00000000b
    .3:  db 11101110b
    .4:  db 10111010b
    .5:  db 10111010b
    .6:  db 10111010b
    .7:  db 10111010b
    .8:  db 10010010b
    .9:  db 10000010b
    .10: db 10000010b
    .11: db 10000010b
    .12: db 10000010b
    .13: db 00000000b
    .14: db 00000000b
    .15: db 00000000b

FONT_N:
    .0:  db 00000000b
    .1:  db 00000000b
    .2:  db 00000000b
    .3:  db 11000110b
    .4:  db 11100110b
    .5:  db 11110110b
    .6:  db 11010110b
    .7:  db 11010110b
    .8:  db 11010110b
    .9:  db 11010110b
    .10: db 11011110b
    .11: db 11001110b
    .12: db 11000110b
    .13: db 00000000b
    .14: db 00000000b
    .15: db 00000000b

FONT_O:
    .0:  db 00000000b
    .1:  db 00000000b
    .2:  db 00000000b
    .3:  db 00111000b
    .4:  db 01111100b
    .5:  db 01101100b
    .6:  db 11000110b
    .7:  db 11000110b
    .8:  db 11000110b
    .9:  db 11000110b
    .10: db 01101100b
    .11: db 01111100b
    .12: db 00111000b
    .13: db 00000000b
    .14: db 00000000b
    .15: db 00000000b

FONT_P:
    .0:  db 00000000b
    .1:  db 00000000b
    .2:  db 00000000b
    .3:  db 11111100b
    .4:  db 11000110b
    .5:  db 11000110b
    .6:  db 11111100b
    .7:  db 11000000b
    .8:  db 11000000b
    .9:  db 11000000b
    .10: db 11000000b
    .11: db 11000000b
    .12: db 11000000b
    .13: db 00000000b
    .14: db 00000000b
    .15: db 00000000b

FONT_Q:
    .0:  db 00000000b
    .1:  db 00000000b
    .2:  db 00000000b
    .3:  db 00111000b
    .4:  db 01111100b
    .5:  db 11000110b
    .6:  db 11000110b
    .7:  db 11000110b
    .8:  db 11010110b
    .9:  db 11011110b
    .10: db 11001110b
    .11: db 01101110b
    .12: db 00111010b
    .13: db 00000011b
    .14: db 00000000b
    .15: db 00000000b

FONT_R:
    .0:  db 00000000b
    .1:  db 00000000b
    .2:  db 00000000b
    .3:  db 11111100b
    .4:  db 11000110b
    .5:  db 11000110b
    .6:  db 11111100b
    .7:  db 11100000b
    .8:  db 11110000b
    .9:  db 11011000b
    .10: db 11001100b
    .11: db 11000110b
    .12: db 11000110b
    .13: db 00000000b
    .14: db 00000000b
    .15: db 00000000b

FONT_S:
    .0:  db 00000000b
    .1:  db 00000000b
    .2:  db 00000000b
    .3:  db 00111000b
    .4:  db 01101100b
    .5:  db 11000110b
    .6:  db 01100000b
    .7:  db 00110000b
    .8:  db 00011000b
    .9:  db 00001100b
    .10: db 11000110b
    .11: db 01101100b
    .12: db 00111000b
    .13: db 00000000b
    .14: db 00000000b
    .15: db 00000000b

FONT_T:
    .0:  db 00000000b
    .1:  db 00000000b
    .2:  db 00000000b
    .3:  db 11111110b
    .4:  db 11111110b
    .5:  db 00010000b
    .6:  db 00010000b
    .7:  db 00010000b
    .8:  db 00010000b
    .9:  db 00010000b
    .10: db 00010000b
    .11: db 00010000b
    .12: db 00010000b
    .13: db 00000000b
    .14: db 00000000b
    .15: db 00000000b

FONT_U:
    .0:  db 00000000b
    .1:  db 00000000b
    .2:  db 00000000b
    .3:  db 11000110b
    .4:  db 11000110b
    .5:  db 11000110b
    .6:  db 11000110b
    .7:  db 11000110b
    .8:  db 11000110b
    .9:  db 11000110b
    .10: db 11000110b
    .11: db 11000110b
    .12: db 11000110b
    .13: db 01111100b
    .14: db 00000000b
    .15: db 00000000b

FONT_V:
    .0:  db 00000000b
    .1:  db 00000000b
    .2:  db 00000000b
    .3:  db 11000110b
    .4:  db 11000110b
    .5:  db 11000110b
    .6:  db 11000110b
    .7:  db 11000110b
    .8:  db 11000110b
    .9:  db 11101110b
    .10: db 01111100b
    .11: db 00111000b
    .12: db 00010000b
    .13: db 00000000b
    .14: db 00000000b
    .15: db 00000000b

FONT_W:
    .0:  db 00000000b
    .1:  db 00000000b
    .2:  db 00000000b
    .3:  db 11000110b
    .4:  db 11000110b
    .5:  db 11000110b
    .6:  db 11000110b
    .7:  db 11000110b
    .8:  db 01000100b
    .9:  db 01010100b
    .10: db 01111100b
    .11: db 01101100b
    .12: db 01101100b
    .13: db 00000000b
    .14: db 00000000b
    .15: db 00000000b

FONT_X:
    .0:  db 00000000b
    .1:  db 00000000b
    .2:  db 00000000b
    .3:  db 11000110b
    .4:  db 11000110b
    .5:  db 11000110b
    .6:  db 01101100b
    .7:  db 00111000b
    .8:  db 01101100b
    .9:  db 11000110b
    .10: db 11000110b
    .11: db 11000110b
    .12: db 11000110b
    .13: db 00000000b
    .14: db 00000000b
    .15: db 00000000b

FONT_Y:
    .0:  db 00000000b
    .1:  db 00000000b
    .2:  db 00000000b
    .3:  db 11000110b
    .4:  db 11000110b
    .5:  db 11000110b
    .6:  db 01111100b
    .7:  db 00111000b
    .8:  db 00010000b
    .9:  db 00010000b
    .10: db 00010000b
    .11: db 00010000b
    .12: db 00010000b
    .13: db 00000000b
    .14: db 00000000b
    .15: db 00000000b

FONT_Z:
    .0:  db 00000000b
    .1:  db 00000000b
    .2:  db 00000000b
    .3:  db 11111110b
    .4:  db 00000110b
    .5:  db 00001100b
    .6:  db 00001100b
    .7:  db 00011000b
    .8:  db 00110000b
    .9:  db 01100000b
    .10: db 01100000b
    .11: db 11000000b
    .12: db 11111110b
    .13: db 00000000b
    .14: db 00000000b
    .15: db 00000000b

FONT_LEFT_BRACKET:
    .0:  db 00000000b
    .1:  db 00000000b
    .2:  db 00000000b
    .3:  db 00111110b
    .4:  db 00110000b
    .5:  db 00110000b
    .6:  db 00110000b
    .7:  db 00110000b
    .8:  db 00110000b
    .9:  db 00110000b
    .10: db 00110000b
    .11: db 00110000b
    .12: db 00111110b
    .13: db 00000000b
    .14: db 00000000b
    .15: db 00000000b

FONT_BACKSLASH:
    .0:  db 00000000b
    .1:  db 00000000b
    .2:  db 00000000b
    .3:  db 11000000b
    .4:  db 01100000b
    .5:  db 00110000b
    .6:  db 00110000b
    .7:  db 00011000b
    .8:  db 00011000b
    .9:  db 00011000b
    .10: db 00001100b
    .11: db 00001100b
    .12: db 00000110b
    .13: db 00000000b
    .14: db 00000000b
    .15: db 00000000b

FONT_RIGHT_BRACKET:
    .0:  db 00000000b
    .1:  db 00000000b
    .2:  db 00000000b
    .3:  db 01111100b
    .4:  db 00001100b
    .5:  db 00001100b
    .6:  db 00001100b
    .7:  db 00001100b
    .8:  db 00001100b
    .9:  db 00001100b
    .10: db 00001100b
    .11: db 00001100b
    .12: db 01111100b
    .13: db 00000000b
    .14: db 00000000b
    .15: db 00000000b

FONT_CARET:
    .0:  db 00000000b
    .1:  db 00000000b
    .2:  db 00011000b
    .3:  db 00111100b
    .4:  db 01100110b
    .5:  db 11000011b
    .6:  db 00000000b
    .7:  db 00000000b
    .8:  db 00000000b
    .9:  db 00000000b
    .10: db 00000000b
    .11: db 00000000b
    .12: db 00000000b
    .13: db 00000000b
    .14: db 00000000b
    .15: db 00000000b

FONT_UNDERSCORE:
    .0:  db 00000000b
    .1:  db 00000000b
    .2:  db 00000000b
    .3:  db 00000000b
    .4:  db 00000000b
    .5:  db 00000000b
    .6:  db 00000000b
    .7:  db 00000000b
    .8:  db 00000000b
    .9:  db 00000000b
    .10: db 00000000b
    .11: db 00000000b
    .12: db 01111110b
    .13: db 00000000b
    .14: db 00000000b
    .15: db 00000000b

FONT_GRAVE_ACCENT:
    .0:  db 00000000b
    .1:  db 01100000b
    .2:  db 00110000b
    .3:  db 00011100b
    .4:  db 00000110b
    .5:  db 00000000b
    .6:  db 00000000b
    .7:  db 00000000b
    .8:  db 00000000b
    .9:  db 00000000b
    .10: db 00000000b
    .11: db 00000000b
    .12: db 00000000b
    .13: db 00000000b
    .14: db 00000000b
    .15: db 00000000b

FONT_a:
    .0:  db 00000000b
    .1:  db 00000000b
    .2:  db 00000000b
    .3:  db 00000000b
    .4:  db 00000000b
    .5:  db 00000000b
    .6:  db 00011100b
    .7:  db 00110110b
    .8:  db 00000110b
    .19: db 01111110b
    .10: db 01100110b
    .11: db 11000110b
    .12: db 01111111b
    .13: db 00000000b
    .14: db 00000000b
    .15: db 00000000b

FONT_b:
    .0:  db 00000000b
    .1:  db 00000000b
    .2:  db 00000000b
    .3:  db 11000000b
    .4:  db 11000000b
    .5:  db 11000000b
    .6:  db 11000000b
    .7:  db 11000000b
    .8:  db 11111000b
    .9:  db 11001100b
    .10: db 11000110b
    .11: db 11100110b
    .12: db 11011100b
    .13: db 00000000b
    .14: db 00000000b
    .15: db 00000000b

FONT_c:
    .0:  db 00000000b
    .1:  db 00000000b
    .2:  db 00000000b
    .3:  db 00000000b
    .4:  db 00000000b
    .5:  db 00000000b
    .6:  db 00000000b
    .7:  db 00000000b
    .8:  db 00111100b
    .9:  db 01100110b
    .10: db 11000000b
    .11: db 11000000b
    .12: db 01100110b
    .13: db 00111100b
    .14: db 00000000b
    .15: db 00000000b

FONT_d:
    .0:  db 00000000b
    .1:  db 00000000b
    .2:  db 00000000b
    .3:  db 00000110b
    .4:  db 00000110b
    .5:  db 00000110b
    .6:  db 00000110b
    .7:  db 00000110b
    .8:  db 00000110b
    .9:  db 00111110b
    .10: db 01100110b
    .11: db 11000110b
    .12: db 11001110b
    .13: db 01110110b
    .14: db 00000000b
    .15: db 00000000b

FONT_e:
    .0:  db 00000000b
    .1:  db 00000000b
    .2:  db 00000000b
    .3:  db 00000000b
    .4:  db 00000000b
    .5:  db 00000000b
    .6:  db 00000000b
    .7:  db 00000000b
    .8:  db 00111100b
    .9:  db 01100110b
    .10: db 01111110b
    .11: db 01100000b
    .12: db 01100110b
    .13: db 00111100b
    .14: db 00000000b
    .15: db 00000000b

FONT_f:
    .0:  db 00000000b
    .1:  db 00000000b
    .2:  db 00000000b
    .3:  db 00011100b
    .4:  db 00110010b
    .5:  db 00110010b
    .6:  db 00110000b
    .7:  db 00110000b
    .8:  db 01111000b
    .9:  db 00110000b
    .10: db 00110000b
    .11: db 00110000b
    .12: db 00110000b
    .13: db 00000000b
    .14: db 00000000b
    .15: db 00000000b

FONT_g:
    .0:  db 00000000b
    .1:  db 00000000b
    .2:  db 00000000b
    .3:  db 00000000b
    .4:  db 00000000b
    .5:  db 00000000b
    .6:  db 00000000b
    .7:  db 00000000b
    .8:  db 00111110b
    .9:  db 01100110b
    .10: db 01100110b
    .11: db 00111110b
    .12: db 00000110b
    .13: db 01100110b
    .14: db 00111100b
    .15: db 00000000b

FONT_h:
    .0:  db 00000000b
    .1:  db 00000000b
    .2:  db 00000000b
    .3:  db 11000000b
    .4:  db 11000000b
    .5:  db 11000000b
    .6:  db 11000000b
    .7:  db 11000000b
    .8:  db 11011110b
    .9:  db 11110110b
    .10: db 11100110b
    .11: db 11000110b
    .12: db 11000110b
    .13: db 00000000b
    .14: db 00000000b
    .15: db 00000000b

FONT_i:
    .0:  db 00000000b
    .1:  db 00000000b
    .2:  db 00000000b
    .3:  db 00011000b
    .4:  db 00011000b
    .5:  db 00000000b
    .6:  db 00000000b
    .7:  db 00011000b
    .8:  db 00011000b
    .9:  db 00011000b
    .10: db 00011000b
    .11: db 00011000b
    .12: db 00011000b
    .13: db 00000000b
    .14: db 00000000b
    .15: db 00000000b

FONT_j:
    .0:  db 00000000b
    .1:  db 00000000b
    .2:  db 00000000b
    .3:  db 00001100b
    .4:  db 00001100b
    .5:  db 00000000b
    .6:  db 00000000b
    .7:  db 00001100b
    .8:  db 00001100b
    .9:  db 00001100b
    .10: db 00001100b
    .11: db 00001100b
    .12: db 11001100b
    .13: db 11001100b
    .14: db 01111000b
    .15: db 00000000b

FONT_k:
    .0:  db 00000000b
    .1:  db 00000000b
    .2:  db 00000000b
    .3:  db 11000000b
    .4:  db 11000000b
    .5:  db 11000000b
    .6:  db 11011000b
    .7:  db 11011000b
    .8:  db 11110000b
    .9:  db 11110000b
    .10: db 11011000b
    .11: db 11001100b
    .12: db 11001100b
    .13: db 00000000b
    .14: db 00000000b
    .15: db 00000000b

FONT_l:
    .0:  db 00000000b
    .1:  db 00000000b
    .2:  db 00000000b
    .3:  db 00111000b
    .4:  db 00011000b
    .5:  db 00011000b
    .6:  db 00011000b
    .7:  db 00011000b
    .8:  db 00011000b
    .9:  db 00011000b
    .10: db 00011000b
    .11: db 00011000b
    .12: db 00111100b
    .13: db 00000000b
    .14: db 00000000b
    .15: db 00000000b

FONT_m:
    .0:  db 00000000b
    .1:  db 00000000b
    .2:  db 00000000b
    .3:  db 00000000b
    .4:  db 00000000b
    .5:  db 00000000b
    .6:  db 00000000b
    .7:  db 00000000b
    .8:  db 10101100b
    .9:  db 11010010b
    .10: db 10010010b
    .11: db 10010010b
    .12: db 10010010b
    .13: db 00000000b
    .14: db 00000000b
    .15: db 00000000b

FONT_n:
    .0:  db 00000000b
    .1:  db 00000000b
    .2:  db 00000000b
    .3:  db 00000000b
    .4:  db 00000000b
    .5:  db 00000000b
    .6:  db 00000000b
    .7:  db 00000000b
    .8:  db 11011100b
    .9:  db 11100010b
    .10: db 11000010b
    .11: db 11000010b
    .12: db 11000010b
    .13: db 00000000b
    .14: db 00000000b
    .15: db 00000000b

FONT_o:
    .0:  db 00000000b
    .1:  db 00000000b
    .2:  db 00000000b
    .3:  db 00000000b
    .4:  db 00000000b
    .5:  db 00000000b
    .6:  db 00000000b
    .7:  db 00000000b
    .8:  db 00111100b
    .9:  db 01100110b
    .10: db 01100110b
    .11: db 01100110b
    .12: db 00111100b
    .13: db 00000000b
    .14: db 00000000b
    .15: db 00000000b

FONT_p:
    .0:  db 00000000b
    .1:  db 00000000b
    .2:  db 00000000b
    .3:  db 00000000b
    .4:  db 00000000b
    .5:  db 00000000b
    .6:  db 00000000b
    .7:  db 00000000b
    .8:  db 01111100b
    .9:  db 01100110b
    .10: db 01100110b
    .11: db 01111100b
    .12: db 01100000b
    .13: db 01100000b
    .14: db 01100000b
    .15: db 01100000b

FONT_q:
    .0:  db 00000000b
    .1:  db 00000000b
    .2:  db 00000000b
    .3:  db 00000000b
    .4:  db 00000000b
    .5:  db 00000000b
    .6:  db 00000000b
    .7:  db 00000000b
    .8:  db 00111110b
    .9:  db 01100110b
    .10: db 01100110b
    .11: db 00111110b
    .12: db 00000110b
    .13: db 00000110b
    .14: db 00000111b
    .15: db 00000110b

FONT_r:
    .0:  db 00000000b
    .1:  db 00000000b
    .2:  db 00000000b
    .3:  db 00000000b
    .4:  db 00000000b
    .5:  db 00000000b
    .6:  db 00000000b
    .7:  db 00000000b
    .8:  db 11011100b
    .9:  db 11100110b
    .10: db 11000000b
    .11: db 11000000b
    .12: db 11000000b
    .13: db 00000000b
    .14: db 00000000b
    .15: db 00000000b

FONT_s:
    .0:  db 00000000b
    .1:  db 00000000b
    .2:  db 00000000b
    .3:  db 00000000b
    .4:  db 00000000b
    .5:  db 00000000b
    .6:  db 00000000b
    .7:  db 00000000b
    .8:  db 00111100b
    .9:  db 01100010b
    .10: db 00110000b
    .11: db 00001100b
    .12: db 01000110b
    .13: db 00111100b
    .14: db 00000000b
    .15: db 00000000b

FONT_t:
    .0:  db 00000000b
    .1:  db 00000000b
    .2:  db 00000000b
    .3:  db 00011000b
    .4:  db 00011000b
    .5:  db 00011000b
    .6:  db 00111100b
    .7:  db 00111100b
    .8:  db 00011000b
    .9:  db 00011000b
    .10: db 00011010b
    .11: db 00011110b
    .12: db 00011110b
    .13: db 00000000b
    .14: db 00000000b
    .15: db 00000000b

FONT_u:
    .0:  db 00000000b
    .1:  db 00000000b
    .2:  db 00000000b
    .3:  db 00000000b
    .4:  db 00000000b
    .5:  db 00000000b
    .6:  db 00000000b
    .7:  db 00000000b
    .8:  db 01100110b
    .9:  db 01100110b
    .10: db 01100110b
    .11: db 01100110b
    .12: db 00111110b
    .13: db 00000000b
    .14: db 00000000b
    .15: db 00000000b

FONT_v:
    .0:  db 00000000b
    .1:  db 00000000b
    .2:  db 00000000b
    .3:  db 00000000b
    .4:  db 00000000b
    .5:  db 00000000b
    .6:  db 00000000b
    .7:  db 00000000b
    .8:  db 01100110b
    .9:  db 01100110b
    .10: db 00111100b
    .11: db 00111100b
    .12: db 00011000b
    .13: db 00000000b
    .14: db 00000000b
    .15: db 00000000b

FONT_w:
    .0:  db 00000000b
    .1:  db 00000000b
    .2:  db 00000000b
    .3:  db 00000000b
    .4:  db 00000000b
    .5:  db 00000000b
    .6:  db 00000000b
    .7:  db 00000000b
    .8:  db 01000010b
    .9:  db 01000010b
    .10: db 01011010b
    .11: db 01011010b
    .12: db 00100100b
    .13: db 00000000b
    .14: db 00000000b
    .15: db 00000000b

FONT_x:
    .0:  db 00000000b
    .1:  db 00000000b
    .2:  db 00000000b
    .3:  db 00000000b
    .4:  db 00000000b
    .5:  db 00000000b
    .6:  db 00000000b
    .7:  db 00000000b
    .8:  db 01000010b
    .9:  db 00100100b
    .10: db 00011000b
    .11: db 00100100b
    .12: db 01000010b
    .13: db 00000000b
    .14: db 00000000b
    .15: db 00000000b

FONT_y:
    .0:  db 00000000b
    .1:  db 00000000b
    .2:  db 00000000b
    .3:  db 00000000b
    .4:  db 00000000b
    .5:  db 00000000b
    .6:  db 00000000b
    .7:  db 00000000b
    .8:  db 01100110b
    .9:  db 01100110b
    .10: db 01100110b
    .11: db 00111110b
    .12: db 00000110b
    .13: db 01100110b
    .14: db 01100110b
    .15: db 00111100b

FONT_z:
    .0:  db 00000000b
    .1:  db 00000000b
    .2:  db 00000000b
    .3:  db 00000000b
    .4:  db 00000000b
    .5:  db 00000000b
    .6:  db 00000000b
    .7:  db 00000000b
    .8:  db 01111110b
    .9:  db 00000110b
    .10: db 00011000b
    .11: db 01100000b
    .12: db 01111110b
    .13: db 00000000b
    .14: db 00000000b
    .15: db 00000000b

FONT_LEFT_BRACE:
    .0:  db 00000000b
    .1:  db 00000000b
    .2:  db 00000100b
    .3:  db 00001100b
    .4:  db 00001100b
    .5:  db 00001100b
    .6:  db 00011000b
    .7:  db 00110000b
    .8:  db 00110000b
    .9:  db 00011000b
    .10: db 00001100b
    .11: db 00001100b
    .12: db 00001100b
    .13: db 00000100b
    .14: db 00000000b
    .15: db 00000000b

FONT_PIPE:
    .0:  db 00000000b
    .1:  db 00011000b
    .2:  db 00011000b
    .3:  db 00011000b
    .4:  db 00011000b
    .5:  db 00011000b
    .6:  db 00011000b
    .7:  db 00011000b
    .8:  db 00011000b
    .9:  db 00011000b
    .10: db 00011000b
    .11: db 00011000b
    .12: db 00011000b
    .13: db 00011000b
    .14: db 00011000b
    .15: db 00000000b

FONT_RIGHT_BRACE:
    .0:  db 00000000b
    .1:  db 00000000b
    .2:  db 00100000b
    .3:  db 00110000b
    .4:  db 00110000b
    .5:  db 00110000b
    .6:  db 00011000b
    .7:  db 00001100b
    .8:  db 00001100b
    .9:  db 00011000b
    .10: db 00110000b
    .11: db 00110000b
    .12: db 00110000b
    .13: db 00100000b
    .14: db 00000000b
    .15: db 00000000b

FONT_TILDE:
    .0:  db 00000000b
    .1:  db 00000000b
    .2:  db 00000000b
    .3:  db 00000000b
    .4:  db 00000000b
    .5:  db 00000000b
    .6:  db 00000000b
    .7:  db 00110010b
    .8:  db 01001100b
    .9:  db 00000000b
    .10: db 00000000b
    .11: db 00000000b
    .12: db 00000000b
    .13: db 00000000b
    .14: db 00000000b
    .15: db 00000000b


; INPUTS:
;   ARG1 = Location of start output.
;   ARG2 = Base Ptr of String
;   ARG3 = Foreground Color
;   ARG4 = Background Color
; -- Write a string of ASCII characters to the screen, given it is within the printable range (32d-126d)
; == DEPs:
; ==== VIDEO_OUTPUT_CHAR(Startpos, (uint32) index into MONOSPACE_FONT, fgColor, bgColor)
VIDEO_WRITE_STRING_CURRENT_CHARACTER_COORDS dd 0x00000000
VIDEO_WRITE_STRING:
    push ebp
    mov ebp, esp
    pushad

    xor eax, eax    ; clear EAX
    xor ecx, ecx    ; clear ECX
    mov ebx, dword [ebp+8]      ; EBX = arg1 = starting coords (y<<16|x)
    mov esi, dword [ebp+12]  ; ESI = arg2 = base of string

 .getChars:
    lodsb   ; AL = byte [ESI]; ESI++
    or al, al   ; null-terminator?
    jz .leaveCall
    cmp al, 126 ; char > 126 ASCII?
    jg .unknownChar
    cmp al, 32  ; < 32 ASCII
    jl .unknownChar

    ; Check the coordinates for validity...
    push ecx ; save regs that get altered
    movzx ecx, word [SCREEN_HEIGHT]   ; Get screen height val
    shl ecx, 16 ; ECX high WORD = Max Y
    mov cx, word [SCREEN_WIDTH] ; Get screen width val
    call VIDEO_checkCoordinates ;(ECX = end coord, EBX = base coord [looking to check this mainly])
    jc .badCoord    ; if bad coord, leave
    pop ecx ;restore

    sub al, 32  ; chop off the char to get index into font table
    and eax, 0x000000FF     ; AL only.

    push dword [ebp+20] ; pass bgColor
    push dword [ebp+16] ; pass fgColor
    push dword eax      ; pass index into font table
    push dword ebx      ; pass coords of print.
    call VIDEO_OUTPUT_CHAR
    add esp, 16

    add bx, 8   ; add 8 pixels to the x coord.
    jmp .getChars

 .unknownChar:
    ; print ?
 .badCoord:
 .leaveCall:
    popad
    pop ebp
    ret



; INPUTS:
;   ARG1 = Start (top-left position) (Y<<16|X)
;   ARG2 = Character (index into MONOSPACE_FONT table)
;   ARG3 = Foreground Color
;   ARG4 = Background Color
; -- Draws a character based on foreground & background color.
; == DEPs:
; ==== VIDEO_putPixel; EBX = coord location, EAX = color of pixel
VIDEO_OUTPUT_CHAR_CURRENT_PIXEL_COORDS dd 0x00000000
VIDEO_OUTPUT_CHAR:
    push ebp
    mov ebp, esp
    pushad

    mov edx, dword [ebp+8] ; arg1 - set starting point
    mov dword [VIDEO_OUTPUT_CHAR_CURRENT_PIXEL_COORDS], edx
    mov edx, dword [ebp+12] ; arg2 - which char
    shl edx, 4  ; EDX *= 16
    add edx, MONOSPACE_FONT ; add system font table base to get start of character bitmap
    mov esi, edx    ; ESI = 16-byte font character bitmap entry.

    xor ecx, ecx    ; ECX = 0
    xor ebx, ebx    ; EBX = 0
    xor edx, edx    ; EDX = 0
    xor eax, eax    ; EAX = 0

 .getNextRow:
    lodsb       ; AL = [ESI], ESI++
    mov bl, 0x80    ; BL = 10000000b
    push ecx    ; save ECX (meta-loop counter)
    xor ecx, ecx    ; set it to 0 for sub-counting
 .drawRow:
    push eax    ; save AL
    push ebx    ; save BL
    and al, bl  ; and AL w/ BL. If AL comes out a 0, it's a background bit on the bitmap
    mov ebx, dword [VIDEO_OUTPUT_CHAR_CURRENT_PIXEL_COORDS] ; EBX = pixel coord

    or al, al
    jnz .foregroundColor

   .backgroundColor:
    mov eax, dword [ebp+20] ;EAX = arg4 - bg color
    jmp .drawPixel
   .foregroundColor:
    mov eax, dword [ebp+16] ;EAX = arg3 - fg color
   .drawPixel:
    push eax
    push ebx
    call VIDEO_putPixel
    add esp, 8

    ; prepare for next iteration...
    pop ebx     ; restore ebx (BL)
    shr bl, 1   ; move to the next bit of the bitmap.
    mov eax, dword [VIDEO_OUTPUT_CHAR_CURRENT_PIXEL_COORDS]
    inc eax     ; add to the X coord
    mov dword [VIDEO_OUTPUT_CHAR_CURRENT_PIXEL_COORDS], eax ; put it back
    pop eax     ; restore AL
    inc ecx     ; increment counter
    cmp ecx, 8  ; check that whole byte of bitmap was checked/entered
    jae .doneRow    ; if count > 8, next row
    jmp .drawRow    ; else continue

 .doneRow:
    push eax ;save
    mov eax, dword [VIDEO_OUTPUT_CHAR_CURRENT_PIXEL_COORDS]
    sub eax, 8  ; go back 8 pixels in X direction
    add eax, 0x00010000 ; add 1 in the high WORD (Y coord)
    mov dword [VIDEO_OUTPUT_CHAR_CURRENT_PIXEL_COORDS], eax
    pop eax ;restore

    ; Retrieve and increment counter, check if it's run 16 times.
    pop ecx
    inc ecx
    cmp ecx, 16
    jae .leaveCall
    jmp .getNextRow

 .leaveCall:
    popad
    pop ebp
    ret
