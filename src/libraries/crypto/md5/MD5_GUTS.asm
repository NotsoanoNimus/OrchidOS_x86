; MD5_GUTS.asm
; -- Interal computation functions for the MD5 hash algorithm.

; The first 16 bytes of the allocated buffer is the location of the result.
MD5_RESULT_OFFSET           equ 0
; ... and the 32 after that belong to the ASCII version of the output.
MD5_RESULT_STRING_OFFSET    equ 16
; ... then EVERYTHING after (until the max buffer length) belongs to the memcpy for padding/ops.
MD5_MEMCPY_ZONE_OFFSET      equ 48

ALIGN 4
MD5_RESULT_POINTER          dd 0x00000000   ; Set on MD5 init.
MD5_RESULT_ASCII_POINTER    dd 0x00000000   ; ^
MD5_MEMCPY_ZONE_POINTER     dd 0x00000000   ; ^

; Internal computation variables.
MD5_INTERNAL_AA dd 0x00000000
MD5_INTERNAL_BB dd 0x00000000
MD5_INTERNAL_CC dd 0x00000000
MD5_INTERNAL_DD dd 0x00000000

; rol table for the computation. Each group of 4 indices is used 4 times.
MD5_INTERNAL_ROL_TABLE:
    db 7, 12, 17, 22,  7, 12, 17, 22,  7, 12, 17, 22,  7, 12, 17, 22
    db 5,  9, 14, 20,  5,  9, 14, 20,  5,  9, 14, 20,  5,  9, 14, 20
    db 4, 11, 16, 23,  4, 11, 16, 23,  4, 11, 16, 23,  4, 11, 16, 23
    db 6, 10, 15, 21,  6, 10, 15, 21,  6, 10, 15, 21,  6, 10, 15, 21


; Define the 64-element table, where for each index i, do MD5_T[i] = HEX(4294967296 * abs(sin_rad(i))).
MD5_INTERNAL_STATIC_TABLE:
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



; Clean the internal variables up that are used in computation.
MD5_INTERNAL_CLEAN_VARIABLES:
    MultiPush eax,ecx,edi
    ZERO eax,ecx

    mov dword [MD5_INTERNAL_AA], eax
    mov dword [MD5_INTERNAL_BB], eax
    mov dword [MD5_INTERNAL_CC], eax
    mov dword [MD5_INTERNAL_DD], eax

    mov byte [MD5_INTERNAL_PASS_COUNTER], 0x00
    mov byte [MD5_INTERNAL_G_VAR], 0x00
    mov dword [MD5_INTERNAL_F_VAR], eax

    ; do not wipe the result. :thinking_emoji:
    ;mov cl, 4
    ;mov edi, dword [MD5_RESULT_POINTER]
    ;rep stosd

    ; !!!!!!!!!!!!!!!!!!!!!!!
    ; !!!!!! IMPORTANT !!!!!!
    ; !!!!!!!!!!!!!!!!!!!!!!!
    ; Uncomment on deployment to clean up the memcpy zone.
    ;mov ecx, CRYPTO_MD5_BUFFER_MEMCPY_ZONE_SIZE
    ;mov edi, dword [MD5_MEMCPY_ZONE_POINTER]
    ;shr ecx, 2  ; divide by 4
    ;rep stosd

 .leaveCall:
    MultiPop edi,ecx,eax
    ret



; INPUTS:
;   ECX = Length of input buffer.
; OUTPUTS:
;   EAX = # of passes required for hash computation.
; Get the amount of passes required for the hashing algorithm.
; -- Called only from the COMPUTE_HASH function.
MD5_INTERNAL_GET_PASS_COUNT:
    MultiPush ebx,edx
    ZERO eax,ebx
    mov bl, 64      ; Each pass covers 512-bit blocks (64 bytes since ECX is in byte units).
    mov eax, ecx    ; EAX = Input buffer length to divide.
    div bl          ; AX div BL ---> AH = Remainder (mod - important), AL = Quotient.

    inc al          ; Pass count is always at least 1.

 .leaveCall:
    MultiPop edx,ebx
    ret



