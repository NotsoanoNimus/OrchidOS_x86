; ARP.asm
; -- Address Resolution Protocol library for drivers to create ARP frames.

; Default ARP frame structure.
struc arp_link
    .htype: resw 1      ; Hardware type
    .ptype: resw 1      ; Protocol type
    .hlen: resb 1       ; Hardware address length (Ethernet = 6)
    .plen: resb 1       ; Protocol address length (IPv4 = 4)
    .opcode: resw 1     ; ARP Operation Code
    .srchw: resb .hlen  ; Source hardware address, hlen bytes in length
    .srcpr: resb .plen  ; Source protocol address, plen bytes in length
    .dsthw: resb .hlen  ; Destination hardware address
    .dstpr: resb .plen  ; Destination protocol address, IPv4 would be DWORD length
    .size:
endstruc

; Default ARP frame structure using MAC and IPv4.
arp_mac_ipv4:
    .htype: dw ARP_HTYPE_ETHERNET
    .ptype: dw ARP_PTYPE_IP
    .hlen: db 0x06          ; 6-byte MAC address
    .plen: db 0x04          ; 4-byte IP(v4) address
    .opcode: dw 0x0000      ; blank opcode
    .srchw: times 6 db 0x00 ; reserved source MAC space.
    .srcpr: times 4 db 0x00 ; reserved source IP space.
    .dsthw: times 6 db 0x00 ; reserved destination address. Could be FF:FF:FF:FF:FF:FF
    .dstpr: times 4 db 0x00 ; reserved destination IP space.
    .size:


; Hardware types
ARP_HTYPE_ETHERNET      equ 0x0001

; Protocol types
ARP_PTYPE_IP            equ 0x0800

; Opcodes
ARP_OPCODE_REQUEST      equ 0x0001
ARP_OPCODE_REPLY        equ 0x0002


; Frame Codes. These are not relevant to the ARP specification, but are instead used to identify internal ARP types in orchid.
ARP_MAC_IPV4_FRAME_CODE     equ 0x00000001

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; INPUTS:
;  ARG1 = Pointer to base of 6-byte MAC address
;  ARG2 = Pointer to base of device 4-byte IP address
;  ARG3 = Opcode
; OUTPUTS:
;  EAX = return code
;       0 = success, 1 = bad MAC address, 2 = bad IP address
; Based on inputs, creates an arp frame in the arp_mac_ipv4 structure
; -- That structure (arp_mac_ipv4) is used for operations after the call.
ARP_MAC_IPV4_CREATE_FRAME:
    push ebp
    mov ebp, esp

    ; clean out the old data.
    push ARP_MAC_IPV4_FRAME_CODE
    call ARP_INTERNAL_READY_FRAME_BUFFER
    add esp, 4

    mov edi, arp_mac_ipv4   ;point edi to the base of this specific ARP frame type.


 .leaveCall:
    pop ebp
    ret



; INPUTS:
;   ARG1 = Which one to reset.
; OUTPUTS: NONE
; Called to reset the designated ARP frame.
ARP_INTERNAL_READY_FRAME_BUFFER:
    push ebp
    mov ebp, esp
    push eax
    push ebx
    push ecx

    xor eax, eax
    xor ebx, ebx
    xor ecx, ecx
    mov ebx, dword [ebp+8]  ;arg1

    cmp ebx, ARP_MAC_IPV4_FRAME_CODE
    je .arp_mac_ipv4_clean

    jmp .leaveCall

 .arp_mac_ipv4_clean:
    mov edi, arp_mac_ipv4
    add edi, 6  ;the first 6 bytes is always the same for this type of frame.
    mov cl, 0x14    ; 20 iterations
    rep stosb   ; AL = 0 into EDI, EDI++
    jmp .leaveCall

 .leaveCall:
    pop ecx
    pop ebx
    pop eax
    pop ebp
    ret
