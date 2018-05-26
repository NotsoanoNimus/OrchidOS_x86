; MD5_GUTS.asm
; -- Interal computation functions for the MD5 hash algorithm.


; Define the 64-element table, where for each index i, do MD5_T[i] = HEX(4294967296 * abs(sin_rad(i))).
MD5_INTERNAL_KEY_TABLE_T:
  .1: dd 0xD76AA478
  .2: dd 0xE8C7B756
  .3: dd 0x242070DB
  .4: dd 0xC1BDCEEE
  .5: dd 0xF57C0FAF
  .6: dd 0x4787C62A
  .7: dd 0xA8304613
  .8: dd 0xFD469501
  .9: dd 0x698098D8
 .10: dd 0x8B44F7AF
 .11: dd 0xFFFF5BB1
 .12: dd 0x895CD7BE
 .13: dd 0x6B901122
 .14: dd 0xFD987193
 .15: dd 0xA679438E
 .16: dd 0x49B40821
 .17: dd 0xF61E2562
 .18: dd 0xC040B340
 .19: dd 0x265E5A51
 .20: dd 0xE9B6C7AA
 .21: dd 0xD62F105D
 .22: dd 0x02441453
 .23: dd 0xD8A1E681
 .24: dd 0xE7D3FBC8
 .25: dd 0x21E1CDE6
 .26: dd 0xC33707D6
 .27: dd 0xF4D50D87
 .28: dd 0x455A14ED
 .29: dd 0xA9E3E905
 .30: dd 0xFCEFA3F8
 .31: dd 0x676F02D9
 .32: dd 0x8D2A4C8A
 .33: dd 0xFFFA3942
 .34: dd 0x8771F681
 .35: dd 0x699D6122
 .36: dd 0xFDE5380C
 .37: dd 0xA4BEEA44
 .38: dd 0x4BDECFA9
 .39: dd 0xF6BB4B60
 .40: dd 0xBEBFBC70
 .41: dd 0x289B7EC6
 .42: dd 0xEAA127FA
 .43: dd 0xD4EF3085
 .44: dd 0x04881D05
 .45: dd 0xD9D4D039
 .46: dd 0xE6DB99E5
 .47: dd 0x1FA27CF8
 .48: dd 0xC4AC5665
 .49: dd 0xF4292244
 .50: dd 0x432AFF97
 .51: dd 0xAB9423A7
 .52: dd 0xFC93A039
 .53: dd 0x655B59C3
 .54: dd 0x8F0CCC92
 .55: dd 0xFFEFF47D
 .56: dd 0x85845DD1
 .57: dd 0x6FA87E4F
 .58: dd 0xFE2CE6E0
 .59: dd 0xA3014314
 .60: dd 0x4E0811A1
 .61: dd 0xF7537E82
 .62: dd 0xBD3AF235
 .63: dd 0x2AD7D2BB
 .64: dd 0xEB86D391


; F(X,Y,Z) = (X & Y) | (~X & Z)
MD5_INTERNAL_F:
	FunctionSetup

 .leaveCall:
 	FunctionLeave


; G(X,Y,Z) = (X & Y) | (Y & ~Z)
MD5_INTERNAL_G:
	FunctionSetup

 .leaveCall:
 	FunctionLeave


; H(X,Y,Z) = X xor Y xor Z
MD5_INTERNAL_H:
	FunctionSetup

 .leaveCall:
 	FunctionLeave


; I(X,Y,Z) = Y xor (X | ~Z)
MD5_INTERNAL_I:
	FunctionSetup

 .leaveCall:
 	FunctionLeave