; INPUTS:
;   ARG1 = Length of input buffer in bytes (for quick movement to end-of-buffer).
;   AL = # of passes, AH = leftovers.
; Pad the input buffer to the required 512-bit boundary.
; -- Each MD5 'block' of data must be 512 bits in length. The last block should be < or = 447 bits,
; ---- (55 bytes due to granularity of the Orchid MD5 library)
; ---- because the algorithm pads data with a starting 1 bit (and subsequent 0s) at the end of the
; ---- input buffer and terminates with 64 bits detailing the length of the input buffer itself (in bits).
; -- Ex: [440-bit(55-byte) input] + 0x80 + QWORD(inputBuffer.length)
; -- Ex2: [1264-byte(158-byte) input] mod 64 = 30 bytes to be padded to 56 bytes, followed by the 64-bit bit-length marker.
; ---- [158-byte input] + 0x80 (byte 31) + 0x00 (bytes 32-56) + 0x000004F0 (bytes 57-64 = QWORD(inputBuffer.length * 8))
MD5_INTERNAL_PAD_DATA:
    FunctionSetup
    MultiPush edi,ecx,ebx
    ZERO ebx,ecx

    ; Place the terminating 0x80 byte immediately with no calculations.
    mov edi, dword [MD5_MEMCPY_ZONE_POINTER]    ; EDI = base of memcpy'd string
    mov ecx, ARG1   ; ECX = Length of the string.
    add edi, ecx    ; EDI += strlen (goto buffer end)
    mov strict byte [edi], 0x80 ; add the trailing 1-bit, with 0s after. Takes up 1 byte.
    inc ah  ; increment the mod value to account for the added 0x80.

    ; Multiply the length by 8 to get its equivalent in bits. This will be stored later.
    shl ecx, 3
    push ecx    ;save it
    mov ecx, 0x00000040 ; ECX = 64

    ; Check the mod operation. If it is > 56 bytes leftover, add another pass.
    ; -- We'll do more with the mod in the padding function.
    ;if(AH > 56) { AL++; }
    cmp ah, 56  ; 58 => 122
    jbe .noExtra

    inc al  ; inc passes count
    mov ecx, 56 ; start at 56
    ; have to find a way to dynamically go to the end of the boundary (448 mod 512), with space for the QWORD.
    not ah  ; negate the AH register,
    and ah, 00111111b   ; constrain it to a 63-byte boundary,
    inc ah  ; and increment to get an accurate subtraction value.
    add cl, ah  ; 56 + ~AH
    jmp .endIf1
 .noExtra:
    sub cl, ah  ; 64 - bytes in last block
    sub cl, 8   ; minus 8 for ending QWORD
 .endIf1:

    ; Set EDI to the beginning of the padding area.
    inc edi
    ; At this point, CL = the amount of padding bytes to add... Save eax and get a transfer going.
    push eax
    ZERO eax
    rep stosb
    pop eax

    ; Place QWORD data length in bits as trailing signature.
    pop ecx     ;restore
    mov dword [edi+4], 0x00000000
    mov dword [edi+0], ecx


 .leaveCall:
    MultiPop ebx,ecx,edi
    FunctionLeave



; Given that X is an array consisting of a 16-byte segment of a block,
;  T is the internal constant table array,
;  a = EAX, b = EBX, c = ECX, d = EDX,
;  and r is the given function of the round number, 1=F,  2=G, 3=H, 4=I,
;  then the following equations are true and computable:
;   [abcd k s i] ====>  a = b + ((a + r(b,c,d) + X[k] + T[i]) <<< s)
;   [dabc k s i] ====>  d = a + ((d + r(a,b,c) + X[k] + T[i]) <<< s)
;   [cdab k s i] ====>  c = d + ((c + r(d,a,b) + X[k] + T[i]) <<< s)
;   [bcda k s i] ====>  b = c + ((b + r(c,d,a) + X[k] + T[i]) <<< s)
; Defs/Macros for the internal pass function for ease of programmer comprehension, and simplicity.
%macro MD5_COMPS 16
    MD5_COMPUTATION_ABCD %1,%2,%3,%4
    MD5_COMPUTATION_DABC %5,%6,%7,%8
    MD5_COMPUTATION_CDAB %9,%10,%11,%12
    MD5_COMPUTATION_BCDA %13,%14,%15,%16
