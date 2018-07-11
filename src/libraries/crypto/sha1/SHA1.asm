; SHA1.asm
; -- Implementation of SHA1 wrapper functions.

; Include the internal SHA1 functions.
%include "libraries/crypto/sha1/SHA1_GUTS.asm"



CRYPTO_SHA1_INIT:

 .leaveCall:
    ret