%endmacro
; EAX = EBX + ((EAX + round#(EBX,ECX,EDX) + [ESI+k] + [MD5_INTERNAL_STATIC_TABLE.i]) rol s)
; Goal is to only change EAX from this...
%macro MD5_COMPUTATION_ABCD 4
    push ebx    ; save state for end pop
    push ebx    ; save EBX value
    mov ebx, eax    ; EBX = EAX
    func(MD5_INTERNAL_%4,ebx,ecx,edx)   ; EAX = round#(b,c,d)
    add ebx, eax
    mov eax, ebx    ; EAX = EAX_start + round#(b,c,d)
    mov ebx, dword [esi+(%1*4)] ; EBX = DWORD from the input buffer at position (k)
    add eax, ebx
    add eax, dword [MD5_INTERNAL_STATIC_TABLE.%3]   ; add value from the table at index (i)
    rol eax, %2     ; Rotate EAX left by the value (s)
    pop ebx     ; get EBX value from earlier
    add ebx, eax    ; EBX += (... rol s)
    mov eax, ebx    ; EAX = result!
    pop ebx     ; restore the b value
%endmacro
; EDX = EAX + ((EDX + round#(EAX,EBX,ECX) + [ESI+k] + [MD5_INTERNAL_STATIC_TABLE.i]) rol s)
%macro MD5_COMPUTATION_DABC 4
    ;push eax    ; save orig EAX
    push eax    ; save EAX_start
    func(MD5_INTERNAL_%4,eax,ebx,ecx)   ; EAX = round#(a,b,c)
    add edx, eax    ; EDX += result
    mov eax, dword [esi+(%1*4)]
    add edx, eax    ; ... += [ESI+k]
    add edx, dword [MD5_INTERNAL_STATIC_TABLE.%3]
    rol edx, %2
    pop eax     ; get EAX_start
    add edx, eax    ; EDX = (... rol s) + EAX
    ;pop eax ; restore orig EAX
%endmacro
; ECX = EDX + ((ECX + round#(EDX,EAX,EBX) + [ESI+k] + [MD5_INTERNAL_STATIC_TABLE.i]) rol s)
%macro MD5_COMPUTATION_CDAB 4
    ;push edx    ; save orig edx
    push eax    ; save orig eax
    func(MD5_INTERNAL_%4,edx,eax,ebx)   ; EAX = round#(d,a,b)
    add ecx, eax    ; ECX += result
    mov eax, dword [esi+(%1*4)]
    add ecx, eax    ; ... += [ESI+k]
    add ecx, dword [MD5_INTERNAL_STATIC_TABLE.%3]
    rol ecx, %2
    pop eax ; restore eax
    add ecx, edx    ; ECX = (... rol s) + EDX
    ;pop edx
%endmacro
; EBX = ECX + ((EBX + round#(ECX,EDX,EAX) + [ESI+k] + [MD5_INTERNAL_STATIC_TABLE.i]) rol s)
%macro MD5_COMPUTATION_BCDA 4
    push eax    ; save orig eax
    func(MD5_INTERNAL_%4,ecx,edx,eax)   ; EAX = round#(c,d,a)
    add ebx, eax    ; EBX += result
    mov eax, dword [esi+(%1*4)]
    add ebx, eax    ; ... += [ESI+k]
    add ebx, dword [MD5_INTERNAL_STATIC_TABLE.%3]
    rol ebx, %2
    pop eax ; restore eax
    add ebx, ecx    ; EBX = (... rol s) + ECX
%endmacro
; Begin Internal Per-Pass function that operates on a 16-byte segment of a block of data.
MD5_INTERNAL_PASS_COUNTER db 0x00   ; var int i = 0
MD5_INTERNAL_G_VAR db 0x00          ; var int g = 0
MD5_INTERNAL_F_VAR dd 0x00000000    ; var int F = 0
MD5_INTERNAL_PASS:
    ; AA = A, BB = B, CC = C, DD = D
    mov dword [MD5_INTERNAL_AA], eax
    mov dword [MD5_INTERNAL_BB], ebx
    mov dword [MD5_INTERNAL_CC], ecx
    mov dword [MD5_INTERNAL_DD], edx
    mov byte [MD5_INTERNAL_PASS_COUNTER], 0x00

 .mainLoop:
    cmp byte [MD5_INTERNAL_PASS_COUNTER], 15
    jle .round1 ; if i<=15
    cmp byte [MD5_INTERNAL_PASS_COUNTER], 31
    jle .round2 ; elseif i<=31 && i>=16
    cmp byte [MD5_INTERNAL_PASS_COUNTER], 47
    jle .round3 ; elseif i<=47 && i>=32
    jmp .round4 ; else

 .round1: ;range i = 0 to 15
    ; F = MD5_INTERNAL_F(EBX,ECX,EDX)
    ; g = i
    push eax
    func(MD5_INTERNAL_F,ebx,ecx,edx)
    mov dword [MD5_INTERNAL_F_VAR], eax
    ZERO eax
    mov al, byte [MD5_INTERNAL_PASS_COUNTER]
    mov strict byte [MD5_INTERNAL_G_VAR], al
    pop eax
    jmp .rotate

 .round2: ;range i = 16 to 31
    ; F = MD5_INTERNAL_G(EBX,ECX,EDX)
    ; g = (5*i + 1) mod 16
    MultiPush eax,ebx
    func(MD5_INTERNAL_G,ebx,ecx,edx)
    mov dword [MD5_INTERNAL_F_VAR], eax
    ZERO eax,ebx
    mov al, byte [MD5_INTERNAL_PASS_COUNTER]
    mov bl, 5
    mul bl  ; AX = 5*i
    inc ax  ; AX++
    mov bl, 16
    div bl  ; AH = modulus/rem (important part)
    mov strict byte [MD5_INTERNAL_G_VAR], ah
    MultiPop ebx,eax
    jmp .rotate

 .round3: ;range i = 32 to 47
    ; F = MD5_INTERNAL_H(EBX,ECX,EDX)
    ; g = (3*i + 5) mod 16
    MultiPush eax,ebx
    func(MD5_INTERNAL_H,ebx,ecx,edx)
    mov dword [MD5_INTERNAL_F_VAR], eax
    ZERO eax,ebx
    mov al, byte [MD5_INTERNAL_PASS_COUNTER]
    mov bl, 3
    mul bl  ; AX = 3*i
    add ax, 5 ; += 5
    mov bl, 16
    div bl  ; AH = modulus/rem
    mov strict byte [MD5_INTERNAL_G_VAR], ah
    MultiPop ebx,eax
    jmp .rotate

 .round4: ;range i = 48 to 63
    ; F = MD5_INTERNAL_I(EBX,ECX,EDX)
    ; g = (7*i) mod 16
    MultiPush eax,ebx
    func(MD5_INTERNAL_I,ebx,ecx,edx)
    mov dword [MD5_INTERNAL_F_VAR], eax
    ZERO eax,ebx
    mov al, byte [MD5_INTERNAL_PASS_COUNTER]
    mov bl, 7
    mul bl  ; AX = 7*i
    mov bl, 16
    div bl  ; AH = modulus/rem
    mov strict byte [MD5_INTERNAL_G_VAR], ah
    MultiPop ebx,eax
    jmp .rotate

 .rotate:
    ; F = F + A + K[i] + M[g]
    ; `--> F_VAR + EAX + MD5_INTERNAL_STATIC_TABLE.(i) + inputBuffer[G_VAR * 4]
    MultiPush eax,ebx,edi,ecx,esi
    movzx ebx, byte [MD5_INTERNAL_F_VAR]
    add eax, ebx    ; EAX += F_VAR

    ; get K[i]
    mov edi, dword MD5_INTERNAL_STATIC_TABLE
    movzx ecx, strict byte [MD5_INTERNAL_PASS_COUNTER]
    shl ecx, 2  ; i * 4
    add edi, ecx    ; EDI (base) += (i*4)
    mov ebx, dword [edi]    ; extract from the static table
    add eax, ebx    ; EAX += static[i]

    ; get M[g] -- DWORD of Message/Input @ index g*4
    movzx ebx, strict byte [MD5_INTERNAL_G_VAR]
    shl ebx, 2  ; EBX = g*4
    add esi, ebx    ; ESI += (g*4)
    mov ebx, dword [esi]
    add eax, ebx    ; EAX += DWORD(inputBuffer[g*4])

    mov dword [MD5_INTERNAL_F_VAR], eax ; store back into F
    MultiPop esi,ecx,edi,ebx,eax

    ; ----------------------
    ; A = D, D = C, C = B, B = B + leftRotate(F,internalRotate[i])
    push edi
    push edx    ; d_start
    push ecx    ; c_start
    push ebx    ; b_start

    ; B = B + rol(F,s[i]), where s = internalRotate table
    mov eax, dword [MD5_INTERNAL_F_VAR]
    movzx ecx, strict byte [MD5_INTERNAL_PASS_COUNTER]
    mov edi, MD5_INTERNAL_ROL_TABLE
    add edi, ecx    ; go to byte at index
    movzx ecx, strict byte [edi] ; get byte at internalRotate[i]
    rol eax, cl ; rotate by the value,
    add ebx, eax; and add it into EBX

    pop ecx     ; C = b_start
    pop edx     ; D = c_start
    pop eax     ; A = d_start
    pop edi

    cmp byte [MD5_INTERNAL_PASS_COUNTER], 63
    jge .leaveLoop ; i >= 63, exit
    inc byte [MD5_INTERNAL_PASS_COUNTER] ; else, inc counter
    jmp .mainLoop ; and go again

 .leaveLoop:

    ; Round 1
    ;MD5_COMPS 0,7,1,F,1,12,2,F,2,17,3,F,3,22,4,F
    ;MD5_COMPS 4,7,5,F,5,12,6,F,6,17,7,F,7,22,8,F
    ;MD5_COMPS 8,7,9,F,9,12,10,F,10,17,11,F,11,22,12,F
    ;MD5_COMPS 12,7,13,F,13,12,14,F,14,17,15,F,15,22,16,F

    ; Round 2
    ;MD5_COMPS 1,5,17,G,6,9,18,G,11,14,19,G,0,20,20,G
    ;MD5_COMPS 5,5,21,G,10,9,22,G,15,14,23,G,4,20,24,G
    ;MD5_COMPS 9,5,25,G,14,9,26,G,3,14,27,G,8,20,28,G
    ;MD5_COMPS 13,5,29,G,2,9,30,G,7,14,31,G,12,20,32,G

    ; Round 3
    ;MD5_COMPS 5,4,33,H,8,11,34,H,11,16,35,H,14,23,36,H
    ;MD5_COMPS 1,4,37,H,4,11,38,H,7,16,39,H,10,23,40,H
    ;MD5_COMPS 13,4,41,H,0,11,42,H,3,16,43,H,6,23,44,H
    ;MD5_COMPS 9,4,45,H,12,11,46,H,15,16,47,H,2,23,48,H

    ; Round 4
    ;MD5_COMPS 0,6,49,I,7,10,50,I,14,15,51,I,5,21,52,I
    ;MD5_COMPS 12,6,53,I,3,10,54,I,10,15,55,I,1,21,56,I
    ;MD5_COMPS 8,6,57,I,15,10,58,I,6,15,59,I,13,21,60,I
    ;MD5_COMPS 4,6,61,I,11,10,62,I,2,15,63,I,9,21,64,I

    ; A = A + AA
    push ebx
    mov ebx, dword [MD5_INTERNAL_AA]
    add eax, ebx
    pop ebx
    ; B = B + BB
    push eax
    mov eax, dword [MD5_INTERNAL_BB]
    add ebx, eax
    pop eax
    ; C = C + CC
    push eax
    mov eax, dword [MD5_INTERNAL_CC]
    add ecx, eax
    pop eax
    ; D = D + DD
    push eax
    mov eax, dword [MD5_INTERNAL_DD]
    add edx, eax
    pop eax
 .leaveCall:
    ; On return, the 4 abcd regs have their values ready to store into the MD5_RESULT_POINTER.
    ret



; F(X,Y,Z) = (X & Y) | (~X & Z)
; Return register: EAX
MD5_INTERNAL_F:
	FunctionSetup
    MultiPush ebx,ecx,edx
    ZERO eax,ebx,ecx,edx

    mov ebx, dword [ebp+8]  ; EBX = X
    mov ecx, dword [ebp+12] ; ECX = Y
    mov edx, dword [ebp+16] ; EDX = Z

    and ecx, ebx    ; Y = (X & Y) <-- Using Y because it's not used in the other half of the equation
    not ebx ; X = ~X
    and edx, ebx    ; Z = (~X & Z)

    or ecx, edx ; Y = (X & Y) | (~X & Z)
    mov eax, ecx    ; Set return value.

 .leaveCall:
    MultiPop edx,ecx,ebx
 	FunctionLeave



; G(X,Y,Z) = (X & Z) | (Y & ~Z)
; Return register: EAX
MD5_INTERNAL_G:
    FunctionSetup
    MultiPush ebx,ecx,edx
    ZERO eax,ebx,ecx,edx

    mov ebx, dword [ebp+8]  ; EBX = X
    mov ecx, dword [ebp+12] ; ECX = Y
    mov edx, dword [ebp+16] ; EDX = Z

    and ebx, edx    ; X = (X & Z)
    not edx ; Z = ~Z
    and ecx, edx    ; Y = (Y & ~Z)

    or ebx, ecx     ; X = (X & Y) | (Y & ~Z)
    mov eax, ebx    ; Set return value.

 .leaveCall:
    MultiPop edx,ecx,ebx
    FunctionLeave



; H(X,Y,Z) = X xor Y xor Z
; Return register: EAX
MD5_INTERNAL_H:
    FunctionSetup
    MultiPush ebx,ecx,edx
    ZERO eax,ebx,ecx,edx

    mov ebx, dword [ebp+8]  ; EBX = X
    mov ecx, dword [ebp+12] ; ECX = Y
    mov edx, dword [ebp+16] ; EDX = Z

    ; (X^Y)^Z === Z^(Y^Z), so order doesn't matter.
    xor ebx, ecx    ; X = X xor Y
    xor ebx, edx    ; X = (X xor Y) xor Z

    mov eax, ebx    ; Set return value.

 .leaveCall:
    MultiPop edx,ecx,ebx
    FunctionLeave



; I(X,Y,Z) = Y xor (X | ~Z)
; Return register: EAX
MD5_INTERNAL_I:
    FunctionSetup
    MultiPush ebx,ecx,edx
    ZERO eax,ebx,ecx,edx

    mov ebx, dword [ebp+8]  ; EBX = X
    mov ecx, dword [ebp+12] ; ECX = Y
    mov edx, dword [ebp+16] ; EDX = Z

    not edx     ; Z = ~Z
    or ebx, edx     ; X = (X | ~Z)
    xor ecx, ebx    ; Y = Y xor (X | ~Z)

    mov eax, ecx    ; Set return value.

 .leaveCall:
    MultiPop edx,ecx,ebx
    FunctionLeave
